//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Manages `Query` fetching/caching and `Mutation` execution (port of `queryManager.ts`).
@available(iOS 17.0, macOS 14.0, *)
@MainActor
final class QueryManager {
    /// An evaluated `Query(...)` declaration.
    struct QueryNode: Sendable, Equatable {
        var statementId: String
        var toolName: String
        var args: OpenUIValue?
        var defaults: OpenUIValue?
        /// Evaluated `$variable` dependencies — part of the cache key, so changes re-fetch.
        var deps: OpenUIValue?
        /// Auto-refresh interval in seconds.
        var refreshInterval: Double?
        var complete: Bool

        init(statementId: String, toolName: String, args: OpenUIValue? = nil, defaults: OpenUIValue? = nil, deps: OpenUIValue? = nil, refreshInterval: Double? = nil, complete: Bool = true) {
            self.statementId = statementId
            self.toolName = toolName
            self.args = args
            self.defaults = defaults
            self.deps = deps
            self.refreshInterval = refreshInterval
            self.complete = complete
        }
    }

    /// An evaluated `Mutation(...)` declaration.
    struct MutationNode: Sendable, Equatable {
        var statementId: String
        var toolName: String

        init(statementId: String, toolName: String) {
            self.statementId = statementId
            self.toolName = toolName
        }
    }

    /// Observable snapshot of query data, loading state and errors.
    struct Snapshot: Sendable, Equatable {
        /// Statement ID → current data (settled, previous while refetching, or defaults) / mutation result.
        var values = OpenUIObject()
        var loading: [String] = []
        var refetching: [String] = []
        var errors: [OpenUIError] = []
    }

    private final class QueryEntry {
        var toolName: String
        var args: OpenUIValue?
        var defaults: OpenUIValue?
        var cacheKey: String
        var previousCacheKey: String?
        var loading = false
        var everFetched = false
        var refreshInterval: Double = 0
        var timer: Task<Void, Never>?
        var pendingFetch: Task<Void, Never>?
        var needsRefetch = false
        var error: OpenUIError?

        init(toolName: String, args: OpenUIValue?, defaults: OpenUIValue?, cacheKey: String) {
            self.toolName = toolName
            self.args = args
            self.defaults = defaults
            self.cacheKey = cacheKey
        }
    }

    private final class MutationEntry {
        var toolName: String
        var result: OpenUIValue
        var error: OpenUIError?

        init(toolName: String, result: OpenUIValue) {
            self.toolName = toolName
            self.result = result
        }
    }

    private final class CacheEntry {
        /// `nil` = no data yet (distinct from a `null` result).
        var data: OpenUIValue?
        var inFlight: Bool

        init(data: OpenUIValue?, inFlight: Bool) {
            self.data = data
            self.inFlight = inFlight
        }
    }

    let toolProvider: (any OpenUIToolProvider)?

    private var queryOrder: [String] = []
    private var queries: [String: QueryEntry] = [:]
    private var mutationOrder: [String] = []
    private var mutations: [String: MutationEntry] = [:]
    private var cache: [String: CacheEntry] = [:]
    private var disposed = false
    private var refreshesPaused = false
    private var generation = 0

    private(set) var snapshot = Snapshot()

    /// Called when the snapshot changes.
    var onChange: (() -> Void)?

    /// How long a query waits after its arguments change before it fetches, so a query bound to
    /// a field the person types in fetches once they pause, not on every keystroke.
    var argumentDebounce: TimeInterval = 0.3

    init(toolProvider: (any OpenUIToolProvider)?) {
        self.toolProvider = toolProvider
    }

    // MARK: - Snapshot

    @discardableResult
    private func rebuildSnapshot() -> Bool {
        var next = Snapshot()
        for statementId in queryOrder {
            guard let query = queries[statementId] else { continue }
            if let data = cache[query.cacheKey]?.data {
                next.values[statementId] = data
            } else if let previousKey = query.previousCacheKey, let data = cache[previousKey]?.data {
                next.values[statementId] = data
            } else {
                next.values[statementId] = query.defaults ?? .null
            }
            if query.loading {
                next.loading.append(statementId)
                if query.everFetched { next.refetching.append(statementId) }
            }
            if let error = query.error { next.errors.append(error) }
        }
        for statementId in mutationOrder {
            guard let mutation = mutations[statementId] else { continue }
            next.values[statementId] = mutation.result
            if let error = mutation.error { next.errors.append(error) }
        }
        guard next != snapshot else { return false }
        snapshot = next
        return true
    }

    private func notify() {
        onChange?()
    }

    // MARK: - Fetching

    /// Marks the fetch as in flight synchronously, then performs it asynchronously.
    private func startFetch(cacheKey: String, statementId: String) {
        guard let toolProvider, let query = queries[statementId] else { return }
        let toolName = query.toolName
        let arguments = query.args?.objectValue ?? [:]

        let entry: CacheEntry
        if let existing = cache[cacheKey] {
            entry = existing
            entry.inFlight = true
        } else {
            entry = CacheEntry(data: nil, inFlight: true)
            cache[cacheKey] = entry
        }
        query.loading = true
        rebuildSnapshot()
        notify()

        Task { [weak self] in
            let outcome: Result<OpenUIValue, any Error>
            do {
                outcome = .success(try await toolProvider.callTool(toolName, arguments: arguments, userInitiated: false))
            } catch {
                outcome = .failure(error)
            }
            self?.finishFetch(outcome, entry: entry, cacheKey: cacheKey, statementId: statementId, toolName: toolName)
        }
    }

    private func finishFetch(_ outcome: Result<OpenUIValue, any Error>, entry: CacheEntry, cacheKey: String, statementId: String, toolName: String) {
        switch outcome {
        case .success(let data):
            if !disposed {
                if let current = queries[statementId], current.cacheKey == cacheKey {
                    entry.data = data
                    current.everFetched = true
                    current.error = nil
                    if let previousKey = current.previousCacheKey, previousKey != cacheKey {
                        current.previousCacheKey = nil
                        cleanupCacheEntry(previousKey)
                    }
                } else {
                    // The query was removed or moved to another cache key while in flight.
                    entry.inFlight = false
                    cleanupCacheEntry(cacheKey)
                }
            }
        case .failure(let error):
            if let current = queries[statementId], current.cacheKey == cacheKey {
                current.error = Self.queryError(error, source: .query, statementId: statementId, toolName: toolName)
            }
        }

        entry.inFlight = false
        if let current = queries[statementId], current.cacheKey == cacheKey {
            current.loading = false
            if rebuildSnapshot() { notify() }
            if current.needsRefetch {
                current.needsRefetch = false
                startFetch(cacheKey: current.cacheKey, statementId: statementId)
            }
        } else if rebuildSnapshot() {
            notify()
        }
    }

    private static func errorMessage(_ error: any Error) -> String {
        if let localized = error as? LocalizedError, let description = localized.errorDescription {
            return description
        }
        return String(describing: error)
    }

    private static func queryError(_ error: any Error, source: OpenUIError.Source, statementId: String, toolName: String) -> OpenUIError {
        let kind = source == .query ? "Query" : "Mutation"
        if let notFound = error as? ToolNotFoundError {
            return OpenUIError(
                source: source,
                code: "tool-not-found",
                message: "\(kind) tool \"\(toolName)\" not found",
                statementId: statementId,
                component: kind,
                toolName: toolName,
                hint: notFound.availableTools.isEmpty ? nil : "Available tools: " + notFound.availableTools.joined(separator: ", ")
            )
        }
        if let mcp = error as? MCPToolError {
            return OpenUIError(
                source: source,
                code: "mcp-error",
                message: "\(kind) \"\(toolName)\" returned an error: \(mcp.toolErrorText)",
                statementId: statementId,
                component: kind,
                toolName: toolName
            )
        }
        return OpenUIError(
            source: source,
            code: "tool-error",
            message: "\(kind) \"\(toolName)\" failed: \(errorMessage(error))",
            statementId: statementId,
            component: kind,
            toolName: toolName
        )
    }

    /// Removes a cache entry no query references anymore.
    private func cleanupCacheEntry(_ cacheKey: String) {
        for query in queries.values where query.cacheKey == cacheKey || query.previousCacheKey == cacheKey {
            return
        }
        cache.removeValue(forKey: cacheKey)
    }

    /// Stable JSON (sorted keys at every level) used for cache keys.
    static func stableStringify(_ value: OpenUIValue?) -> String {
        guard let value else { return "\"__undefined__\"" }
        switch value {
        case .number(let number) where number.isNaN:
            return "\"__NaN__\""
        case .number(let number) where number.isInfinite:
            return number > 0 ? "\"__Inf__\"" : "\"__-Inf__\""
        case .array(let items):
            return "[" + items.map { stableStringify($0) }.joined(separator: ",") + "]"
        case .object(let object):
            let parts = object.keys.sorted().map { key -> String in
                var quoted = ""
                JS.writeJSONString(key, into: &quoted)
                return quoted + ":" + stableStringify(object[key])
            }
            return "{" + parts.joined(separator: ",") + "}"
        case .element, .expression:
            return stableStringify(value.plainJSON)
        case .null, .bool, .number, .string:
            return JS.jsonStringify(value) ?? "null"
        }
    }

    static func cacheKey(toolName: String, args: OpenUIValue?, deps: OpenUIValue?) -> String {
        let depsKey = JS.isNullish(deps) ? "" : "::" + stableStringify(deps)
        return toolName + "::" + stableStringify(args) + depsKey
    }

    // MARK: - Queries

    /// Reconciles the active queries: removes stale ones, fetches new/changed ones, and configures refresh timers.
    func evaluateQueries(_ nodes: [QueryNode]) {
        guard !disposed else { return }
        let activeIds = Set(nodes.map(\.statementId))

        for statementId in queryOrder where !activeIds.contains(statementId) {
            guard let query = queries.removeValue(forKey: statementId) else { continue }
            query.timer?.cancel()
            query.pendingFetch?.cancel()
            cleanupCacheEntry(query.cacheKey)
            if let previousKey = query.previousCacheKey { cleanupCacheEntry(previousKey) }
        }
        queryOrder.removeAll { queries[$0] == nil }

        for node in nodes where node.complete {
            let cacheKey = Self.cacheKey(toolName: node.toolName, args: node.args, deps: node.deps)
            let query: QueryEntry
            var argumentsChanged = false
            if let existing = queries[node.statementId] {
                if existing.cacheKey != cacheKey {
                    existing.previousCacheKey = existing.cacheKey
                    argumentsChanged = true
                }
                existing.toolName = node.toolName
                existing.args = node.args
                existing.defaults = node.defaults
                existing.cacheKey = cacheKey
                query = existing
            } else {
                query = QueryEntry(toolName: node.toolName, args: node.args, defaults: node.defaults, cacheKey: cacheKey)
                queries[node.statementId] = query
                queryOrder.append(node.statementId)
            }

            let entry = cache[cacheKey]
            let hasSettledData = entry?.data != nil && entry?.inFlight == false
            if hasSettledData {
                query.pendingFetch?.cancel()
                query.pendingFetch = nil
            }
            if toolProvider != nil, !hasSettledData, entry?.inFlight != true {
                if argumentsChanged {
                    scheduleFetch(query: query, cacheKey: cacheKey, statementId: node.statementId)
                } else if query.pendingFetch == nil {
                    startFetch(cacheKey: cacheKey, statementId: node.statementId)
                }
            } else if hasSettledData, query.loading {
                // Back on args whose data is cached while another fetch was in flight: that fetch
                // no longer concerns this query, so it must not keep it loading.
                query.loading = false
                if let previousKey = query.previousCacheKey, previousKey != cacheKey {
                    query.previousCacheKey = nil
                    cleanupCacheEntry(previousKey)
                }
            }

            let interval = node.refreshInterval ?? 0
            if interval != query.refreshInterval {
                query.timer?.cancel()
                query.timer = nil
                if interval > 0 && !refreshesPaused {
                    query.timer = makeRefreshTimer(query: query, statementId: node.statementId, interval: interval)
                }
                query.refreshInterval = interval
            }
        }

        if rebuildSnapshot() { notify() }
    }

    // Fetches once the arguments have stayed the same for `argumentDebounce`, as a query whose
    // arguments are bound to a field changes with every keystroke.
    private func scheduleFetch(query: QueryEntry, cacheKey: String, statementId: String) {
        query.pendingFetch?.cancel()
        query.pendingFetch = nil
        guard argumentDebounce > 0 else {
            startFetch(cacheKey: cacheKey, statementId: statementId)
            return
        }
        // It shows as refetching while it waits, with the data it had.
        query.loading = true
        let nanoseconds = UInt64(argumentDebounce * 1_000_000_000)
        query.pendingFetch = Task { [weak self, weak query] in
            try? await Task.sleep(nanoseconds: nanoseconds)
            guard !Task.isCancelled, let self, let query, !self.disposed, self.queries[statementId] === query else { return }
            query.pendingFetch = nil
            let entry = self.cache[cacheKey]
            let hasSettledData = entry?.data != nil && entry?.inFlight == false
            guard query.cacheKey == cacheKey, !hasSettledData, entry?.inFlight != true else {
                query.loading = entry?.inFlight == true
                if self.rebuildSnapshot() { self.notify() }
                return
            }
            self.startFetch(cacheKey: cacheKey, statementId: statementId)
        }
    }

    private func makeRefreshTimer(query: QueryEntry, statementId: String, interval: Double) -> Task<Void, Never> {
        let nanoseconds = Self.refreshNanoseconds(interval, minimum: toolProvider?.minimumRefreshInterval ?? 5)
        return Task { [weak self, weak query] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: nanoseconds)
                guard !Task.isCancelled, let self, let query else { return }
                guard !self.disposed, self.toolProvider != nil else { continue }
                if self.cache[query.cacheKey]?.inFlight != true {
                    self.startFetch(cacheKey: query.cacheKey, statementId: statementId)
                }
            }
        }
    }

    // The model writes the interval, so it can be any number: it waits at least the tool
    // provider's minimum, and like a browser's `setInterval`, at least a millisecond and at most
    // about 24.8 days (2^31 - 1 ms).
    static func refreshNanoseconds(_ interval: Double, minimum: TimeInterval) -> UInt64 {
        let shortest = minimum.isNaN ? 0.001 : min(max(minimum, 0.001), 2_147_483.647)
        let seconds = interval.isNaN ? shortest : min(max(interval, shortest), 2_147_483.647)
        return UInt64(seconds * 1_000_000_000)
    }

    /// Current data for a query: settled data, the previous result while refetching, or the defaults.
    func result(for statementId: String) -> OpenUIValue? {
        guard let query = queries[statementId] else { return .null }
        if let data = cache[query.cacheKey]?.data { return data }
        if let previousKey = query.previousCacheKey, let data = cache[previousKey]?.data { return data }
        return query.defaults
    }

    func isLoading(_ statementId: String) -> Bool {
        queries[statementId]?.loading ?? false
    }

    var isAnyLoading: Bool {
        queries.values.contains { $0.loading }
    }

    /// Re-fetches the given queries (all when `nil`/empty). In-flight queries re-fetch when they settle.
    func invalidate(_ statementIds: [String]? = nil) {
        guard !disposed, toolProvider != nil else { return }
        let targets: [String]
        if let statementIds, !statementIds.isEmpty {
            targets = statementIds.filter { queries[$0] != nil }
        } else {
            targets = queryOrder
        }
        for statementId in targets {
            guard let query = queries[statementId] else { continue }
            if cache[query.cacheKey]?.inFlight == true {
                query.needsRefetch = true
            } else {
                startFetch(cacheKey: query.cacheKey, statementId: statementId)
            }
        }
    }

    // MARK: - Mutations

    func registerMutations(_ nodes: [MutationNode]) {
        let activeIds = Set(nodes.map(\.statementId))
        for statementId in mutationOrder where !activeIds.contains(statementId) {
            mutations.removeValue(forKey: statementId)
        }
        mutationOrder.removeAll { mutations[$0] == nil }

        for node in nodes {
            if let existing = mutations[node.statementId] {
                if existing.toolName != node.toolName {
                    existing.toolName = node.toolName
                    existing.result = ["status": "idle", "data": .null, "error": .null]
                    existing.error = nil
                }
            } else {
                mutations[node.statementId] = MutationEntry(toolName: node.toolName, result: ["status": "idle", "data": .null, "error": .null])
                mutationOrder.append(node.statementId)
            }
        }
        if rebuildSnapshot() { notify() }
    }

    /// Runs a mutation. Returns `false` on failure (or if it is already running).
    func fireMutation(_ statementId: String, arguments: OpenUIObject, refreshQueryIds: [String]? = nil) async -> Bool {
        guard !disposed, let toolProvider, let mutation = mutations[statementId] else { return false }
        // Reject concurrent calls on the same mutation — prevents double submits.
        if mutation.result["status"] == "loading" { return false }

        let startGeneration = generation
        mutation.result = ["status": "loading"]
        rebuildSnapshot()
        notify()

        var success = false
        do {
            let data = try await toolProvider.callTool(mutation.toolName, arguments: arguments, userInitiated: true)
            if disposed || startGeneration != generation { return false }
            mutation.result = ["status": "success", "data": data]
            mutation.error = nil
            success = true
        } catch {
            if disposed || startGeneration != generation { return false }
            mutation.result = ["status": "error", "error": .string(Self.errorMessage(error))]
            mutation.error = Self.queryError(error, source: .mutation, statementId: statementId, toolName: mutation.toolName)
        }

        rebuildSnapshot()
        notify()

        if success, let refreshQueryIds, !refreshQueryIds.isEmpty {
            invalidate(refreshQueryIds)
        }
        return success
    }

    /// The `{ status, data?, error? }` result of a mutation, or `nil` if there is no such mutation.
    func mutationResult(for statementId: String) -> OpenUIValue? {
        mutations[statementId]?.result
    }

    // MARK: - Lifecycle

    func activate() {
        disposed = false
    }

    // Stops the refresh timers while their reply is off screen, keeping the queries and their data.
    func pauseRefreshes() {
        refreshesPaused = true
        for query in queries.values {
            query.timer?.cancel()
            query.timer = nil
        }
    }

    func resumeRefreshes() {
        guard refreshesPaused else { return }
        refreshesPaused = false
        for (statementId, query) in queries where query.refreshInterval > 0 && query.timer == nil {
            query.timer = makeRefreshTimer(query: query, statementId: statementId, interval: query.refreshInterval)
        }
    }

    /// Stops timers and in-flight bookkeeping. Cached data and query entries are kept.
    func dispose() {
        disposed = true
        generation += 1
        onChange = nil
        for query in queries.values {
            query.timer?.cancel()
            query.timer = nil
            query.pendingFetch?.cancel()
            query.pendingFetch = nil
            query.refreshInterval = 0
            query.loading = false
            query.needsRefetch = false
        }
        mutations.removeAll()
        mutationOrder.removeAll()
    }
}
