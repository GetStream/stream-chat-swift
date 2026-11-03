//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// The type of a component prop — the Swift counterpart of the Zod schemas used to define OpenUI
/// component libraries.
///
/// A prop type produces both the JSON Schema used by the parser (positional mapping and
/// validation) and the type annotation shown to the model in the generated system prompt.
@available(iOS 17.0, macOS 14.0, *)
struct PropType: Sendable, Hashable {
    indirect enum Kind: Sendable, Hashable {
        case string
        case number
        case boolean
        case any
        case enumeration([String])
        case literal(String)
        case array(PropType, minItems: Int?)
        case object([PropField])
        case record(PropType)
        case component(String)
        case union([PropType])
        case action
        case actions([String])
    }

    let kind: Kind

    init(kind: Kind) {
        self.kind = kind
    }

    static let string = PropType(kind: .string)
    static let number = PropType(kind: .number)
    static let boolean = PropType(kind: .boolean)
    /// Anything (`{}` in JSON Schema).
    static let any = PropType(kind: .any)
    /// An action: one `@step`, or `Action([...])` with several (`ActionExpression` in signatures).
    static let action = PropType(kind: .action)

    /// One of a fixed set of strings: `"a" | "b"`.
    static func enumeration(_ values: [String]) -> PropType {
        PropType(kind: .enumeration(values))
    }

    /// A single string literal: `"open_url"`.
    static func literal(_ value: String) -> PropType {
        PropType(kind: .literal(value))
    }

    /// An array; `minItems` adds a JSON Schema length constraint.
    static func array(_ items: PropType, minItems: Int? = nil) -> PropType {
        PropType(kind: .array(items, minItems: minItems))
    }

    /// A nested object with named fields.
    static func object(_ fields: [PropField]) -> PropType {
        PropType(kind: .object(fields))
    }

    /// `Record<string, Value>`.
    static func record(_ value: PropType) -> PropType {
        PropType(kind: .record(value))
    }

    /// A reference to another component in the library (rendered as its name in signatures).
    static func component(_ name: String) -> PropType {
        PropType(kind: .component(name))
    }

    /// Any of several types: `A | B`.
    static func union(_ options: [PropType]) -> PropType {
        PropType(kind: .union(options))
    }

    /// An action slot that takes only the listed steps, such as `["CopyToClipboard", "OpenUrl"]`
    /// (`@CopyToClipboard | @OpenUrl` in signatures). Built-in steps with a JSON shape are `OpenUrl`
    /// and `ToAssistant`; any other name is one of the library's custom actions.
    static func actions(_ names: [String]) -> PropType {
        PropType(kind: .actions(names))
    }

    /// The JSON Schema for this type (matches the output of Zod's `toJSONSchema`).
    var jsonSchema: OpenUIValue {
        switch kind {
        case .string:
            return ["type": "string"]
        case .number:
            return ["type": "number"]
        case .boolean:
            return ["type": "boolean"]
        case .any:
            return [:]
        case .enumeration(let values):
            return ["type": "string", "enum": .array(values.map(OpenUIValue.string))]
        case .literal(let value):
            return ["type": "string", "const": .string(value)]
        case .array(let items, let minItems):
            var schema = OpenUIObject()
            if let minItems { schema["minItems"] = .number(Double(minItems)) }
            schema["type"] = "array"
            schema["items"] = items.jsonSchema
            return .object(schema)
        case .object(let fields):
            return PropField.objectSchema(fields, description: nil)
        case .record(let value):
            return ["type": "object", "propertyNames": ["type": "string"], "additionalProperties": value.jsonSchema]
        case .component(let name):
            return ["$ref": .string("#/$defs/\(name)")]
        case .union(let options):
            return ["anyOf": .array(options.map(\.jsonSchema))]
        case .action:
            return ["$ref": .string("#/$defs/\(Self.actionExpressionName)")]
        case .actions(let names):
            return ["anyOf": .array(names.map { ["$ref": .string("#/$defs/\($0)")] })]
        }
    }

    /// The type annotation used in prompt signatures (e.g. `string`, `Series[]`, `(A | B)[]`).
    var signature: String {
        switch kind {
        case .string: return "string"
        case .number: return "number"
        case .boolean: return "boolean"
        case .any: return "any"
        case .enumeration(let values): return values.map { "\"\($0)\"" }.joined(separator: " | ")
        case .literal(let value): return "\"\(value)\""
        case .array(let items, _):
            if case .union = items.kind { return "(\(items.signature))[]" }
            return "\(items.signature)[]"
        case .object(let fields):
            return "{" + fields.map(\.signature).joined(separator: ", ") + "}"
        case .record(let value):
            return "Record<string, \(value.signature)>"
        case .component(let name):
            return name
        case .union(let options):
            return options.map(\.signature).joined(separator: " | ")
        case .action:
            return Self.actionExpressionName
        case .actions(let names):
            return names.map { "@\($0)" }.joined(separator: " | ")
        }
    }

    /// A `$defs` entry a type refers to: a component, or the JSON shape of an action.
    enum Definition: Hashable {
        case component(String)
        case action(String)
    }

    /// The `$defs` entries this type refers to, in declaration order.
    var definitionReferences: [Definition] {
        switch kind {
        case .component(let name):
            return [.component(name)]
        case .array(let items, _):
            return items.definitionReferences
        case .union(let options):
            return options.flatMap(\.definitionReferences)
        case .object(let fields):
            return fields.flatMap(\.type.definitionReferences)
        case .record(let value):
            return value.definitionReferences
        case .action:
            return [.action(Self.actionExpressionName)]
        case .actions(let names):
            return names.map(Definition.action)
        case .string, .number, .boolean, .any, .enumeration, .literal:
            return []
        }
    }

    /// Component names referenced by this type, in declaration order.
    var componentReferences: [String] {
        definitionReferences.compactMap { reference in
            if case .component(let name) = reference { return name }
            return nil
        }
    }

    /// The type without `names` among the options of its unions. A union keeps them when they are
    /// all it has.
    func removingComponents(_ names: Set<String>) -> PropType {
        switch kind {
        case .union(let options):
            let kept = options.filter { option in
                guard case .component(let name) = option.kind else { return true }
                return !names.contains(name)
            }
            return kept.isEmpty ? self : .union(kept.map { $0.removingComponents(names) })
        case .array(let items, let minItems):
            return .array(items.removingComponents(names), minItems: minItems)
        case .record(let value):
            return .record(value.removingComponents(names))
        case .object(let fields):
            return .object(fields.map { field in
                var field = field
                field.type = field.type.removingComponents(names)
                return field
            })
        case .string, .number, .boolean, .any, .enumeration, .literal, .component, .action, .actions:
            return self
        }
    }

    /// The components this type can't do without when `names` are removed: a slot's only type, or
    /// the types of a union that would be left with none.
    func neededComponents(removing names: Set<String>) -> [String] {
        switch kind {
        case .component(let name):
            return [name]
        case .union(let options):
            let components = options.compactMap { option -> String? in
                guard case .component(let name) = option.kind else { return nil }
                return name
            }
            let nested = options.flatMap { option -> [String] in
                if case .component = option.kind { return [] }
                return option.neededComponents(removing: names)
            }
            let keepsOne = options.count > components.count || components.contains { !names.contains($0) }
            return (keepsOne ? [] : components) + nested
        case .array(let items, _):
            return items.neededComponents(removing: names)
        case .record(let value):
            return value.neededComponents(removing: names)
        case .object(let fields):
            return fields.flatMap { $0.type.neededComponents(removing: names) }
        case .string, .number, .boolean, .any, .enumeration, .literal, .action, .actions:
            return []
        }
    }

    static let actionExpressionName = "ActionExpression"

    /// The legacy action object contract (the JSON Schema side of `ActionExpression`).
    static let actionSchema: OpenUIValue = [
        "anyOf": [
            openURLSchema,
            toAssistantSchema,
            [
                "type": "object",
                "properties": [
                    "type": ["type": "string"],
                    "params": ["type": "object", "propertyNames": ["type": "string"], "additionalProperties": [:]]
                ],
                "required": ["type"],
                "additionalProperties": false
            ]
        ]
    ]

    /// The JSON shape of `@OpenUrl` (`$defs.OpenUrl`).
    static let openURLSchema: OpenUIValue = [
        "type": "object",
        "properties": ["type": ["type": "string", "const": "open_url"], "url": ["type": "string"]],
        "required": ["type", "url"],
        "additionalProperties": false
    ]

    /// The JSON shape of `@ToAssistant` (`$defs.ToAssistant`).
    static let toAssistantSchema: OpenUIValue = [
        "type": "object",
        "properties": ["type": ["type": "string", "const": "continue_conversation"], "context": ["type": "string"]],
        "required": ["type"],
        "additionalProperties": false
    ]
}

/// A named prop (or nested object field) with its type and modifiers.
@available(iOS 17.0, macOS 14.0, *)
struct PropField: Sendable, Hashable {
    var name: String
    var type: PropType
    /// Optional props may be omitted from the end of a positional call.
    var isOptional: Bool
    /// Schema default (used when the value is missing, `null` or invalid).
    var defaultValue: OpenUIValue?
    /// Reactive props accept a `$variable` for two-way binding (`$binding<T>` in signatures).
    var isReactive: Bool

    init(_ name: String, _ type: PropType, isOptional: Bool = false, defaultValue: OpenUIValue? = nil, isReactive: Bool = false) {
        self.name = name
        self.type = type
        self.isOptional = isOptional
        self.defaultValue = defaultValue
        self.isReactive = isReactive
    }

    /// A required prop.
    static func required(_ name: String, _ type: PropType) -> PropField {
        PropField(name, type)
    }

    /// An optional prop.
    static func optional(_ name: String, _ type: PropType) -> PropField {
        PropField(name, type, isOptional: true)
    }

    /// A prop with a default value (optional for the model, always present after parsing).
    static func defaulted(_ name: String, _ type: PropType, _ defaultValue: OpenUIValue) -> PropField {
        PropField(name, type, isOptional: true, defaultValue: defaultValue)
    }

    /// An optional prop that accepts a `$variable` binding.
    static func binding(_ name: String, _ type: PropType) -> PropField {
        PropField(name, type, isOptional: true, isReactive: true)
    }

    /// Present in the JSON Schema `required` list (required props and props with defaults).
    var isSchemaRequired: Bool {
        !isOptional || defaultValue != nil
    }

    var jsonSchema: OpenUIValue {
        guard let defaultValue else { return type.jsonSchema }
        var schema = OpenUIObject()
        schema["default"] = defaultValue
        if case .object(let base) = type.jsonSchema {
            for (key, value) in base.entries { schema[key] = value }
        }
        return .object(schema)
    }

    /// `name: type`, `name?: type`, or `name?: $binding<type>`.
    var signature: String {
        let base = type.signature
        let annotation = isReactive ? "$binding<\(base)>" : base
        return isOptional ? "\(name)?: \(annotation)" : "\(name): \(annotation)"
    }

    static func objectSchema(_ fields: [PropField], description: String?) -> OpenUIValue {
        var schema: OpenUIObject = ["type": "object"]
        schema["properties"] = .object(OpenUIObject(fields.map { ($0.name, $0.jsonSchema) }))
        let required = fields.filter(\.isSchemaRequired).map { OpenUIValue.string($0.name) }
        if !required.isEmpty { schema["required"] = .array(required) }
        schema["additionalProperties"] = false
        if let description, !description.isEmpty { schema["description"] = .string(description) }
        return .object(schema)
    }
}

/// The schema of a component: its name, description and ordered (positional) props.
@available(iOS 17.0, macOS 14.0, *)
struct ComponentSchema: Sendable, Hashable {
    var name: String
    var description: String
    var props: [PropField]

    init(_ name: String, description: String, props: [PropField]) {
        self.name = name
        self.description = description
        self.props = props
    }

    /// Prompt signature: `Name(prop: type, optional?: type, ...)`.
    var signature: String {
        "\(name)(" + props.map(\.signature).joined(separator: ", ") + ")"
    }

    /// The component's JSON Schema definition.
    var jsonSchema: OpenUIValue {
        PropField.objectSchema(props, description: description)
    }

    /// Names of reactive props.
    var reactiveProps: Set<String> {
        Set(props.filter(\.isReactive).map(\.name))
    }

    /// Returns a copy with the prop named `name` modified.
    func updatingProp(_ name: String, _ update: (inout PropField) -> Void) -> ComponentSchema {
        var copy = self
        if let index = copy.props.firstIndex(where: { $0.name == name }) {
            update(&copy.props[index])
        }
        return copy
    }
}
