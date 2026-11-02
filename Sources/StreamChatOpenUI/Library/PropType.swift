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
public indirect enum PropType: Sendable, Hashable {
    case string
    case number
    case boolean
    /// Anything (`{}` in JSON Schema).
    case any
    /// One of a fixed set of strings: `"a" | "b"`.
    case enumeration([String])
    /// A single string literal: `"open_url"`.
    case literal(String)
    /// An array; `minItems` adds a JSON Schema length constraint.
    case array(PropType, minItems: Int? = nil)
    /// A nested object with named fields.
    case object([PropField])
    /// `Record<string, Value>`.
    case record(PropType)
    /// A reference to another component in the library (rendered as its name in signatures).
    case component(String)
    /// Any of several types: `A | B`.
    case union([PropType])
    /// An `Action([...])` expression (or a legacy action object).
    case action

    /// The JSON Schema for this type (matches the output of Zod's `toJSONSchema`).
    public var jsonSchema: OpenUIValue {
        switch self {
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
            return Self.actionSchema
        }
    }

    /// The type annotation used in prompt signatures (e.g. `string`, `Series[]`, `(A | B)[]`).
    public var signature: String {
        switch self {
        case .string: return "string"
        case .number: return "number"
        case .boolean: return "boolean"
        case .any: return "any"
        case .enumeration(let values): return values.map { "\"\($0)\"" }.joined(separator: " | ")
        case .literal(let value): return "\"\(value)\""
        case .array(let items, _):
            if case .union = items { return "(\(items.signature))[]" }
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
            return "ActionExpression"
        }
    }

    /// Component names referenced by this type, in declaration order.
    var componentReferences: [String] {
        switch self {
        case .component(let name):
            return [name]
        case .array(let items, _):
            return items.componentReferences
        case .union(let options):
            return options.flatMap(\.componentReferences)
        case .object(let fields):
            return fields.flatMap(\.type.componentReferences)
        case .record(let value):
            return value.componentReferences
        case .string, .number, .boolean, .any, .enumeration, .literal, .action:
            return []
        }
    }

    /// The legacy action object contract (the JSON Schema side of `ActionExpression`).
    static let actionSchema: OpenUIValue = [
        "anyOf": [
            [
                "type": "object",
                "properties": ["type": ["type": "string", "const": "open_url"], "url": ["type": "string"]],
                "required": ["type", "url"],
                "additionalProperties": false
            ],
            [
                "type": "object",
                "properties": ["type": ["type": "string", "const": "continue_conversation"], "context": ["type": "string"]],
                "required": ["type"],
                "additionalProperties": false
            ],
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
}

/// A named prop (or nested object field) with its type and modifiers.
@available(iOS 17.0, macOS 14.0, *)
public struct PropField: Sendable, Hashable {
    public var name: String
    public var type: PropType
    /// Optional props may be omitted from the end of a positional call.
    public var isOptional: Bool
    /// Schema default (used when the value is missing, `null` or invalid).
    public var defaultValue: OpenUIValue?
    /// Reactive props accept a `$variable` for two-way binding (`$binding<T>` in signatures).
    public var isReactive: Bool

    public init(_ name: String, _ type: PropType, isOptional: Bool = false, defaultValue: OpenUIValue? = nil, isReactive: Bool = false) {
        self.name = name
        self.type = type
        self.isOptional = isOptional
        self.defaultValue = defaultValue
        self.isReactive = isReactive
    }

    /// A required prop.
    public static func required(_ name: String, _ type: PropType) -> PropField {
        PropField(name, type)
    }

    /// An optional prop.
    public static func optional(_ name: String, _ type: PropType) -> PropField {
        PropField(name, type, isOptional: true)
    }

    /// A prop with a default value (optional for the model, always present after parsing).
    public static func defaulted(_ name: String, _ type: PropType, _ defaultValue: OpenUIValue) -> PropField {
        PropField(name, type, isOptional: true, defaultValue: defaultValue)
    }

    /// An optional prop that accepts a `$variable` binding.
    public static func binding(_ name: String, _ type: PropType) -> PropField {
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
public struct ComponentSchema: Sendable, Hashable {
    public var name: String
    public var description: String
    public var props: [PropField]

    public init(_ name: String, description: String, props: [PropField]) {
        self.name = name
        self.description = description
        self.props = props
    }

    /// Prompt signature: `Name(prop: type, optional?: type, ...)`.
    public var signature: String {
        "\(name)(" + props.map(\.signature).joined(separator: ", ") + ")"
    }

    /// The component's JSON Schema definition.
    public var jsonSchema: OpenUIValue {
        PropField.objectSchema(props, description: description)
    }

    /// Names of reactive props.
    public var reactiveProps: Set<String> {
        Set(props.filter(\.isReactive).map(\.name))
    }

    /// Returns a copy with the prop named `name` modified.
    public func updatingProp(_ name: String, _ update: (inout PropField) -> Void) -> ComponentSchema {
        var copy = self
        if let index = copy.props.firstIndex(where: { $0.name == name }) {
            update(&copy.props[index])
        }
        return copy
    }
}
