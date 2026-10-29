//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// A parameter of a component: what the agent fills in when it places the component.
public struct AIUIParameter: Equatable, Sendable {
    /// The name the agent fills it in by, such as `title`.
    public var name: String
    /// What it holds.
    public var type: AIUIParameterType
    /// What it is, for the agent.
    public var description: String?
    /// Whether the agent must fill it in.
    public var isRequired: Bool

    public init(name: String, type: AIUIParameterType, description: String? = nil, isRequired: Bool = true) {
        self.name = name
        self.type = type
        self.description = description
        self.isRequired = isRequired
    }

    /// A parameter the agent must fill in.
    public static func required(_ name: String, _ type: AIUIParameterType, description: String? = nil) -> AIUIParameter {
        AIUIParameter(name: name, type: type, description: description, isRequired: true)
    }

    /// A parameter the agent may leave out.
    public static func optional(_ name: String, _ type: AIUIParameterType, description: String? = nil) -> AIUIParameter {
        AIUIParameter(name: name, type: type, description: description, isRequired: false)
    }
}

/// The type of a component's parameter, as JSON Schema. It is an open set: use the static
/// members, or any JSON Schema the formats you render can read.
public struct AIUIParameterType: Equatable, Sendable {
    /// The type as a JSON Schema object.
    public var schema: [String: RawJSON]

    public init(schema: [String: RawJSON]) {
        self.schema = schema
    }

    public static let string = AIUIParameterType(schema: ["type": .string("string")])
    public static let number = AIUIParameterType(schema: ["type": .string("number")])
    public static let integer = AIUIParameterType(schema: ["type": .string("integer")])
    public static let boolean = AIUIParameterType(schema: ["type": .string("boolean")])
    /// A day, such as `2026-11-14`.
    public static let date = AIUIParameterType(schema: ["type": .string("string"), "format": .string("date")])
    /// A moment, such as `2026-11-14T09:30:00Z`.
    public static let dateTime = AIUIParameterType(schema: ["type": .string("string"), "format": .string("date-time")])
    /// A link, such as an image's.
    public static let url = AIUIParameterType(schema: ["type": .string("string"), "format": .string("uri")])

    /// One of a fixed set of strings.
    public static func enumeration(_ values: [String]) -> AIUIParameterType {
        AIUIParameterType(schema: ["type": .string("string"), "enum": .array(values.map(RawJSON.string))])
    }

    /// A list of values of one type.
    public static func array(_ items: AIUIParameterType) -> AIUIParameterType {
        AIUIParameterType(schema: ["type": .string("array"), "items": .dictionary(items.schema)])
    }

    /// An object with named fields, in order.
    public static func object(_ fields: [AIUIParameter]) -> AIUIParameterType {
        AIUIParameterType(schema: AIUIParameter.objectSchema(fields))
    }
}

extension AIUIParameter {
    /// The key that keeps the order of an object's fields, which JSON objects don't have.
    static let orderKey = "x-order"

    static func objectSchema(_ parameters: [AIUIParameter]) -> [String: RawJSON] {
        var properties: [String: RawJSON] = [:]
        for parameter in parameters {
            var schema = parameter.type.schema
            if let description = parameter.description {
                schema["description"] = .string(description)
            }
            properties[parameter.name] = .dictionary(schema)
        }
        return [
            "type": .string("object"),
            "properties": .dictionary(properties),
            "required": .array(parameters.filter(\.isRequired).map { .string($0.name) }),
            orderKey: .array(parameters.map { .string($0.name) })
        ]
    }

    // The fields of a JSON Schema object, in the order it keeps, then by name.
    static func parameters(fromObjectSchema schema: [String: RawJSON]) -> [AIUIParameter] {
        let properties = schema["properties"]?.dictionaryValue ?? [:]
        let required = Set((schema["required"]?.arrayValue ?? []).compactMap(\.stringValue))
        let ordered = (schema[orderKey]?.arrayValue ?? []).compactMap(\.stringValue).filter { properties[$0] != nil }
        let names = ordered + properties.keys.filter { !ordered.contains($0) }.sorted()
        return names.compactMap { name in
            guard var fieldSchema = properties[name]?.dictionaryValue else { return nil }
            let description = fieldSchema.removeValue(forKey: "description")?.stringValue
            return AIUIParameter(
                name: name,
                type: AIUIParameterType(schema: fieldSchema),
                description: description,
                isRequired: required.contains(name)
            )
        }
    }
}
