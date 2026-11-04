//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Incremental editing: merges a patch (changed/new statements) into an existing program
/// (port of `mergeStatements` in `merge.ts`).
///
/// - Same name → the patch definition replaces the existing one.
/// - New name → appended.
/// - `name = null` in the patch → the statement is deleted.
/// - Statements no longer reachable from the root are garbage-collected (`$state` is always kept).
@available(iOS 17.0, macOS 14.0, *)
enum StatementMerger {
    private struct ParsedStatement {
        let id: String
        let ast: ASTNode
        let raw: String
    }

    /// Merges `patch` into `existing` and returns the merged program text.
    static func merge(_ existing: String, patch: String, rootId: String = "root") -> String {
        let existingStatements = parseStatements(existing)
        let patchStatements = parseStatements(Preprocessor.stripFences(patch))

        if existingStatements.isEmpty {
            return patchStatements.map(\.raw).joined(separator: "\n")
        }
        if patchStatements.isEmpty { return existing }

        var merged: [String: String] = [:]
        var asts: [String: ASTNode] = [:]
        var order: [String] = []

        for statement in existingStatements {
            merged[statement.id] = statement.raw
            asts[statement.id] = statement.ast
            order.append(statement.id)
        }

        for statement in patchStatements {
            if case .null = statement.ast {
                // `name = null` in a patch deletes the statement.
                merged.removeValue(forKey: statement.id)
                asts.removeValue(forKey: statement.id)
                if let index = order.firstIndex(of: statement.id) { order.remove(at: index) }
                continue
            }
            if merged[statement.id] == nil { order.append(statement.id) }
            merged[statement.id] = statement.raw
            asts[statement.id] = statement.ast
        }

        collectGarbage(order: &order, merged: &merged, asts: asts, rootId: rootId)

        return order.compactMap { merged[$0] }.joined(separator: "\n")
    }

    /// Splits source into statements at depth-0 newlines (string- and bracket-aware).
    private static func splitStatementSource(_ input: String) -> [String] {
        let bytes = Array(input.utf8)
        var statements: [String] = []
        var depth = 0
        var inString: UInt8?
        var escaped = false
        var start = 0

        for (i, c) in bytes.enumerated() {
            if escaped {
                escaped = false
                continue
            }
            if c == UInt8(ascii: "\\"), inString != nil {
                escaped = true
                continue
            }
            if let quote = inString {
                if c == quote { inString = nil }
                continue
            }
            switch c {
            case UInt8(ascii: "\""), UInt8(ascii: "'"):
                inString = c
            case UInt8(ascii: "("), UInt8(ascii: "["), UInt8(ascii: "{"):
                depth += 1
            case UInt8(ascii: ")"), UInt8(ascii: "]"), UInt8(ascii: "}"):
                depth = max(0, depth - 1)
            case 0x0a where depth <= 0:
                let statement = JS.trim(String(decoding: bytes[start..<i], as: UTF8.self))
                if !statement.isEmpty { statements.append(statement) }
                start = i + 1
            default:
                break
            }
        }

        let tail = JS.trim(String(decoding: bytes[min(start, bytes.count)...], as: UTF8.self))
        if !tail.isEmpty { statements.append(tail) }
        return statements
    }

    private static func parseStatements(_ input: String) -> [ParsedStatement] {
        let trimmed = JS.trim(input)
        guard !trimmed.isEmpty else { return [] }
        return splitStatementSource(trimmed).compactMap { raw in
            guard let statement = Statements.split(Lexer.tokenize(raw)).first else { return nil }
            return ParsedStatement(id: statement.id, ast: ExpressionParser.parse(statement.tokens), raw: raw)
        }
    }

    private static func collectGarbage(order: inout [String], merged: inout [String: String], asts: [String: ASTNode], rootId: String) {
        guard asts[rootId] != nil else { return }

        var reachable: Set<String> = [rootId]
        var queue = [rootId]
        while let id = queue.popLast() {
            guard let ast = asts[id] else { continue }
            var refs: [String] = []
            ast.walk { node in
                switch node {
                case .ref(let name), .runtimeRef(let name, _):
                    refs.append(name)
                default:
                    break
                }
            }
            for ref in refs where !reachable.contains(ref) && asts[ref] != nil {
                reachable.insert(ref)
                queue.append(ref)
            }
        }

        // $state variables are bound at runtime, not via references — always keep them.
        for id in order where id.hasPrefix("$") {
            reachable.insert(id)
        }

        for index in order.indices.reversed() where !reachable.contains(order[index]) {
            merged.removeValue(forKey: order[index])
            order.remove(at: index)
        }
    }
}
