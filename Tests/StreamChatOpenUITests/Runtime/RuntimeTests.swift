//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChatOpenUI
import Testing

/// Polls `condition` on the main actor until it holds or the timeout elapses.
@MainActor
// Polls every 10 ms, up to `timeout` worth of polls. It counts polls rather than time, so tests
// running in parallel that keep the main actor busy don't make it give up early.
func waitUntil(timeout: TimeInterval = 30, _ condition: @MainActor () -> Bool) async -> Bool {
    for _ in 0..<Int(timeout * 100) {
        if condition() { return true }
        try? await Task.sleep(nanoseconds: 10_000_000)
    }
    return condition()
}

/// A tool provider that records calls and returns scripted results.
final class RecordingToolProvider: OpenUIToolProvider, @unchecked Sendable {
    private let lock = NSLock()
    private var _calls: [(String, OpenUIObject)] = []
    private var _userInitiated: [Bool] = []
    let handler: @Sendable (String, OpenUIObject, Int) async throws -> OpenUIValue
    let minimumRefreshInterval: TimeInterval

    init(minimumRefreshInterval: TimeInterval = 0.01, handler: @escaping @Sendable (String, OpenUIObject, Int) async throws -> OpenUIValue) {
        self.handler = handler
        self.minimumRefreshInterval = minimumRefreshInterval
    }

    var calls: [(String, OpenUIObject)] {
        lock.lock()
        defer { lock.unlock() }
        return _calls
    }

    var userInitiated: [Bool] {
        lock.withLock { _userInitiated }
    }

    func callTool(_ name: String, arguments: OpenUIObject) async throws -> OpenUIValue {
        let count = record(name, arguments)
        return try await handler(name, arguments, count)
    }

    func callTool(_ name: String, arguments: OpenUIObject, userInitiated: Bool) async throws -> OpenUIValue {
        lock.withLock { _userInitiated.append(userInitiated) }
        return try await callTool(name, arguments: arguments)
    }

    private func record(_ name: String, _ arguments: OpenUIObject) -> Int {
        lock.withLock {
            _calls.append((name, arguments))
            return _calls.count
        }
    }
}

struct ToolFailure: Error, LocalizedError {
    var errorDescription: String? { "boom" }
}

@Suite("Store")
@MainActor
struct StoreTests {
    @Test func setGetAndChangeNotifications() {
        let store = OpenUIStore()
        var changes: [String] = []
        store.onChange = { changes.append($0) }
        store.set("$a", 1)
        store.set("$a", 1)
        store.set("$a", 2)
        store.set("$b", ["x": 1])
        store.set("$b", ["x": 1])
        #expect(store.get("$a") == 2)
        #expect(changes == ["$a", "$a", "$b"])
        store.set("$a", nil)
        #expect(store.get("$a") == nil)
    }

    @Test func initializeOnlyAddsNewDefaultsAndAppliesPersisted() {
        let store = OpenUIStore()
        store.set("$days", "30")
        store.initialize(defaults: ["$days": "7", "$title": ""], persisted: ["$restored": true])
        #expect(store.get("$days") == "30")
        #expect(store.get("$title") == "")
        #expect(store.get("$restored") == true)
        // Declarations disappearing never delete user state.
        store.initialize(defaults: [:], persisted: [:])
        #expect(store.get("$days") == "30")
    }

    @Test func defaultsFollowStreamingDeclarationsUntilTheUserChangesThem() {
        let store = OpenUIStore()
        // `$servings = "` mid-stream, then the complete declaration.
        store.initialize(defaults: ["$servings": ""], persisted: [:])
        store.initialize(defaults: ["$servings": "2"], persisted: [:])
        #expect(store.get("$servings") == "2")
        store.set("$servings", "4")
        store.initialize(defaults: ["$servings": "6"], persisted: [:])
        #expect(store.get("$servings") == "4")
        // Restored values are kept like user changes.
        store.initialize(defaults: ["$days": "7"], persisted: ["$days": "30"])
        store.initialize(defaults: ["$days": "14"], persisted: [:])
        #expect(store.get("$days") == "30")
    }
}

@Suite("Query manager")
@MainActor
struct QueryManagerTests {
    func node(_ id: String, args: OpenUIValue = [:], deps: OpenUIValue? = nil, refresh: Double? = nil) -> QueryManager.QueryNode {
        QueryManager.QueryNode(statementId: id, toolName: "list", args: args, defaults: ["rows": []], deps: deps, refreshInterval: refresh)
    }

    @Test func fetchesAndCachesResults() async {
        let provider = RecordingToolProvider { _, args, _ in ["rows": [args["q"] ?? "none"]] }
        let manager = QueryManager(toolProvider: provider)
        manager.evaluateQueries([node("data", args: ["q": "a"])])
        #expect(manager.result(for: "data") == ["rows": []])
        #expect(manager.isLoading("data"))
        #expect(await waitUntil { manager.result(for: "data") == ["rows": ["a"]] })
        #expect(!manager.isAnyLoading)

        // Same cache key: no new fetch.
        manager.evaluateQueries([node("data", args: ["q": "a"])])
        try? await Task.sleep(nanoseconds: 50_000_000)
        #expect(provider.calls.count == 1)
    }

    @Test func refetchesWhenArgumentsChangeAndKeepsPreviousDataWhileLoading() async {
        let provider = RecordingToolProvider { _, args, _ in
            try await Task.sleep(nanoseconds: 80_000_000)
            return ["rows": [args["q"] ?? "none"]]
        }
        let manager = QueryManager(toolProvider: provider)
        manager.evaluateQueries([node("data", args: ["q": "a"], deps: ["$q": "a"])])
        #expect(await waitUntil { manager.result(for: "data") == ["rows": ["a"]] })

        manager.evaluateQueries([node("data", args: ["q": "b"], deps: ["$q": "b"])])
        #expect(manager.isLoading("data"))
        #expect(manager.result(for: "data") == ["rows": ["a"]], "previous data stays visible while refetching")
        #expect(manager.snapshot.refetching == ["data"])
        #expect(await waitUntil { manager.result(for: "data") == ["rows": ["b"]] })
        #expect(provider.calls.count == 2)
    }

    @Test func argumentChangesFetchOnceThePersonPauses() async {
        let provider = RecordingToolProvider { _, args, _ in ["rows": [args["q"] ?? "none"]] }
        let manager = QueryManager(toolProvider: provider)
        manager.evaluateQueries([node("data", args: ["q": ""], deps: ["$q": ""])])
        #expect(await waitUntil { manager.result(for: "data") == ["rows": [""]] })

        for typed in ["O", "Oh", "Ohr", "Ohri", "Ohrid"] {
            manager.evaluateQueries([node("data", args: ["q": .string(typed)], deps: ["$q": .string(typed)])])
        }

        #expect(manager.isLoading("data"), "it shows as refetching while it waits")
        #expect(await waitUntil { manager.result(for: "data") == ["rows": ["Ohrid"]] })
        #expect(provider.calls.map { $0.1["q"] } == ["", "Ohrid"])
    }

    @Test func queriesRunToolsByThemselvesAndMutationsAsTaps() async {
        let provider = RecordingToolProvider { _, _, _ in ["ok": true] }
        let manager = QueryManager(toolProvider: provider)
        manager.registerMutations([.init(statementId: "create", toolName: "create")])

        manager.evaluateQueries([node("data")])
        #expect(await waitUntil { provider.userInitiated.count == 1 })
        _ = await manager.fireMutation("create", arguments: [:])

        #expect(provider.userInitiated == [false, true])
    }

    @Test func togglingBackToCachedArgumentsWhileAFetchIsInFlightStopsLoading() async {
        let provider = RecordingToolProvider { _, args, _ in
            if args["q"] == "b" { try await Task.sleep(nanoseconds: 150_000_000) }
            return ["rows": [args["q"] ?? "none"]]
        }
        let manager = QueryManager(toolProvider: provider)
        manager.evaluateQueries([node("data", args: ["q": "a"], deps: ["$q": "a"])])
        #expect(await waitUntil { manager.result(for: "data") == ["rows": ["a"]] })

        manager.evaluateQueries([node("data", args: ["q": "b"], deps: ["$q": "b"])])
        manager.evaluateQueries([node("data", args: ["q": "a"], deps: ["$q": "a"])])

        #expect(!manager.isLoading("data"))
        #expect(manager.result(for: "data") == ["rows": ["a"]])
        try? await Task.sleep(nanoseconds: 250_000_000)
        #expect(!manager.isAnyLoading, "the superseded fetch finishing doesn't leave it loading")
        #expect(manager.result(for: "data") == ["rows": ["a"]])
    }

    @Test func invalidateRefetchesAndQueuesWhileInFlight() async {
        let provider = RecordingToolProvider { _, _, count in
            try await Task.sleep(nanoseconds: 50_000_000)
            return ["n": .number(Double(count))]
        }
        let manager = QueryManager(toolProvider: provider)
        manager.evaluateQueries([node("data")])
        manager.invalidate(["data"]) // in flight → queued
        #expect(await waitUntil { provider.calls.count == 2 && !manager.isAnyLoading })
        #expect(manager.result(for: "data") == ["n": 2])
        manager.invalidate()
        #expect(await waitUntil { manager.result(for: "data") == ["n": 3] })
    }

    @Test func reportsToolErrors() async {
        let manager = QueryManager(toolProvider: FunctionToolProvider(["other": { _ in .null }]))
        manager.evaluateQueries([node("data")])
        #expect(await waitUntil { !manager.snapshot.errors.isEmpty })
        let error = manager.snapshot.errors[0]
        #expect(error.code == "tool-not-found")
        #expect(error.source == .query)
        #expect(error.statementId == "data")
        #expect(error.hint == "Available tools: other")
        #expect(manager.result(for: "data") == ["rows": []], "defaults remain")

        let failing = QueryManager(toolProvider: RecordingToolProvider { _, _, _ in throw ToolFailure() })
        failing.evaluateQueries([node("data")])
        #expect(await waitUntil { failing.snapshot.errors.first?.code == "tool-error" })
        #expect(failing.snapshot.errors.first?.message == "Query \"list\" failed: boom")
    }

    @Test func refreshIntervalRefetchesPeriodicallyAndStopsWhenRemoved() async {
        let provider = RecordingToolProvider { _, _, count in ["n": .number(Double(count))] }
        let manager = QueryManager(toolProvider: provider)
        manager.evaluateQueries([node("health", refresh: 0.05)])
        #expect(await waitUntil { provider.calls.count >= 3 })
        manager.evaluateQueries([])
        let count = provider.calls.count
        try? await Task.sleep(nanoseconds: 200_000_000)
        #expect(provider.calls.count <= count + 1)
    }

    @Test func refreshIntervalWaitsAtLeastTheToolProvidersMinimum() async {
        let provider = RecordingToolProvider(minimumRefreshInterval: 3600) { _, _, count in ["n": .number(Double(count))] }
        let manager = QueryManager(toolProvider: provider)
        manager.evaluateQueries([node("health", refresh: 0.001)])
        #expect(await waitUntil { provider.calls.count == 1 })
        try? await Task.sleep(nanoseconds: 200_000_000)

        #expect(provider.calls.count == 1)
        manager.evaluateQueries([])
    }

    @Test func refreshesPauseWhileTheirReplyIsOffScreen() async {
        let provider = RecordingToolProvider(minimumRefreshInterval: 0.01) { _, _, count in ["n": .number(Double(count))] }
        let manager = QueryManager(toolProvider: provider)
        manager.evaluateQueries([node("health", refresh: 0.02)])
        #expect(await waitUntil { provider.calls.count >= 2 })

        manager.pauseRefreshes()
        let paused = provider.calls.count
        try? await Task.sleep(nanoseconds: 150_000_000)
        #expect(provider.calls.count <= paused + 1)

        manager.resumeRefreshes()
        #expect(await waitUntil { provider.calls.count >= paused + 3 })
        manager.evaluateQueries([])
    }

    @Test func mutationsReportStatusAndRejectConcurrentCalls() async {
        let provider = RecordingToolProvider { name, args, _ in
            try await Task.sleep(nanoseconds: 30_000_000)
            if name == "fail" { throw ToolFailure() }
            return ["id": "42", "title": args["title"] ?? .null]
        }
        let manager = QueryManager(toolProvider: provider)
        manager.registerMutations([.init(statementId: "create", toolName: "create"), .init(statementId: "broken", toolName: "fail")])
        #expect(manager.mutationResult(for: "create") == ["status": "idle", "data": .null, "error": .null])

        async let first = manager.fireMutation("create", arguments: ["title": "A"])
        try? await Task.sleep(nanoseconds: 5_000_000)
        #expect(manager.mutationResult(for: "create")?["status"] == "loading")
        let rejected = await manager.fireMutation("create", arguments: [:])
        #expect(rejected == false)
        #expect(await first == true)
        #expect(manager.mutationResult(for: "create") == ["status": "success", "data": ["id": "42", "title": "A"]])

        #expect(await manager.fireMutation("broken", arguments: [:]) == false)
        #expect(manager.mutationResult(for: "broken") == ["status": "error", "error": "boom"])
        #expect(manager.snapshot.errors.first?.source == .mutation)
    }
}

@Suite("Runtime")
@MainActor
struct RuntimeTests {
    let library = ComponentLibrary.openUIChat

    func texts(_ runtime: OpenUIRuntime) -> [String] {
        var result: [String] = []
        func walk(_ value: OpenUIValue) {
            switch value {
            case .element(let element):
                if element.typeName == "TextContent", let text = element.props["text"] { result.append(JS.toString(text)) }
                for item in element.props.values { walk(item) }
            case .array(let items):
                for item in items { walk(item) }
            case .object(let object):
                for item in object.values { walk(item) }
            default:
                break
            }
        }
        if let root = runtime.root { walk(.element(root)) }
        return result
    }

    @Test func streamsAndEvaluatesState() {
        let runtime = OpenUIRuntime(library: library)
        runtime.update(response: "root = Card([greeting])\n$name = \"Ada\"\ngreeting = TextContent(\"Hi \" + $na", isStreaming: true)
        #expect(runtime.root?.typeName == "Card")
        #expect(runtime.parseResult?.meta.incomplete == true)
        runtime.update(response: "root = Card([greeting])\n$name = \"Ada\"\ngreeting = TextContent(\"Hi \" + $name)", isStreaming: false)
        #expect(texts(runtime) == ["Hi Ada"])
        runtime.store.set("$name", "Grace")
        #expect(texts(runtime) == ["Hi Grace"])
    }

    @Test func reactiveFieldsWriteTheBoundVariable() {
        let runtime = OpenUIRuntime(library: library)
        runtime.update(response: """
        root = Card([field, echo])
        field = Input("name", "Name", "text", null, $name)
        echo = TextContent("Typed: " + $name)
        """, isStreaming: false)
        let input = runtime.root?.props["children"]?.arrayValue?.first?.elementValue
        let binding = input?.props["value"]
        #expect(ReactiveBinding.target(of: binding) == "$name")
        let field = runtime.stateField(name: "name", binding: binding, formName: nil)
        #expect(field.isReactive)
        field.set("Linus")
        #expect(runtime.store.get("$name") == "Linus")
        #expect(texts(runtime).contains("Typed: Linus"))
    }

    @Test func aSecretFieldNeverGoesInItsVariable() {
        let runtime = OpenUIRuntime(library: library)
        runtime.update(response: """
        root = Card([field, echo])
        field = Input("pw", "Password", "password", null, $pw)
        echo = TextContent("Typed: " + $pw)
        """, isStreaming: false)
        let binding = runtime.root?.props["children"]?.arrayValue?.first?.elementValue?.props["value"]

        let field = runtime.stateField(name: "pw", binding: binding, formName: "login", componentType: "Input", isSecret: true)
        field.set("hunter22")

        #expect(!field.isReactive)
        #expect(runtime.store.get("$pw") == nil || runtime.store.get("$pw") == .null)
        #expect(!texts(runtime).contains("Typed: hunter22"))
        #expect(runtime.fieldValue(formName: "login", name: "pw") == "hunter22")
        #expect(runtime.store.snapshot.withoutSecrets["login"]?.objectValue?["pw"] == nil)
    }

    @Test func formFieldsAreStoredUnderTheFormName() {
        var updates: [OpenUIObject] = []
        let runtime = OpenUIRuntime(library: library)
        runtime.onStateUpdate = { updates.append($0) }
        runtime.update(response: "root = Card([TextContent(\"x\")])", isStreaming: false)
        let field = runtime.stateField(name: "email", binding: nil, formName: "contact", componentType: "Input")
        #expect(!field.isReactive)
        field.set("a@b.co")
        #expect(runtime.fieldValue(formName: "contact", name: "email") == "a@b.co")
        #expect(runtime.store.get("contact") == ["email": ["value": "a@b.co", "componentType": "Input"]])
        #expect(updates.last?["contact"] != nil)
        #expect(runtime.formPayload("contact") == ["contact": ["email": ["value": "a@b.co", "componentType": "Input"]]])
    }

    @Test func actionPlansRunStepsInOrder() async {
        var events: [ActionEvent] = []
        let provider = RecordingToolProvider { name, args, _ in
            name == "save" ? ["ok": true, "title": args["title"] ?? .null] : ["rows": []]
        }
        let runtime = OpenUIRuntime(library: library, toolProvider: provider)
        runtime.onAction = { events.append($0) }
        runtime.update(response: """
        $title = "Draft"
        $saved = false
        data = Query("list", {}, {rows: []})
        save = Mutation("save", {title: $title})
        root = Card([btn])
        btn = Button("Save", Action([@Run(save), @Set($saved, true), @Run(data), @Reset($title), @ToAssistant("Saved " + $title, "ctx"), @OpenUrl("https://example.com")]))
        """, isStreaming: false)
        runtime.store.set("$title", "Final")
        #expect(await waitUntil { !runtime.isQueryLoading })

        let action = runtime.root?.props["children"]?.arrayValue?.first?.elementValue?.props["action"]
        await runtime.triggerAction(label: "Save", action: action)

        #expect(provider.calls.first { $0.0 == "save" }?.1 == ["title": "Final"])
        #expect(runtime.store.get("$saved") == true)
        #expect(runtime.store.get("$title") == "Draft", "@Reset restores the declared default")
        #expect(runtime.queryManager.mutationResult(for: "save")?["status"] == "success")
        #expect(events.count == 2)
        #expect(events[0].type == BuiltinActionType.continueConversation)
        #expect(events[0].humanFriendlyMessage == "Saved Final", "evaluated when the plan was built")
        #expect(events[0].context == "ctx")
        #expect(events[1].type == BuiltinActionType.openURL)
        #expect(events[1].url == URL(string: "https://example.com"))
        #expect(await waitUntil { provider.calls.filter { $0.0 == "list" }.count == 2 }, "@Run(query) refetches")
    }

    @Test func failingMutationHaltsThePlan() async {
        var events: [ActionEvent] = []
        let runtime = OpenUIRuntime(library: library, toolProvider: RecordingToolProvider { _, _, _ in throw ToolFailure() })
        runtime.onAction = { events.append($0) }
        runtime.update(response: """
        $done = false
        save = Mutation("save", {})
        root = Card([Button("Go", Action([@Run(save), @Set($done, true), @ToAssistant("next")]))])
        """, isStreaming: false)
        let action = runtime.root?.props["children"]?.arrayValue?.first?.elementValue?.props["action"]
        await runtime.triggerAction(label: "Go", action: action)
        #expect(runtime.store.get("$done") == false)
        #expect(events.isEmpty)
        #expect(runtime.queryManager.mutationResult(for: "save")?["status"] == "error")
    }

    @Test func legacyAndDefaultActions() async {
        var events: [ActionEvent] = []
        let runtime = OpenUIRuntime(library: library)
        runtime.onAction = { events.append($0) }
        runtime.update(response: "root = Card([TextContent(\"x\")])", isStreaming: false)
        await runtime.triggerAction(label: "Plan", action: ["type": "continue_conversation", "context": "Help me plan"])
        await runtime.triggerAction(label: "Open", action: ["type": "open_url", "url": "https://openui.com"])
        await runtime.triggerAction(label: "Tell me more")
        #expect(events.map(\.type) == ["continue_conversation", "open_url", "continue_conversation"])
        #expect(events[0].context == "Help me plan")
        #expect(events[1].url?.absoluteString == "https://openui.com")
        #expect(events[2].humanFriendlyMessage == "Tell me more")
        #expect(events[2].assistantMessage.hasPrefix(MessageEnvelope.contentMarker + "\nTell me more"))
    }

    @Test func queryResultsFlowIntoTheTree() async {
        let tools = FunctionToolProvider([
            "list_hotels": { args in
                let max = JS.toNumber(args["maxPrice"])
                let hotels: [OpenUIValue] = [["name": "Alfama Inn", "price": 90], ["name": "Chiado Grand", "price": 210]]
                return ["hotels": .array(hotels.filter { JS.toNumber($0["price"]) <= max })]
            }
        ])
        let runtime = OpenUIRuntime(library: library, toolProvider: tools)
        runtime.update(response: """
        $max = 300
        hotels = Query("list_hotels", {maxPrice: $max}, {hotels: []})
        root = Card([count])
        count = TextContent("" + @Count(hotels.hotels) + " hotels: " + hotels.hotels.name)
        """, isStreaming: true)
        #expect(texts(runtime) == ["0 hotels: "], "queries wait for streaming to end")
        runtime.update(response: runtime.response, isStreaming: false)
        #expect(await waitUntil { texts(runtime) == ["2 hotels: Alfama Inn,Chiado Grand"] })
        runtime.store.set("$max", 100)
        #expect(await waitUntil { texts(runtime) == ["1 hotels: Alfama Inn"] })
    }

    @Test func bindingDefaultsSplitAcrossChunksUseTheFinalValue() async {
        let tools = RecordingToolProvider { _, args, _ in ["servings": args["servings"] ?? .null] }
        let runtime = OpenUIRuntime(library: library, toolProvider: tools)
        let program = """
        root = Card([summary])
        $servings = "2"
        recipe = Query("scale_recipe", {servings: $servings}, {servings: 0})
        summary = TextContent("Serves " + recipe.servings)
        """
        // Render at every chunk boundary, including inside `"2"` and inside `$limit`-style numbers.
        for end in program.indices.dropFirst() {
            runtime.update(response: String(program[..<end]), isStreaming: true)
        }
        runtime.update(response: program, isStreaming: false)
        #expect(runtime.store.get("$servings") == "2")
        #expect(await waitUntil { texts(runtime) == ["Serves 2"] })
        #expect(tools.calls.map { JS.toString($0.1["servings"]) } == ["2"])
    }

    @Test func reportsErrorsAfterStreaming() {
        var reported: [[OpenUIError]] = []
        let runtime = OpenUIRuntime(library: library)
        runtime.onError = { reported.append($0) }
        runtime.update(response: "root = Card([Ghost(\"x\")])", isStreaming: true)
        #expect(reported.isEmpty)
        runtime.update(response: "root = Card([Ghost(\"x\")])", isStreaming: false)
        #expect(reported.last?.first?.code == "unknown-component")
        #expect(reported.last?.first?.hint?.hasPrefix("Available components: Card") == true)
        runtime.update(response: "root = Card([Ghost(\"x\")])\n", isStreaming: true)
        #expect(reported.last == [])

        let empty = OpenUIRuntime(library: library)
        var emptyErrors: [OpenUIError] = []
        empty.onError = { emptyErrors = $0 }
        empty.update(response: "just some text", isStreaming: false)
        #expect(emptyErrors.first?.code == "parse-failed")
    }

    @Test func restoresInitialState() {
        let runtime = OpenUIRuntime(library: library, initialState: ["$name": "Restored", "contact": ["email": ["value": "x@y.z"]]])
        runtime.update(response: "$name = \"Default\"\nroot = Card([TextContent($name)])", isStreaming: false)
        #expect(texts(runtime) == ["Restored"])
        #expect(runtime.fieldValue(formName: "contact", name: "email") == "x@y.z")
    }
}
