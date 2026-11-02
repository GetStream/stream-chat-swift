//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Insertion-ordered statement table (mirrors a JavaScript `Map`: re-setting a key keeps its position).
@available(iOS 17.0, macOS 14.0, *)
struct StatementTable: Sendable {
    private(set) var order: [String] = []
    private var statements: [String: Statement] = [:]

    var count: Int { order.count }
    var values: [Statement] { order.compactMap { statements[$0] } }

    func contains(_ id: String) -> Bool { statements[id] != nil }

    subscript(id: String) -> Statement? {
        statements[id]
    }

    mutating func set(_ statement: Statement) {
        if statements.updateValue(statement, forKey: statement.id) == nil {
            order.append(statement.id)
        }
    }

    mutating func removeAll() {
        order.removeAll()
        statements.removeAll()
    }
}

/// Parses complete OpenUI Lang programs.
///
/// ```swift
/// let parser = OpenUIParser(library: .openUIChat)
/// let result = parser.parse(source)
/// result.root      // ElementNode tree
/// result.meta      // incomplete / unresolved / orphaned / errors
/// ```
@available(iOS 17.0, macOS 14.0, *)
public struct OpenUIParser: Sendable {
    public let paramMap: ParamMap
    public let rootName: String?

    /// Creates a parser from a compiled parameter map.
    public init(paramMap: ParamMap, rootName: String? = nil) {
        self.paramMap = paramMap
        self.rootName = rootName
    }

    /// Creates a parser from a library JSON Schema document (`library.toJSONSchema()`).
    public init(schema: OpenUIValue, rootName: String? = nil) {
        self.init(paramMap: Self.compileSchema(schema), rootName: rootName)
    }

    /// Parses a complete (or partial) program in one pass.
    public func parse(_ input: String) -> ParseResult {
        Self.parse(input, paramMap: paramMap, rootName: rootName)
    }

    // MARK: - Schema compilation

    /// The action `$defs` of every library: `action` props are `{"$ref": "#/$defs/ActionExpression"}`.
    static let actionDefinitionNames = ["ActionExpression", "OpenUrl", "ToAssistant"]

    /// Compiles a library JSON Schema into positional parameter definitions. Each component lives in
    /// `$defs` (keyed by name); its `properties` order defines the positional argument order. The
    /// library's `functions` and `actions` join the built-in calls.
    public static func compileSchema(_ schema: OpenUIValue) -> ParamMap {
        var map = ParamMap()
        guard case .object(let root) = schema else { return map }
        let definitions = root["$defs"]?.objectValue ?? [:]
        let componentNames = root["properties"]?.objectValue.map { Set($0.keys) }
        // Action $defs (ActionExpression, OpenUrl, custom actions) are data shapes, never components.
        var actionDefinitions: [String: OpenUIValue] = [:]
        for name in actionDefinitionNames + (root["actions"]?.objectValue?.keys ?? []) {
            if let body = definitions[name], componentNames?.contains(name) != true {
                actionDefinitions["#/$defs/\(name)"] = body
            }
        }
        for (name, definition) in definitions.entries {
            // Skip non-component defs (e.g. zod's hoisted recursive schemas).
            if let componentNames {
                if !componentNames.contains(name) { continue }
            } else if actionDefinitions["#/$defs/\(name)"] != nil {
                continue
            }
            map[name] = compileParams(definition, actionDefinitions)
        }
        for (name, function) in root["functions"]?.objectValue?.entries ?? [] {
            map.callDefs[name] = CallDef(kind: .function, params: compileParams(function["params"], actionDefinitions))
        }
        for (name, action) in root["actions"]?.objectValue?.entries ?? [] {
            map.callDefs[name] = CallDef(kind: .action, params: compileParams(action["params"], actionDefinitions))
        }
        return map
    }

    private static func compileParams(_ definition: OpenUIValue?, _ actionDefinitions: [String: OpenUIValue]) -> [ParamDef] {
        let properties = definition?["properties"]?.objectValue ?? [:]
        let required = (definition?["required"]?.arrayValue ?? []).compactMap(\.stringValue)
        return properties.entries.map { key, property in
            ParamDef(
                name: key,
                required: required.contains(key),
                defaultValue: SchemaValidation.defaultValue(of: property),
                schema: actionDefinitions.isEmpty ? property : inlineActionRefs(property, actionDefinitions)
            )
        }
    }

    // `{"$ref": "#/$defs/ActionExpression"}` → its body, so action slots validate as inline unions.
    private static func inlineActionRefs(_ node: OpenUIValue, _ definitions: [String: OpenUIValue]) -> OpenUIValue {
        switch node {
        case .object(let object):
            if case .string(let ref)? = object["$ref"] {
                return definitions[ref].map { inlineActionRefs($0, definitions) } ?? node
            }
            return .object(object.mapValues { inlineActionRefs($0, definitions) })
        case .array(let items):
            return .array(items.map { inlineActionRefs($0, definitions) })
        default:
            return node
        }
    }

    // MARK: - Core pipeline

    static func parse(_ input: String, paramMap: ParamMap?, rootName: String?) -> ParseResult {
        let trimmed = Preprocessor.preprocess(input)
        if trimmed.isEmpty { return .empty() }

        let (text, wasIncomplete) = Statements.autoClose(trimmed)
        let raw = Statements.split(Lexer.tokenize(text))
        if raw.isEmpty { return .empty(incomplete: wasIncomplete) }

        var table = StatementTable()
        for statement in raw {
            table.set(classify(statement, ExpressionParser.parse(statement.tokens)))
        }
        return buildResult(table, wasIncomplete: wasIncomplete, statementCount: table.count, paramMap: paramMap, rootName: rootName)
    }

    /// Classifies a statement from its identifier token and expression shape.
    static func classify(_ raw: RawStatement, _ expression: ASTNode) -> Statement {
        if case .comp(let name, let args, _, _) = expression {
            if name == Builtins.query {
                let deps = args.count > 1 ? args[1].stateReferences : []
                return .query(id: raw.id, args: args, expr: expression, deps: deps.isEmpty ? nil : deps)
            }
            if name == Builtins.mutation {
                return .mutation(id: raw.id, args: args, expr: expression)
            }
        }
        if raw.idKind == .stateVar {
            return .state(id: raw.id, initial: expression)
        }
        return .value(id: raw.id, expr: expression)
    }

    /// A call to a library component: not an `@` function, built-in, `Query` or `Mutation`.
    private static func componentCallName(_ node: ASTNode?) -> String? {
        guard case .comp(let name, _, _, let isFunction)? = node,
              !isFunction,
              !Builtins.isBuiltin(name),
              !Builtins.isReservedCall(name) else { return nil }
        return name
    }

    /// The entry: `root`, else the first statement that calls the root component (a fallback).
    private static func pickEntry(_ table: StatementTable, rootName: String?) -> (id: String, isFallback: Bool)? {
        if table.contains("root") { return ("root", false) }
        for statement in table.values {
            if case .value(let id, let expression) = statement, let name = componentCallName(expression), name == rootName {
                return (id, true)
            }
        }
        return nil
    }

    /// Follows refs to the entry's value; a component call that didn't render was dropped by validation.
    private static func resolvesToComponentCall(_ node: ASTNode?, _ symbols: [String: ASTNode]) -> Bool {
        var node = node
        var seen = Set<String>()
        while case .ref(let name)? = node, seen.insert(name).inserted {
            node = symbols[name]
        }
        return componentCallName(node) != nil
    }

    /// Whether a runtime expression can produce a component, such as `$t ? A : B`.
    private static func containsComponent(_ node: ASTNode) -> Bool {
        var found = false
        node.walk { current in
            if componentCallName(current) != nil { found = true }
        }
        return found
    }

    /// A `$name` at the very end of streamed text, which may still be growing (`$d` of `$dishes`).
    struct PartialReference {
        let name: String
        let statementIds: Set<String>
    }

    static func buildResult(
        _ table: StatementTable,
        wasIncomplete: Bool,
        statementCount: Int,
        paramMap: ParamMap?,
        rootName: String?,
        partialReference: PartialReference? = nil
    ) -> ParseResult {
        let entry = pickEntry(table, rootName: rootName)

        var symbols: [String: ASTNode] = [:]
        var unreached: [String] = []
        for statement in table.values {
            symbols[statement.id] = statement.symbol
            switch statement {
            case .value where statement.id != entry?.id:
                unreached.append(statement.id)
            default:
                break
            }
        }

        let context = MaterializeContext(
            symbols: symbols,
            catalog: paramMap,
            partial: wasIncomplete,
            currentStatementId: entry?.id,
            unreached: unreached
        )
        var root: ElementNode?
        var rootExpression: ASTNode?
        if let entry, let entrySymbol = symbols[entry.id] {
            switch Materializer.materializeValue(entrySymbol, context) {
            case .element(var element):
                element.statementId = entry.id
                root = element
            case .expression(let expression) where containsComponent(expression):
                rootExpression = expression
            default:
                break
            }
        }

        // Extract typed declarations (state defaults are materialized to plain values).
        var stateDeclarations = OpenUIObject()
        var queries: [QueryStatementInfo] = []
        var mutations: [MutationStatementInfo] = []
        let statements = table.values
        for statement in statements {
            switch statement {
            case .state(let id, let initial):
                stateDeclarations[id] = Materializer.materializeValue(initial, context)
            case .query(let id, let rawArgs, _, let deps):
                let args = Materializer.nameRawCallArgs(rawArgs, context, statementId: id)
                queries.append(QueryStatementInfo(
                    statementId: id,
                    toolAST: args.count > 0 ? args[0] : nil,
                    argsAST: args.count > 1 ? args[1] : nil,
                    defaultsAST: args.count > 2 ? args[2] : nil,
                    refreshAST: args.count > 3 ? args[3] : nil,
                    deps: deps,
                    complete: true
                ))
            case .mutation(let id, let rawArgs, _):
                let args = Materializer.nameRawCallArgs(rawArgs, context, statementId: id)
                mutations.append(MutationStatementInfo(
                    statementId: id,
                    toolAST: args.count > 0 ? args[0] : nil,
                    argsAST: args.count > 1 ? args[1] : nil
                ))
            case .value:
                break
            }
        }

        // Auto-declare: any $variable referenced but not declared gets a null default, except a
        // `$name` that may still be streaming in.
        for statement in statements {
            let nodes: [ASTNode]
            switch statement {
            case .state(_, let initial): nodes = [initial]
            case .value(_, let expression): nodes = [expression]
            case .query(_, let args, _, _), .mutation(_, let args, _): nodes = args
            }
            for node in nodes {
                for dependency in node.stateReferences where !stateDeclarations.contains(dependency) {
                    if let partialReference, partialReference.name == dependency, partialReference.statementIds.contains(statement.id) {
                        continue
                    }
                    stateDeclarations[dependency] = .null
                }
            }
        }

        // Streaming consumers drop parser errors until the stream ends, so this reads as a stream-end check.
        context.currentStatementId = entry?.id
        let component = rootName ?? ""
        if entry == nil {
            SchemaValidation.push(context, component: component, path: "", issue: .noRoot(.missing))
        } else if let entry, root == nil, rootExpression == nil, !resolvesToComponentCall(symbols[entry.id], symbols) {
            SchemaValidation.push(context, component: component, path: "", issue: .noRoot(.notComponent))
        } else if let entry, entry.isFallback {
            SchemaValidation.push(context, component: component, path: "", issue: .noRoot(root != nil ? .fallback : .missing))
        }

        return ParseResult(
            root: root,
            rootExpression: rootExpression,
            meta: ParseMeta(
                incomplete: wasIncomplete,
                unresolved: context.unresolved,
                // With no entry nothing is reachable; `no-root` alone describes the problem.
                orphaned: entry == nil ? [] : context.orphaned,
                statementCount: statementCount,
                errors: context.errors
            ),
            stateDeclarations: stateDeclarations,
            queryStatements: queries,
            mutationStatements: mutations
        )
    }
}

/// Incremental parser for streaming input (port of `createStreamParser`).
///
/// Completed statements are cached; only the trailing (pending) statement is re-parsed per chunk.
/// Use ``set(_:)`` with the full accumulated text (it diffs and resets automatically when the text
/// is replaced rather than appended), or ``push(_:)`` with deltas.
@available(iOS 17.0, macOS 14.0, *)
public struct OpenUIStreamParser: Sendable {
    public let paramMap: ParamMap
    public let rootName: String?

    private var buffer = ""
    /// Preprocessed view of `buffer` (fences and comments stripped).
    private var cleaned: [UInt8] = []
    /// How far into `cleaned` statements are already completed.
    private var completedEnd = 0
    private var completed = StatementTable()
    private var completedCount = 0

    public init(paramMap: ParamMap, rootName: String? = nil) {
        self.paramMap = paramMap
        self.rootName = rootName
    }

    public init(schema: OpenUIValue, rootName: String? = nil) {
        self.init(paramMap: OpenUIParser.compileSchema(schema), rootName: rootName)
    }

    /// Appends a chunk and returns the latest result. Pass `complete` once the stream has ended.
    public mutating func push(_ chunk: String, complete: Bool = false) -> ParseResult {
        buffer += chunk
        return currentResult(complete: complete)
    }

    /// Sets the full text so far. Resets when the text no longer extends the previous buffer. Pass
    /// `complete` once the stream has ended.
    public mutating func set(_ fullText: String, complete: Bool = false) -> ParseResult {
        if fullText.utf8.count < buffer.utf8.count || !fullText.utf8.starts(with: buffer.utf8) {
            reset()
        }
        if fullText.utf8.count > buffer.utf8.count {
            buffer = fullText
        }
        return currentResult(complete: complete)
    }

    /// The latest result without consuming new data.
    public mutating func result(complete: Bool = false) -> ParseResult {
        currentResult(complete: complete)
    }

    public mutating func reset() {
        buffer = ""
        cleaned = []
        completedEnd = 0
        completed.removeAll()
        completedCount = 0
    }

    private mutating func addStatements(_ text: String) {
        let trimmed = JS.trim(text)
        guard !trimmed.isEmpty else { return }
        for raw in Statements.split(Lexer.tokenize(trimmed)) {
            completed.set(OpenUIParser.classify(raw, ExpressionParser.parse(raw.tokens)))
            completedCount += 1
        }
    }

    private mutating func refreshCleaned() {
        let next = Array(Preprocessor.preprocess(buffer).utf8)
        let stablePrefix = cleaned[0..<min(completedEnd, cleaned.count)]
        if !next.starts(with: stablePrefix) {
            completedEnd = 0
            completed.removeAll()
            completedCount = 0
        }
        cleaned = next
    }

    /// Scans for newly completed statements; returns the start of the pending statement.
    private mutating func scanNewCompleted() -> Int {
        var depth = 0
        var ternaryDepth = 0
        var inString: UInt8?
        var escaped = false
        var statementStart = completedEnd
        let n = cleaned.count
        var i = completedEnd

        while i < n {
            let c = cleaned[i]
            defer { i += 1 }
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
            case UInt8(ascii: "?") where depth == 0:
                ternaryDepth += 1
            case UInt8(ascii: ":") where depth == 0 && ternaryDepth > 0:
                ternaryDepth -= 1
            case 0x0a where depth <= 0 && ternaryDepth <= 0:
                var peek = i + 1
                while peek < n, cleaned[peek] == 0x20 || cleaned[peek] == 0x09 || cleaned[peek] == 0x0d || cleaned[peek] == 0x0a {
                    peek += 1
                }
                if peek < n, cleaned[peek] == UInt8(ascii: "?") || (cleaned[peek] == UInt8(ascii: ":") && ternaryDepth > 0) {
                    continue
                }
                let statementText = String(decoding: cleaned[statementStart..<i], as: UTF8.self)
                addStatements(statementText)
                statementStart = i + 1
                completedEnd = i + 1
            default:
                break
            }
        }
        return statementStart
    }

    private mutating func currentResult(complete: Bool) -> ParseResult {
        refreshCleaned()
        let pendingStart = scanNewCompleted()
        let pendingText = JS.trim(String(decoding: cleaned[min(pendingStart, cleaned.count)...], as: UTF8.self))

        if pendingText.isEmpty {
            if completedCount == 0 { return .empty() }
            return OpenUIParser.buildResult(completed, wasIncomplete: false, statementCount: completedCount, paramMap: paramMap, rootName: rootName)
        }

        let (closed, wasIncomplete) = Statements.autoClose(pendingText)
        let raw = Statements.split(Lexer.tokenize(closed))
        if raw.isEmpty {
            if completedCount == 0 { return .empty(incomplete: wasIncomplete) }
            return OpenUIParser.buildResult(completed, wasIncomplete: wasIncomplete, statementCount: completedCount, paramMap: paramMap, rootName: rootName)
        }

        // New IDs render progressively; existing IDs are only replaced once the pending
        // statement no longer needs automatic closing.
        var all = completed
        var pendingIds = Set<String>()
        for statement in raw {
            if completed.contains(statement.id) && wasIncomplete { continue }
            all.set(OpenUIParser.classify(statement, ExpressionParser.parse(statement.tokens)))
            pendingIds.insert(statement.id)
        }
        let tail = complete ? nil : Self.partialStateName(buffer: buffer, pendingText: pendingText)
        return OpenUIParser.buildResult(
            all,
            wasIncomplete: wasIncomplete,
            statementCount: completedCount + raw.count,
            paramMap: paramMap,
            rootName: rootName,
            partialReference: tail.map { OpenUIParser.PartialReference(name: $0, statementIds: pendingIds) }
        )
    }

    /// A `$name` ending the raw text may still be growing (`$d` of `$dishes`): it isn't declared
    /// unless the same name already appears in full in the pending text.
    static func partialStateName(buffer: String, pendingText: String) -> String? {
        let scalars = Array(buffer.unicodeScalars)
        var start = scalars.count
        while start > 0, isWordCharacter(scalars[start - 1]) { start -= 1 }
        guard start > 0, start < scalars.count, scalars[start - 1] == "$" else { return nil }
        let tail = "$" + String(String.UnicodeScalarView(scalars[start...]))
        guard pendingText.hasSuffix(tail) else { return nil }
        let before = Array(pendingText.unicodeScalars.dropLast(tail.unicodeScalars.count))
        let needle = Array(tail.unicodeScalars)
        var index = 0
        while index + needle.count <= before.count {
            if Array(before[index..<index + needle.count]) == needle {
                let next = index + needle.count
                if next >= before.count || !isWordCharacter(before[next]) { return nil }
            }
            index += 1
        }
        return tail
    }

    private static func isWordCharacter(_ scalar: Unicode.Scalar) -> Bool {
        scalar == "_" || ("a"..."z").contains(scalar) || ("A"..."Z").contains(scalar) || ("0"..."9").contains(scalar)
    }
}
