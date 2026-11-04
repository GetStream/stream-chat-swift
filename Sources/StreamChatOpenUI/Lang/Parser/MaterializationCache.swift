//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

// What each statement materialized to while a response streams, with everything that read
// reported, so the next chunk reuses it as long as none of the statements it read has changed.
@available(iOS 17.0, macOS 14.0, *)
struct MaterializationCache: Sendable {
    struct Key: Hashable, Sendable {
        let name: String
        let expression: Bool
        let partial: Bool
    }

    // A statement read by name, with the version it had, or nil when it wasn't declared.
    struct Read: Sendable {
        let name: String
        let version: Int?
    }

    struct Entry: Sendable {
        let result: Materializer.RefResult
        let version: Int?
        let reads: [Read]
        let errors: [ValidationError]
        let unresolved: [String]
        let reached: [String]
        let nodes: Int
        let height: Int
    }

    struct StateReferences: Sendable {
        let version: Int
        let names: [String]
    }

    // Each statement's version, which changes whenever its expression may have.
    var versions: [String: Int] = [:]
    var entries: [Key: Entry] = [:]
    var stateReferences: [String: StateReferences] = [:]
    // How many nodes were materialized afresh, not reused, over all passes.
    var materializedNodes = 0

    func isCurrent(_ reads: [Read]) -> Bool {
        reads.allSatisfy { versions[$0.name] == $0.version }
    }
}

// Where a statement's materialization started in the logs of its pass, so what it read and
// reported can be kept with its result.
@available(iOS 17.0, macOS 14.0, *)
struct MaterializationStart {
    let reads: Int
    let errors: Int
    let unresolved: Int
    let reached: Int
    let nodes: Int
    let cycles: Int
    let truncations: Int
    let depth: Int
    let deepest: Int
}

@available(iOS 17.0, macOS 14.0, *)
extension MaterializeContext {
    func lookUp(_ name: String) -> ASTNode? {
        if cache != nil {
            reads.append(MaterializationCache.Read(name: name, version: cache?.versions[name]))
        }
        return symbols[name]
    }

    // A statement's earlier result, reporting again what it reported, when everything it read is
    // unchanged and it fits the depth and nodes left.
    func reuse(_ name: String, expression: Bool) -> Materializer.RefResult? {
        let key = MaterializationCache.Key(name: name, expression: expression, partial: partial)
        guard let cache,
              let entry = cache.entries[key],
              entry.version == cache.versions[name],
              depth + entry.height <= Materializer.maxDepth,
              nodes + entry.nodes <= Materializer.maxNodes,
              cache.isCurrent(entry.reads) else { return nil }
        reads.append(contentsOf: entry.reads)
        errors.append(contentsOf: entry.errors)
        unresolved.append(contentsOf: entry.unresolved)
        for id in entry.reached {
            markReached(id)
        }
        nodes += entry.nodes
        deepest = max(deepest, depth + entry.height)
        return entry.result
    }

    func startMaterializing() -> MaterializationStart? {
        guard cache != nil else { return nil }
        let start = MaterializationStart(
            reads: reads.count,
            errors: errors.count,
            unresolved: unresolved.count,
            reached: reachedLog.count,
            nodes: nodes,
            cycles: cycles,
            truncations: truncations,
            depth: depth,
            deepest: deepest
        )
        deepest = depth
        return start
    }

    // Keeps a statement's result, unless it met a cycle or a limit, which depend on where the
    // statement is used.
    func finishMaterializing(_ start: MaterializationStart?, name: String, expression: Bool, result: Materializer.RefResult) {
        guard let start else { return }
        let height = deepest - start.depth
        deepest = max(start.deepest, deepest)
        guard cycles == start.cycles, truncations == start.truncations else { return }
        var readNames = Set<String>()
        var reachedNames = Set<String>()
        let entry = MaterializationCache.Entry(
            result: result,
            version: cache?.versions[name],
            reads: reads[start.reads...].filter { readNames.insert($0.name).inserted },
            errors: Array(errors[start.errors...]),
            unresolved: Array(unresolved[start.unresolved...]),
            reached: reachedLog[start.reached...].filter { reachedNames.insert($0).inserted },
            nodes: nodes - start.nodes,
            height: height
        )
        cache?.entries[MaterializationCache.Key(name: name, expression: expression, partial: partial)] = entry
    }
}
