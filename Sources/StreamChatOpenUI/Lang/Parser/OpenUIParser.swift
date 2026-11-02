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

    /// Compiles a library JSON Schema into positional parameter definitions. Each component lives in
    /// `$defs` (keyed by name); its `properties` order defines the positional argument order.
    public static func compileSchema(_ schema: OpenUIValue) -> ParamMap {
        var map = ParamMap()
        guard case .object(let root) = schema else { return map }
        let definitions: OpenUIObject
        if case .object(let defs)? = root["$defs"] { definitions = defs } else { definitions = [:] }
        var componentNames: Set<String>?
        if case .object(let properties)? = root["properties"] {
            componentNames = Set(properties.keys)
        }

        for (name, definition) in definitions.entries {
            // Skip non-component defs (e.g. zod's hoisted recursive schemas).
            if let componentNames, !componentNames.contains(name) { continue }
            guard case .object(let def) = definition else { continue }
            let properties: OpenUIObject
            if case .object(let props)? = def["properties"] { properties = props } else { properties = [:] }
            var required: [String] = []
            if case .array(let names)? = def["required"] {
                required = names.compactMap(\.stringValue)
            }
            map[name] = properties.entries.map { key, property in
                ParamDef(
                    name: key,
                    required: required.contains(key),
                    defaultValue: SchemaValidation.defaultValue(of: property),
                    schema: property
                )
            }
        }
        return map
    }

    // MARK: - Core pipeline

    static func parse(_ input: String, paramMap: ParamMap?, rootName: String?) -> ParseResult {
        let trimmed = Preprocessor.preprocess(input)
        if trimmed.isEmpty { return .empty() }

        let (text, wasIncomplete) = Statements.autoClose(trimmed)
        let raw = Statements.split(Lexer.tokenize(text))
        if raw.isEmpty { return .empty(incomplete: wasIncomplete) }

        var table = StatementTable()
        var firstId = ""
        for statement in raw {
            table.set(classify(statement, ExpressionParser.parse(statement.tokens)))
            if firstId.isEmpty { firstId = statement.id }
        }
        return buildResult(table, firstId: firstId, wasIncomplete: wasIncomplete, statementCount: table.count, paramMap: paramMap, rootName: rootName)
    }

    /// Classifies a statement from its identifier token and expression shape.
    static func classify(_ raw: RawStatement, _ expression: ASTNode) -> Statement {
        if case .comp(let name, let args, _) = expression {
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

    private static func isComponentStatement(_ statement: Statement) -> String? {
        guard case .value(_, let expression) = statement,
              case .comp(let name, _, _) = expression,
              !Builtins.isBuiltin(name),
              !Builtins.isReservedCall(name) else { return nil }
        return name
    }

    private static func pickEntryId(_ table: StatementTable, firstId: String, rootName: String?) -> String {
        if table.contains("root") { return "root" }
        if let rootName, table.contains(rootName) { return rootName }
        let statements = table.values
        if let rootName, let preferred = statements.first(where: { isComponentStatement($0) == rootName }) {
            return preferred.id
        }
        return statements.first(where: { isComponentStatement($0) != nil })?.id ?? firstId
    }

    static func buildResult(
        _ table: StatementTable,
        firstId: String,
        wasIncomplete: Bool,
        statementCount: Int,
        paramMap: ParamMap?,
        rootName: String?
    ) -> ParseResult {
        let entryId = pickEntryId(table, firstId: firstId, rootName: rootName)
        guard let entry = table[entryId] else { return .empty(incomplete: wasIncomplete) }

        var symbols: [String: ASTNode] = [:]
        var unreached: [String] = []
        for statement in table.values {
            symbols[statement.id] = statement.symbol
            switch statement {
            case .value where statement.id != entryId:
                unreached.append(statement.id)
            default:
                break
            }
        }

        let context = MaterializeContext(
            symbols: symbols,
            catalog: paramMap,
            partial: wasIncomplete,
            currentStatementId: entryId,
            unreached: unreached
        )
        let materialized = Materializer.materializeValue(entry.symbol, context)
        var root: ElementNode?
        if case .element(var element) = materialized {
            element.statementId = entryId
            root = element
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
            case .query(let id, let args, _, let deps):
                queries.append(QueryStatementInfo(
                    statementId: id,
                    toolAST: args.count > 0 ? args[0] : nil,
                    argsAST: args.count > 1 ? args[1] : nil,
                    defaultsAST: args.count > 2 ? args[2] : nil,
                    refreshAST: args.count > 3 ? args[3] : nil,
                    deps: deps,
                    complete: true
                ))
            case .mutation(let id, let args, _):
                mutations.append(MutationStatementInfo(
                    statementId: id,
                    toolAST: args.count > 0 ? args[0] : nil,
                    argsAST: args.count > 1 ? args[1] : nil
                ))
            case .value:
                break
            }
        }

        // Auto-declare: any $variable referenced but not declared gets a null default.
        for statement in statements {
            let nodes: [ASTNode]
            switch statement {
            case .state(_, let initial): nodes = [initial]
            case .value(_, let expression): nodes = [expression]
            case .query(_, let args, _, _), .mutation(_, let args, _): nodes = args
            }
            for node in nodes {
                for dependency in node.stateReferences where !stateDeclarations.contains(dependency) {
                    stateDeclarations[dependency] = .null
                }
            }
        }

        return ParseResult(
            root: root,
            meta: ParseMeta(
                incomplete: wasIncomplete,
                unresolved: context.unresolved,
                orphaned: context.orphaned,
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
    private var firstId = ""

    public init(paramMap: ParamMap, rootName: String? = nil) {
        self.paramMap = paramMap
        self.rootName = rootName
    }

    public init(schema: OpenUIValue, rootName: String? = nil) {
        self.init(paramMap: OpenUIParser.compileSchema(schema), rootName: rootName)
    }

    /// Appends a chunk and returns the latest result.
    public mutating func push(_ chunk: String) -> ParseResult {
        buffer += chunk
        return currentResult()
    }

    /// Sets the full text so far. Resets when the text no longer extends the previous buffer.
    public mutating func set(_ fullText: String) -> ParseResult {
        if fullText.utf8.count < buffer.utf8.count || !fullText.utf8.starts(with: buffer.utf8) {
            reset()
        }
        if fullText.utf8.count > buffer.utf8.count {
            buffer = fullText
        }
        return currentResult()
    }

    /// The latest result without consuming new data.
    public mutating func result() -> ParseResult {
        currentResult()
    }

    public mutating func reset() {
        buffer = ""
        cleaned = []
        completedEnd = 0
        completed.removeAll()
        completedCount = 0
        firstId = ""
    }

    private mutating func addStatements(_ text: String) {
        let trimmed = JS.trim(text)
        guard !trimmed.isEmpty else { return }
        for raw in Statements.split(Lexer.tokenize(trimmed)) {
            completed.set(OpenUIParser.classify(raw, ExpressionParser.parse(raw.tokens)))
            completedCount += 1
            if firstId.isEmpty { firstId = raw.id }
        }
    }

    private mutating func refreshCleaned() {
        let next = Array(Preprocessor.preprocess(buffer).utf8)
        let stablePrefix = cleaned[0..<min(completedEnd, cleaned.count)]
        if !next.starts(with: stablePrefix) {
            completedEnd = 0
            completed.removeAll()
            completedCount = 0
            firstId = ""
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

    private mutating func currentResult() -> ParseResult {
        refreshCleaned()
        let pendingStart = scanNewCompleted()
        let pendingText = JS.trim(String(decoding: cleaned[min(pendingStart, cleaned.count)...], as: UTF8.self))

        if pendingText.isEmpty {
            if completedCount == 0 { return .empty() }
            return OpenUIParser.buildResult(completed, firstId: firstId, wasIncomplete: false, statementCount: completedCount, paramMap: paramMap, rootName: rootName)
        }

        let (closed, wasIncomplete) = Statements.autoClose(pendingText)
        let raw = Statements.split(Lexer.tokenize(closed))
        if raw.isEmpty {
            if completedCount == 0 { return .empty(incomplete: wasIncomplete) }
            return OpenUIParser.buildResult(completed, firstId: firstId, wasIncomplete: wasIncomplete, statementCount: completedCount, paramMap: paramMap, rootName: rootName)
        }

        // New IDs render progressively; existing IDs are only replaced once the pending
        // statement no longer needs automatic closing.
        var all = completed
        for statement in raw {
            if completed.contains(statement.id) && wasIncomplete { continue }
            all.set(OpenUIParser.classify(statement, ExpressionParser.parse(statement.tokens)))
        }
        let entryFallback = firstId.isEmpty ? raw[0].id : firstId
        return OpenUIParser.buildResult(all, firstId: entryFallback, wasIncomplete: wasIncomplete, statementCount: completedCount + raw.count, paramMap: paramMap, rootName: rootName)
    }
}
