//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Mutable state shared across one materialization pass (mirrors `MaterializeCtx`).
@available(iOS 17.0, macOS 14.0, *)
final class MaterializeContext {
    var symbols: [String: ASTNode]
    let catalog: ParamMap?
    var errors: [ValidationError] = []
    var unresolved: [String] = []
    var visited: Set<String> = []
    var depth = 0
    var nodes = 0
    let partial: Bool
    var currentStatementId: String?
    // Kept by the stream parser, with the logs below, to reuse what statements materialized to.
    var cache: MaterializationCache?
    var reads: [MaterializationCache.Read] = []
    var reachedLog: [String] = []
    var cycles = 0
    var truncations = 0
    var deepest = 0
    var materialized = 0
    /// Statement IDs not reached yet (insertion ordered). Whatever remains is orphaned.
    private(set) var unreachedOrder: [String] = []
    private var unreached: Set<String> = []
    private let tracksUnreached: Bool

    init(symbols: [String: ASTNode], catalog: ParamMap?, partial: Bool, currentStatementId: String?, unreached: [String]?) {
        self.symbols = symbols
        self.catalog = catalog
        self.partial = partial
        self.currentStatementId = currentStatementId
        if let unreached {
            tracksUnreached = true
            unreachedOrder = unreached
            self.unreached = Set(unreached)
        } else {
            tracksUnreached = false
        }
    }

    func markReached(_ id: String) {
        if cache != nil { reachedLog.append(id) }
        guard tracksUnreached else { return }
        unreached.remove(id)
    }

    // Counts a node against the budget, or returns false when it is past the depth or the budget.
    func spendNode() -> Bool {
        nodes += 1
        materialized += 1
        deepest = max(deepest, depth)
        guard depth <= Materializer.maxDepth, nodes <= Materializer.maxNodes else {
            truncations += 1
            return false
        }
        return true
    }

    var orphaned: [String] {
        unreachedOrder.filter { unreached.contains($0) }
    }
}

/// A structured validation issue; message templates live in ``SchemaValidation/message(component:path:issue:)``.
@available(iOS 17.0, macOS 14.0, *)
enum ValidationIssue {
    case typeMismatch(expected: String, actual: String)
    case missingRequired(signature: String?)
    case nullRequired(signature: String?)
    case unknownComponent(available: [String]?)
    case inlineReserved
    case excessArgs(declared: Int, got: Int)
    case unknownFunction
    case noRoot(NoRootReason)

    enum NoRootReason {
        case missing
        case notComponent
        case fallback
    }

    var code: ValidationErrorCode {
        switch self {
        case .typeMismatch: return .typeMismatch
        case .missingRequired: return .missingRequired
        case .nullRequired: return .nullRequired
        case .unknownComponent: return .unknownComponent
        case .inlineReserved: return .inlineReserved
        case .excessArgs: return .excessArgs
        case .unknownFunction: return .unknownFunction
        case .noRoot: return .noRoot
        }
    }

    var isWarning: Bool {
        if case .noRoot(.fallback) = self { return true }
        return false
    }
}

/// Recursive schema validation of materialized props (port of `validation.ts`).
@available(iOS 17.0, macOS 14.0, *)
enum SchemaValidation {
    // MARK: - Schema introspection

    private static func refName(_ schema: OpenUIObject) -> String? {
        guard case .string(let ref)? = schema["$ref"] else { return nil }
        return ref.split(separator: "/", omittingEmptySubsequences: false).last.map(String.init)
    }

    private static func isCompositeSchema(_ schema: OpenUIObject) -> Bool {
        schema.contains("$ref") || schema.contains("anyOf") || schema.contains("oneOf") || schema.contains("allOf")
    }

    /// Scalar type/enum info extracted from a JSON Schema leaf.
    struct ScalarTypeInfo {
        var expectedType: String?
        var enumValues: [OpenUIValue]?
    }

    static func scalarTypeInfo(_ schema: OpenUIObject) -> ScalarTypeInfo {
        if case .array(let values)? = schema["enum"] { return ScalarTypeInfo(enumValues: values) }
        if let constant = schema["const"] { return ScalarTypeInfo(enumValues: [constant]) }
        switch schema["type"] {
        case .string("string")?: return ScalarTypeInfo(expectedType: "string")
        case .string("number")?, .string("integer")?: return ScalarTypeInfo(expectedType: "number")
        case .string("boolean")?: return ScalarTypeInfo(expectedType: "boolean")
        default: return ScalarTypeInfo()
        }
    }

    /// The `default` of a JSON Schema fragment, if it has one.
    static func defaultValue(of property: OpenUIValue?) -> OpenUIValue? {
        guard case .object(let object)? = property else { return nil }
        return object["default"]
    }

    /// Human readable type for a parameter schema (used in signatures and hints).
    static func typeDescription(of property: OpenUIValue?) -> String? {
        guard case .object(let schema)? = property else { return nil }
        if let ref = refName(schema) { return ref }
        let leaf = scalarTypeInfo(schema)
        if let enumValues = leaf.enumValues {
            return enumValues.map { JS.jsonStringify($0) ?? "undefined" }.joined(separator: "|")
        }
        if let expectedType = leaf.expectedType { return expectedType }
        if case .string(let type)? = schema["type"] { return type }
        return nil
    }

    /// `Header(title*: string, variant: "a"|"b")` — `*` marks required params.
    static func paramsSignature(component: String, params: [ParamDef]) -> String {
        let rendered = params.map { param -> String in
            let marked = param.required ? "\(param.name)*" : param.name
            if let type = typeDescription(of: param.schema) {
                return "\(marked): \(type)"
            }
            return marked
        }
        return "\(component)(\(rendered.joined(separator: ", ")))"
    }

    private static func typeMismatch(_ value: OpenUIValue, _ info: ScalarTypeInfo) -> (expected: String, actual: String)? {
        let actual = JS.typeOf(value)
        if let enumValues = info.enumValues {
            guard ["string", "number", "boolean"].contains(actual) else { return nil }
            if enumValues.contains(where: { JS.sameValueZero($0, value) }) { return nil }
            let expected = "one of [" + enumValues.map { JS.jsonStringify($0) ?? "undefined" }.joined(separator: ", ") + "]"
            return (expected, JS.jsonStringify(value) ?? "undefined")
        }
        if let expectedType = info.expectedType, expectedType != actual {
            return (expectedType, JS.jsType(value))
        }
        return nil
    }

    // MARK: - Errors

    static func message(component: String, path: String, issue: ValidationIssue) -> String {
        switch issue {
        case .typeMismatch(let expected, let actual):
            return "field \"\(path)\" expects \(expected) but got \(actual)"
        case .missingRequired(let signature):
            return "missing required field \"\(path)\"" + (signature.map { " — signature: \($0)" } ?? "")
        case .nullRequired(let signature):
            return "required field \"\(path)\" cannot be null" + (signature.map { " — signature: \($0)" } ?? "")
        case .unknownComponent(let available):
            var message = "Unknown component \"\(component)\" — not found in catalog or builtins"
            if let available, !available.isEmpty {
                message += ". Available components: " + available.joined(separator: ", ")
            }
            return message
        case .inlineReserved:
            return "\(component)() must be declared as a top-level statement, not used inline as a value"
        case .excessArgs(let declared, let got):
            return "\(component) takes \(declared) arg(s), got \(got) (\(got - declared) excess dropped)"
        case .unknownFunction:
            return "Unknown function \"@\(component)\": not a built-in or action step. The call evaluates to null"
        case .noRoot(.notComponent):
            return "root does not evaluate to a component"
        case .noRoot(.fallback):
            return "No root statement. Rendering the first statement that calls the root component \(component)"
        case .noRoot(.missing):
            return component.isEmpty
                ? "No root statement"
                : "No root statement, and no statement calls the root component \(component)"
        }
    }

    static func push(_ context: MaterializeContext, component: String, path: String, issue: ValidationIssue) {
        context.errors.append(ValidationError(
            code: issue.code,
            component: component,
            path: path,
            message: message(component: component, path: path, issue: issue),
            statementId: context.currentStatementId,
            isWarning: issue.isWarning
        ))
    }

    // MARK: - Edge rule

    /// Substitutes the default if there is one; otherwise propagates upwards for required keys and
    /// prunes optional ones. Returns `true` when the invalidity must propagate to the parent.
    static func resolveInvalidValue(_ container: inout OpenUIObject, key: String, required: Bool, defaultValue: OpenUIValue?) -> Bool {
        if let defaultValue {
            container[key] = defaultValue
            return false
        }
        if required { return true }
        container.removeValue(forKey: key)
        return false
    }

    // MARK: - Validators

    private static func validateElementPosition(_ element: ElementNode, _ schema: OpenUIObject, component: String, path: String, context: MaterializeContext) -> Bool {
        if isCompositeSchema(schema) { return false }
        let typeString: String?
        if case .string(let type)? = schema["type"] { typeString = type } else { typeString = nil }
        let hasEnum: Bool
        if case .array? = schema["enum"] { hasEnum = true } else { hasEnum = false }
        if typeString != nil || hasEnum || schema.contains("const") {
            push(context, component: component, path: path, issue: .typeMismatch(
                expected: typeString ?? "a literal value",
                actual: "component \"\(element.typeName)\""
            ))
            return true
        }
        return false
    }

    /// The `$ref` names a slot allows (`nil` for options without a `$ref`).
    private static func slotRefNames(_ schema: OpenUIObject) -> [String?] {
        let options: [OpenUIValue]
        if case .array(let anyOf)? = schema["anyOf"] {
            options = anyOf
        } else if case .array(let oneOf)? = schema["oneOf"] {
            options = oneOf
        } else {
            options = [.object(schema)]
        }
        return options.map { option in
            guard case .object(let object) = option else { return nil }
            return refName(object)
        }
    }

    private static func isOnlyComponentSlot(_ schema: OpenUIObject, context: MaterializeContext) -> Bool {
        let names = slotRefNames(schema)
        return !names.isEmpty && names.allSatisfy { name in
            guard let name else { return false }
            return context.catalog?.contains(name) ?? false
        }
    }

    private static func validateObjectValue(_ value: inout OpenUIValue, _ schema: OpenUIObject, component: String, path: String, context: MaterializeContext) -> Bool {
        guard case .object(var object) = value else {
            push(context, component: component, path: path, issue: .typeMismatch(expected: "object", actual: JS.jsType(value)))
            return true
        }
        let properties: OpenUIObject
        if case .object(let props)? = schema["properties"] { properties = props } else { properties = [:] }
        var required: [String] = []
        if case .array(let names)? = schema["required"] {
            required = names.compactMap(\.stringValue)
        }
        var invalid = false

        // Structural checks are streaming-sensitive — only run on complete input.
        if !context.partial {
            for key in required {
                let present = object.contains(key)
                if !present || JS.isNullish(object[key]) {
                    if let fallback = defaultValue(of: properties[key]) {
                        object[key] = fallback
                        continue
                    }
                    push(context, component: component, path: "\(path)/\(key)", issue: present ? .nullRequired(signature: nil) : .missingRequired(signature: nil))
                    invalid = true
                }
            }
        }

        for (key, subschema) in properties.entries {
            guard var child = object[key] else { continue }
            if validate(&child, schema: subschema, component: component, path: "\(path)/\(key)", context: context) {
                object[key] = child
                if resolveInvalidValue(&object, key: key, required: required.contains(key), defaultValue: defaultValue(of: subschema)) {
                    invalid = true
                }
            } else {
                object[key] = child
            }
        }
        value = .object(object)
        return invalid
    }

    private static func validateArrayValue(_ value: inout OpenUIValue, _ schema: OpenUIObject, component: String, path: String, context: MaterializeContext) -> Bool {
        guard case .array(var items) = value else {
            push(context, component: component, path: path, issue: .typeMismatch(expected: "array", actual: JS.jsType(value)))
            return true
        }
        guard let itemSchema = schema["items"], case .object = itemSchema else { return false }
        var invalidIndices: [Int] = []
        for index in items.indices {
            if validate(&items[index], schema: itemSchema, component: component, path: "\(path)/\(index)", context: context) {
                invalidIndices.append(index)
            }
        }
        for index in invalidIndices.reversed() {
            items.remove(at: index)
        }
        value = .array(items)
        return false
    }

    private static func validateLeafValue(_ value: OpenUIValue, _ schema: OpenUIObject, component: String, path: String, context: MaterializeContext) -> Bool {
        let leaf = scalarTypeInfo(schema)
        if leaf.expectedType == nil && leaf.enumValues == nil { return false }
        if leaf.enumValues != nil && context.partial { return false }
        if let mismatch = typeMismatch(value, leaf) {
            push(context, component: component, path: path, issue: .typeMismatch(expected: mismatch.expected, actual: mismatch.actual))
            return true
        }
        return false
    }

    /// Recursively validates `value` against a JSON Schema fragment, pruning unsalvageable data.
    /// Returns `true` when `value` itself is invalid (the caller applies the edge rule).
    @discardableResult
    static func validate(_ value: inout OpenUIValue, schema: OpenUIValue, component: String, path: String, context: MaterializeContext) -> Bool {
        guard case .object(let schemaObject) = schema else { return false }
        switch value {
        case .null, .expression:
            return false
        case .element(let element):
            return validateElementPosition(element, schemaObject, component: component, path: path, context: context)
        default:
            break
        }
        if isCompositeSchema(schemaObject) {
            guard isOnlyComponentSlot(schemaObject, context: context) else { return false }
            let actual: String
            switch value {
            case .array: actual = "array"
            case .object: actual = "plain object"
            default: actual = JS.typeOf(value)
            }
            let expected = slotRefNames(schemaObject).map { $0 ?? "" }.joined(separator: " | ")
            push(context, component: component, path: path, issue: .typeMismatch(expected: expected, actual: actual))
            return true
        }
        switch schemaObject["type"] {
        case .string("object")?:
            return validateObjectValue(&value, schemaObject, component: component, path: path, context: context)
        case .string("array")?:
            return validateArrayValue(&value, schemaObject, component: component, path: path, context: context)
        default:
            return validateLeafValue(value, schemaObject, component: component, path: path, context: context)
        }
    }
}
