//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A resolved component invocation produced by the parser.
///
/// Positional arguments are mapped to named ``props`` using the order of the component's schema.
/// During streaming, ``partial`` is `true` while the parser is still receiving tokens.
@available(iOS 17.0, macOS 14.0, *)
public struct ElementNode: Sendable, Hashable {
    /// Component name as defined in the library (e.g. `"Card"`, `"BarChart"`).
    public var typeName: String
    /// Named props produced by positional-to-named mapping.
    public var props: OpenUIObject
    /// True while the parser hasn't received all tokens for this node yet.
    public var partial: Bool
    /// `false` when every prop is a static literal (evaluation can be skipped). `nil` means unknown.
    public var hasDynamicProps: Bool?
    /// Source statement name (e.g. `"header"` for `header = CardHeader(...)`). `nil` for inline components.
    public var statementId: String?

    public init(
        typeName: String,
        props: OpenUIObject = [:],
        partial: Bool = false,
        hasDynamicProps: Bool? = nil,
        statementId: String? = nil
    ) {
        self.typeName = typeName
        self.props = props
        self.partial = partial
        self.hasDynamicProps = hasDynamicProps
        self.statementId = statementId
    }

    /// JavaScript property access on the element object (`element.props`, `element.typeName`, ...).
    func property(_ key: String) -> OpenUIValue? {
        switch key {
        case "type": return .string("element")
        case "typeName": return .string(typeName)
        case "props": return .object(props)
        case "partial": return .bool(partial)
        case "hasDynamicProps": return hasDynamicProps.map(OpenUIValue.bool)
        case "statementId": return statementId.map(OpenUIValue.string)
        default: return nil
        }
    }

    /// The JSON shape used by the reference implementation.
    public var jsonValue: OpenUIValue {
        var object: OpenUIObject = [
            "type": "element",
            "typeName": .string(typeName),
            "props": .object(props.mapValues(\.plainJSON)),
            "partial": .bool(partial)
        ]
        if let hasDynamicProps { object["hasDynamicProps"] = .bool(hasDynamicProps) }
        if let statementId { object["statementId"] = .string(statementId) }
        return .object(object)
    }
}

/// Machine-readable validation error codes.
@available(iOS 17.0, macOS 14.0, *)
public enum ValidationErrorCode: String, Sendable, Hashable {
    case missingRequired = "missing-required"
    case nullRequired = "null-required"
    case unknownComponent = "unknown-component"
    case inlineReserved = "inline-reserved"
    case excessArgs = "excess-args"
    case typeMismatch = "type-mismatch"
}

/// A prop validation error. Components with unsalvageable props are dropped from the tree.
@available(iOS 17.0, macOS 14.0, *)
public struct ValidationError: Sendable, Hashable, CustomStringConvertible {
    public var code: ValidationErrorCode
    /// Component type name, e.g. `"Header"`.
    public var component: String
    /// JSON Pointer path within the props object, e.g. `"/title"` or `""`.
    public var path: String
    /// Human (and LLM) readable message.
    public var message: String
    /// Statement that triggered the error.
    public var statementId: String?

    public var description: String { message }
}

/// Parser metadata.
@available(iOS 17.0, macOS 14.0, *)
public struct ParseMeta: Sendable, Hashable {
    /// True if the parser detected truncated/incomplete input (streaming in progress).
    public var incomplete: Bool
    /// References used but not (yet) defined.
    public var unresolved: [String]
    /// Value statements that are defined but not reachable from the root.
    public var orphaned: [String]
    /// Number of `identifier = Expression` statements parsed.
    public var statementCount: Int
    /// Prop validation errors.
    public var errors: [ValidationError]

    public init(incomplete: Bool, unresolved: [String] = [], orphaned: [String] = [], statementCount: Int = 0, errors: [ValidationError] = []) {
        self.incomplete = incomplete
        self.unresolved = unresolved
        self.orphaned = orphaned
        self.statementCount = statementCount
        self.errors = errors
    }
}

/// Extracted `Query(...)` declaration.
@available(iOS 17.0, macOS 14.0, *)
public struct QueryStatementInfo: Sendable, Hashable {
    public var statementId: String
    /// Tool name expression (first argument).
    public var toolAST: ASTNode?
    /// Arguments object expression (second argument; may reference `$variables`).
    public var argsAST: ASTNode?
    /// Default data rendered before the fetch resolves (third argument).
    public var defaultsAST: ASTNode?
    /// Refresh interval in seconds (fourth argument).
    public var refreshAST: ASTNode?
    /// `$variables` referenced by the arguments, computed at parse time.
    public var deps: [String]?
    /// False while the declaration is still streaming.
    public var complete: Bool
}

/// Extracted `Mutation(...)` declaration.
@available(iOS 17.0, macOS 14.0, *)
public struct MutationStatementInfo: Sendable, Hashable {
    public var statementId: String
    /// Tool name expression (first argument).
    public var toolAST: ASTNode?
    /// Arguments object expression (second argument), evaluated when the mutation runs.
    public var argsAST: ASTNode?
}

/// The output of parsing an OpenUI Lang program.
@available(iOS 17.0, macOS 14.0, *)
public struct ParseResult: Sendable, Hashable {
    /// The root element, or `nil` if nothing can be rendered yet.
    public var root: ElementNode?
    public var meta: ParseMeta
    /// `$variable` declarations mapped to their default values (in declaration order).
    public var stateDeclarations: OpenUIObject
    public var queryStatements: [QueryStatementInfo]
    public var mutationStatements: [MutationStatementInfo]

    static func empty(incomplete: Bool = true) -> ParseResult {
        ParseResult(
            root: nil,
            meta: ParseMeta(incomplete: incomplete),
            stateDeclarations: [:],
            queryStatements: [],
            mutationStatements: []
        )
    }

    /// The JSON shape produced by the reference implementation (useful for debugging and tooling).
    public var jsonValue: OpenUIValue {
        func ast(_ node: ASTNode?) -> OpenUIValue { node?.jsonValue ?? .null }

        let errors: [OpenUIValue] = meta.errors.map { error in
            var object: OpenUIObject = [
                "code": .string(error.code.rawValue),
                "component": .string(error.component),
                "path": .string(error.path),
                "message": .string(error.message)
            ]
            if let statementId = error.statementId { object["statementId"] = .string(statementId) }
            return .object(object)
        }
        let queries: [OpenUIValue] = queryStatements.map { query in
            var object: OpenUIObject = [
                "statementId": .string(query.statementId),
                "toolAST": ast(query.toolAST),
                "argsAST": ast(query.argsAST),
                "defaultsAST": ast(query.defaultsAST),
                "refreshAST": ast(query.refreshAST)
            ]
            if let deps = query.deps { object["deps"] = .array(deps.map(OpenUIValue.string)) }
            object["complete"] = .bool(query.complete)
            return .object(object)
        }
        let mutations: [OpenUIValue] = mutationStatements.map { mutation in
            [
                "statementId": .string(mutation.statementId),
                "toolAST": ast(mutation.toolAST),
                "argsAST": ast(mutation.argsAST)
            ]
        }
        return [
            "root": root?.jsonValue ?? .null,
            "meta": [
                "incomplete": .bool(meta.incomplete),
                "unresolved": .array(meta.unresolved.map(OpenUIValue.string)),
                "orphaned": .array(meta.orphaned.map(OpenUIValue.string)),
                "statementCount": .number(Double(meta.statementCount)),
                "errors": .array(errors)
            ],
            "stateDeclarations": .object(stateDeclarations.mapValues(\.plainJSON)),
            "queryStatements": .array(queries),
            "mutationStatements": .array(mutations)
        ]
    }
}

/// A positional parameter of a component, compiled from the library's JSON Schema.
@available(iOS 17.0, macOS 14.0, *)
public struct ParamDef: Sendable, Hashable {
    public var name: String
    public var required: Bool
    /// Schema `default`, used when a required value is missing, `null` or invalid.
    public var defaultValue: OpenUIValue?
    /// The JSON Schema fragment describing the parameter.
    public var schema: OpenUIValue?

    public init(name: String, required: Bool, defaultValue: OpenUIValue? = nil, schema: OpenUIValue? = nil) {
        self.name = name
        self.required = required
        self.defaultValue = defaultValue
        self.schema = schema
    }
}

/// Component name → ordered parameters, preserving library order.
@available(iOS 17.0, macOS 14.0, *)
public struct ParamMap: Sendable, Hashable {
    public private(set) var componentNames: [String] = []
    private var params: [String: [ParamDef]] = [:]

    public init() {}

    public init(_ entries: [(String, [ParamDef])]) {
        for (name, params) in entries {
            self[name] = params
        }
    }

    public subscript(name: String) -> [ParamDef]? {
        get { params[name] }
        set {
            if let newValue {
                if params.updateValue(newValue, forKey: name) == nil {
                    componentNames.append(name)
                }
            } else if params.removeValue(forKey: name) != nil {
                componentNames.removeAll { $0 == name }
            }
        }
    }

    public func contains(_ name: String) -> Bool {
        params[name] != nil
    }
}
