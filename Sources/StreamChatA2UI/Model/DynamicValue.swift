//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A component property value as it arrives on the wire.
///
/// A2UI properties declared as `DynamicString`, `DynamicNumber`,
/// `DynamicBoolean`, `DynamicStringList` or `DynamicValue` accept one of three
/// shapes: a literal, a data binding (`{"@path": "/a/b"}`) or a function call
/// (`{"@call": "formatString", "args": {...}}`).
@available(iOS 15.0, macOS 12.0, *)
enum DynamicValue: Equatable, Sendable {
    /// A literal JSON value.
    case literal(any Sendable)

    /// A data binding to a possibly relative path.
    case binding(DataPath)

    /// A function call evaluated by the renderer or routed to the agent.
    case function(FunctionCall)

    /// The property was absent.
    case missing

    /// Classifies a raw JSON value into a dynamic value.
    ///
    /// Objects are bindings or calls only when they carry `@path` or `@call`.
    /// Other objects are literals, with `@@`-escaped keys unescaped. Objects
    /// that misuse the reserved `@` prefix are treated as missing.
    init(_ raw: (any Sendable)?) {
        guard let raw = Json.normalized(raw) else {
            self = .missing
            return
        }
        guard let map = raw as? JsonMap else {
            self = .literal(raw)
            return
        }
        if map[A2UIProtocol.callKey] != nil {
            if let call = FunctionCall(map) {
                self = .function(call)
            } else {
                self = .missing
            }
            return
        }
        if map[A2UIProtocol.pathKey] != nil {
            if map.count == 1, let path = map[A2UIProtocol.pathKey] as? String {
                self = .binding(DataPath(path))
            } else {
                self = .missing
            }
            return
        }
        guard let literal = Self.unescapedLiteral(map) else {
            self = .missing
            return
        }
        self = .literal(literal)
    }

    /// Returns a plain object with its `@@`-escaped keys unescaped.
    ///
    /// Returns `nil` when a key uses the reserved single `@` prefix, which only
    /// `@path` and `@call` may use.
    static func unescapedLiteral(_ map: JsonMap) -> JsonMap? {
        var literal: JsonMap = [:]
        for (key, value) in map {
            if key.hasPrefix("@@") {
                literal[String(key.dropFirst())] = value
            } else if key.hasPrefix("@") {
                return nil
            } else {
                literal[key] = value
            }
        }
        return literal
    }

    /// Describes how a raw value misuses the reserved `@` prefix, if it does.
    ///
    /// Nested arrays and objects are checked too, because function arguments
    /// and action contexts are dynamic values themselves.
    static func reservedKeyViolation(in raw: (any Sendable)?) -> String? {
        if let array = Json.array(raw) {
            return array.lazy.compactMap { reservedKeyViolation(in: $0) }.first
        }
        guard let map = Json.map(raw) else { return nil }
        if map[A2UIProtocol.pathKey] != nil {
            guard let path = map[A2UIProtocol.pathKey] as? String else { return "'@path' must be a string." }
            guard map.count == 1 else { return "A '@path' binding cannot carry other keys." }
            guard DataPath.isValidSyntax(path) else { return "Invalid path syntax: '\(path)'." }
            return nil
        }
        if map[A2UIProtocol.callKey] != nil {
            guard let name = map[A2UIProtocol.callKey] as? String else { return "'@call' must be a string." }
            if name.hasPrefix(A2UIProtocol.systemFunctionPrefix) {
                guard name == "@index" else { return "Unknown system function '\(name)'." }
            } else if !A2UIIdentifier.isValid(name) {
                return "The function name '\(name)' must be a valid UAX #31 identifier."
            }
            if let args = map["args"], Json.map(args) == nil { return "'args' must be an object." }
            return Json.map(map["args"]).flatMap { args in
                args.values.lazy.compactMap { reservedKeyViolation(in: $0) }.first
            }
        }
        for (key, value) in map {
            if key.hasPrefix("@"), !key.hasPrefix("@@") {
                return "The key '\(key)' uses the reserved '@' prefix; escape a literal '@' as '@@'."
            }
            if let violation = reservedKeyViolation(in: value) {
                return violation
            }
        }
        return nil
    }

    // Every `@call` in a value, with the JSON pointer to it from the value.
    static func calls(in raw: (any Sendable)?, at pointer: String = "") -> [(pointer: String, call: JsonMap)] {
        if let array = Json.array(raw) {
            return array.enumerated().flatMap { calls(in: $1, at: "\(pointer)/\($0)") }
        }
        guard let map = Json.map(raw), map[A2UIProtocol.pathKey] == nil else { return [] }
        let own = map[A2UIProtocol.callKey] != nil ? [(pointer, map)] : []
        return own + map.keys.sorted().flatMap { key in
            calls(in: map[key], at: "\(pointer)/" + key.replacingOccurrences(of: "~", with: "~0").replacingOccurrences(of: "/", with: "~1"))
        }
    }

    // How deeply `@call`s nest in a value, through their arguments.
    static func callDepth(of raw: (any Sendable)?) -> Int {
        if let array = Json.array(raw) {
            return array.map(callDepth(of:)).max() ?? 0
        }
        guard let map = Json.map(raw) else { return 0 }
        let nested = map.values.map(callDepth(of:)).max() ?? 0
        return map[A2UIProtocol.callKey] != nil ? nested + 1 : nested
    }

    // A literal `formatString` template that does not parse, with the JSON pointer to it from the value.
    static func formatStringViolation(in raw: (any Sendable)?, at pointer: String = "") -> (pointer: String, message: String)? {
        if let array = Json.array(raw) {
            for (index, item) in array.enumerated() {
                if let violation = formatStringViolation(in: item, at: "\(pointer)/\(index)") { return violation }
            }
            return nil
        }
        guard let map = Json.map(raw), map[A2UIProtocol.pathKey] == nil else { return nil }
        if map[A2UIProtocol.callKey] as? String == "formatString",
           let template = Json.map(map["args"])?["value"] as? String {
            do {
                _ = try A2UIExpressionParser.parseTemplate(template)
            } catch {
                return ("\(pointer)/args/value", A2UIErrorFormatter.describe(error))
            }
        }
        for (key, value) in map.sorted(by: { $0.key < $1.key }) {
            let escaped = key.replacingOccurrences(of: "~", with: "~0").replacingOccurrences(of: "/", with: "~1")
            if let violation = formatStringViolation(in: value, at: "\(pointer)/\(escaped)") { return violation }
        }
        return nil
    }

    /// Whether the property was absent on the wire.
    var isMissing: Bool {
        if case .missing = self { return true }
        return false
    }

    /// The binding path, when this value is a data binding.
    var bindingPath: DataPath? {
        if case let .binding(path) = self { return path }
        return nil
    }

    /// The literal value, when this value is a literal.
    var literalValue: (any Sendable)? {
        if case let .literal(value) = self { return value }
        return nil
    }

    /// The wire representation of this value.
    /// Round-trips a decoded property back to JSON.
    var rawValue: (any Sendable)? {
        switch self {
        case let .literal(value): return value
        case let .binding(path): return [A2UIProtocol.pathKey: path.description]
        case let .function(call): return call.rawValue
        case .missing: return nil
        }
    }

    /// Compares two dynamic values structurally.
    /// Literals are compared as JSON.
    static func == (lhs: DynamicValue, rhs: DynamicValue) -> Bool {
        switch (lhs, rhs) {
        case (.missing, .missing):
            return true
        case let (.binding(left), .binding(right)):
            return left == right
        case let (.function(left), .function(right)):
            return left == right
        case let (.literal(left), .literal(right)):
            return Json.isEqual(left, right)
        default:
            return false
        }
    }
}

/// A named function invocation embedded in a component tree.
///
/// Functions are resolved against the catalog identified by `catalogId`, or the
/// surface default catalog when the call does not declare one. Names starting
/// with `@` are universal system functions.
@available(iOS 15.0, macOS 12.0, *)
struct FunctionCall: Equatable, Sendable {
    /// The name of the function to call.
    let name: String

    /// The catalog that defines the function, when explicitly declared.
    let catalogId: String?

    /// The raw, unevaluated arguments of the call.
    let arguments: JsonMap

    /// Creates a function call.
    /// Arguments stay unevaluated so that nested bindings resolve lazily.
    init(name: String, catalogId: String? = nil, arguments: JsonMap = [:]) {
        self.name = name
        self.catalogId = catalogId
        self.arguments = arguments
    }

    /// Parses a function call from a JSON object.
    /// Returns `nil` when the object does not carry an `@call` property.
    init?(_ json: JsonMap) {
        guard let name = json[A2UIProtocol.callKey] as? String, !name.isEmpty else { return nil }
        self.name = name
        self.catalogId = json["catalogId"] as? String
        self.arguments = Json.map(json["args"]) ?? [:]
    }

    /// Whether this is a universal system function such as `@index`.
    var isSystemFunction: Bool {
        name.hasPrefix(A2UIProtocol.systemFunctionPrefix)
    }

    /// The wire representation of the call.
    var rawValue: JsonMap {
        var json: JsonMap = [A2UIProtocol.callKey: name]
        if let catalogId { json["catalogId"] = catalogId }
        if !arguments.isEmpty { json["args"] = arguments }
        return json
    }

    /// Compares two calls by name, catalog and arguments.
    static func == (lhs: FunctionCall, rhs: FunctionCall) -> Bool {
        lhs.name == rhs.name
            && lhs.catalogId == rhs.catalogId
            && Json.isEqual(lhs.arguments, rhs.arguments)
    }
}

/// The children of a container component.
///
/// A2UI containers either list their children explicitly or declare a template
/// that is instantiated once per item of a bound collection.
@available(iOS 15.0, macOS 12.0, *)
enum ChildList: Equatable, Sendable {
    /// A static list of component ids.
    case ids([String])

    /// A template instantiated for every item at `path`.
    case template(componentId: String, path: DataPath)

    /// No children were declared.
    case none

    /// Parses a child list from a raw property value.
    /// Accepts both the array and template object forms.
    init(_ raw: (any Sendable)?) {
        guard let raw = Json.normalized(raw) else {
            self = .none
            return
        }
        if let ids = Json.stringArray(raw) {
            self = .ids(ids)
            return
        }
        if let map = raw as? JsonMap,
           let componentId = map["componentId"] as? String,
           let path = map["path"] as? String {
            self = .template(componentId: componentId, path: DataPath(path))
            return
        }
        self = .none
    }

    /// The statically declared child ids, if any.
    var staticIds: [String] {
        if case let .ids(ids) = self { return ids }
        return []
    }
}

/// The interaction handler of an interactive component.
///
/// An action either dispatches a named event to the agent or executes a
/// function locally on the renderer.
@available(iOS 15.0, macOS 12.0, *)
enum ActionDefinition: Equatable, Sendable {
    /// Dispatches an event to the agent.
    case event(EventAction)

    /// Executes a function call.
    case functionCall(FunctionCall)

    /// Parses an action from a raw property value.
    /// Returns `nil` when neither `event` nor `functionCall` is present.
    init?(_ raw: (any Sendable)?) {
        guard let map = Json.map(raw) else { return nil }
        if let event = Json.map(map["event"]), let action = EventAction(event) {
            self = .event(action)
            return
        }
        if let call = Json.map(map["functionCall"]), let function = FunctionCall(call) {
            self = .functionCall(function)
            return
        }
        return nil
    }
}

/// An agent-bound event dispatched by a component.
@available(iOS 15.0, macOS 12.0, *)
struct EventAction: Equatable, Sendable {
    /// The event name reported to the agent.
    let name: String

    /// An optional human-readable description of what the user did.
    let userMessage: DynamicValue

    /// Context values sent with the event, keyed by name.
    let context: [String: DynamicValue]

    /// Creates an event action.
    /// Context values may be literals, bindings or function calls.
    init(name: String, userMessage: DynamicValue = .missing, context: [String: DynamicValue] = [:]) {
        self.name = name
        self.userMessage = userMessage
        self.context = context
    }

    /// Parses an event action from a JSON object.
    /// Returns `nil` when the required `name` is missing.
    init?(_ json: JsonMap) {
        guard let name = json["name"] as? String else { return nil }
        self.name = name
        self.userMessage = DynamicValue(json["userMessage"])
        self.context = (Json.map(json["context"]) ?? [:]).mapValues { DynamicValue($0) }
    }
}

/// A single renderer-side validation rule.
@available(iOS 15.0, macOS 12.0, *)
struct CheckRule: Equatable, Sendable {
    /// A binding or function call evaluating to a ``ValidationResult``.
    let condition: DynamicValue

    /// A fallback message shown when the condition fails without one.
    let message: String?

    /// Creates a check rule.
    /// The condition is evaluated whenever the component renders.
    init(condition: DynamicValue, message: String? = nil) {
        self.condition = condition
        self.message = message
    }

    /// Parses a check rule from a JSON object.
    /// Returns `nil` when the condition is missing.
    init?(_ json: JsonMap) {
        let condition = DynamicValue(json["condition"])
        guard !condition.isMissing else { return nil }
        self.condition = condition
        self.message = json["message"] as? String
    }

    /// Parses a list of check rules from a raw property value.
    /// Invalid entries are skipped.
    static func list(_ raw: (any Sendable)?) -> [CheckRule] {
        (Json.array(raw) ?? []).compactMap { entry in
            guard let map = Json.map(entry) else { return nil }
            return CheckRule(map)
        }
    }
}

/// The outcome of a renderer-side validation rule.
@available(iOS 15.0, macOS 12.0, *)
struct ValidationResult: Equatable, Sendable {
    /// How serious a failed check is.
    enum Severity: String, Sendable {
        case error
        case warning
        case info
    }

    /// Whether the check passed.
    let isValid: Bool

    /// An optional machine-readable failure code.
    let code: String?

    /// An optional human-readable message.
    let message: String?

    /// How serious the failure is.
    let severity: Severity

    /// Creates a validation result.
    /// Failures should carry a message so the UI can explain them.
    init(isValid: Bool, code: String? = nil, message: String? = nil, severity: Severity = .error) {
        self.isValid = isValid
        self.code = code
        self.message = message
        self.severity = severity
    }

    /// A passing result.
    static let valid = ValidationResult(isValid: true)

    /// Creates a failing result with a message.
    /// Use this from validation function implementations.
    static func invalid(_ message: String, code: String? = nil) -> ValidationResult {
        ValidationResult(isValid: false, code: code, message: message)
    }

    /// Coerces an evaluated value into a validation result.
    ///
    /// Booleans are treated as pass/fail so that logical functions such as
    /// `and` can be used directly as check conditions, and `nil` (a pending or
    /// unresolved value) is treated as passing so progressive rendering does
    /// not block the user.
    init(coercing value: (any Sendable)?) {
        guard let value = Json.normalized(value) else {
            self = .valid
            return
        }
        if let map = value as? JsonMap, let isValid = Json.bool(map["valid"]) {
            self = ValidationResult(
                isValid: isValid,
                code: map["code"] as? String,
                message: map["message"] as? String,
                severity: Severity(rawValue: Json.string(map["severity"]) ?? "") ?? .error
            )
            return
        }
        self = ValidationResult(isValid: Json.bool(value) ?? true)
    }

    /// The wire representation of the result.
    var rawValue: JsonMap {
        var json: JsonMap = ["valid": isValid]
        if let code { json["code"] = code }
        if let message { json["message"] = message }
        json["severity"] = severity.rawValue
        return json
    }
}

/// Accessibility metadata attached to any component.
///
/// These values are mapped onto the platform accessibility APIs and override
/// the semantics inferred from the component's visible content.
@available(iOS 15.0, macOS 12.0, *)
struct AccessibilityAttributes: Equatable, Sendable {
    /// How dynamic updates should be announced.
    enum Live: String, Sendable {
        case off
        case polite
        case assertive
    }

    /// A short label describing the element's purpose.
    let label: DynamicValue

    /// Additional instructions or result information.
    let description: DynamicValue

    /// How updates to this element are announced.
    let live: Live

    /// Whether the element is hidden from assistive technologies.
    let hidden: DynamicValue

    /// Creates accessibility attributes.
    /// All values are optional and may be data bound.
    init(
        label: DynamicValue = .missing,
        description: DynamicValue = .missing,
        live: Live = .off,
        hidden: DynamicValue = .missing
    ) {
        self.label = label
        self.description = description
        self.live = live
        self.hidden = hidden
    }

    /// Parses accessibility attributes from a JSON object.
    /// Returns `nil` when no attributes are present.
    init?(_ raw: (any Sendable)?) {
        guard let json = Json.map(raw), !json.isEmpty else { return nil }
        self.init(
            label: DynamicValue(json["label"]),
            description: DynamicValue(json["description"]),
            live: Live(rawValue: Json.string(json["live"]) ?? "") ?? .off,
            hidden: DynamicValue(json["hidden"])
        )
    }

    /// The wire representation of the attributes.
    var rawValue: JsonMap {
        var json: JsonMap = [:]
        if let label = label.rawValue { json["label"] = label }
        if let description = description.rawValue { json["description"] = description }
        if live != .off { json["live"] = live.rawValue }
        if let hidden = hidden.rawValue { json["hidden"] = hidden }
        return json
    }
}
