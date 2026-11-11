//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Builders for the JSON Schema fragments used by A2UI catalog definitions.
///
/// A2UI catalogs are plain JSON Schema documents whose property types reference
/// the shared definitions in `common_types.json`. These helpers keep catalog
/// declarations readable while producing spec-compliant output that can be sent
/// to an agent as an inline catalog or embedded in a prompt.
@available(iOS 15.0, macOS 12.0, *)
enum JsonSchema {
    /// The base URI of the shared A2UI common type definitions.
    static let commonTypesUri = "https://a2ui.org/specification/v1_0/common_types.json"

    /// The JSON Schema dialect used by A2UI catalogs.
    static let dialect = "https://json-schema.org/draft/2020-12/schema"

    // MARK: - Primitives

    /// Builds an object schema.
    /// Property order is irrelevant; `required` lists mandatory keys.
    static func object(
        title: String? = nil,
        description: String? = nil,
        properties: [String: JsonMap] = [:],
        required: [String] = [],
        additionalProperties: Bool? = nil
    ) -> JsonMap {
        var schema: JsonMap = ["type": "object"]
        if let title { schema["title"] = title }
        if let description { schema["description"] = description }
        if !properties.isEmpty { schema["properties"] = properties }
        if !required.isEmpty { schema["required"] = required.sorted() }
        if let additionalProperties { schema["additionalProperties"] = additionalProperties }
        return schema
    }

    /// Builds a string schema.
    /// Use `enumValues` to constrain the accepted values.
    static func string(
        description: String? = nil,
        enumValues: [String]? = nil,
        format: String? = nil,
        defaultValue: String? = nil
    ) -> JsonMap {
        var schema: JsonMap = ["type": "string"]
        if let description { schema["description"] = description }
        if let enumValues { schema["enum"] = enumValues }
        if let format { schema["format"] = format }
        if let defaultValue { schema["default"] = defaultValue }
        return schema
    }

    /// Builds a number schema.
    /// Use this for floating point properties such as layout weights.
    static func number(description: String? = nil, defaultValue: Double? = nil) -> JsonMap {
        var schema: JsonMap = ["type": "number"]
        if let description { schema["description"] = description }
        if let defaultValue { schema["default"] = defaultValue }
        return schema
    }

    /// Builds an integer schema.
    /// Use `minimum` to constrain the accepted range.
    static func integer(description: String? = nil, minimum: Int? = nil) -> JsonMap {
        var schema: JsonMap = ["type": "integer"]
        if let description { schema["description"] = description }
        if let minimum { schema["minimum"] = minimum }
        return schema
    }

    /// Builds a boolean schema.
    /// Use `defaultValue` to document the renderer's default behaviour.
    static func boolean(description: String? = nil, defaultValue: Bool? = nil) -> JsonMap {
        var schema: JsonMap = ["type": "boolean"]
        if let description { schema["description"] = description }
        if let defaultValue { schema["default"] = defaultValue }
        return schema
    }

    /// Builds an array schema.
    /// Provide the item schema and optional minimum length.
    static func array(description: String? = nil, items: JsonMap, minItems: Int? = nil) -> JsonMap {
        var schema: JsonMap = ["type": "array", "items": items]
        if let description { schema["description"] = description }
        if let minItems { schema["minItems"] = minItems }
        return schema
    }

    /// Builds a constant schema.
    /// Used for the `component` and `call` discriminators.
    static func constant(_ value: String) -> JsonMap {
        ["const": value]
    }

    /// Builds a reference to another schema.
    /// Pass an absolute URI or a local JSON pointer.
    static func reference(_ uri: String, description: String? = nil) -> JsonMap {
        var schema: JsonMap = ["$ref": uri]
        if let description { schema["description"] = description }
        return schema
    }

    /// Builds a schema accepting any of the given alternatives.
    static func oneOf(_ schemas: [JsonMap], description: String? = nil) -> JsonMap {
        var schema: JsonMap = ["oneOf": schemas]
        if let description { schema["description"] = description }
        return schema
    }

    /// Builds a schema requiring all of the given fragments.
    static func allOf(_ schemas: [JsonMap]) -> JsonMap {
        ["allOf": schemas]
    }

    // MARK: - A2UI common types

    /// A reference to a shared definition in `common_types.json`.
    static func commonType(_ name: String, description: String? = nil) -> JsonMap {
        reference("\(commonTypesUri)#/$defs/\(name)", description: description)
    }

    /// A string that may be a literal, a data binding or a function call.
    static func dynamicString(description: String? = nil) -> JsonMap {
        commonType("DynamicString", description: description)
    }

    /// A number that may be a literal, a data binding or a function call.
    static func dynamicNumber(description: String? = nil) -> JsonMap {
        commonType("DynamicNumber", description: description)
    }

    /// A boolean that may be a literal, a data binding or a function call.
    static func dynamicBoolean(description: String? = nil) -> JsonMap {
        commonType("DynamicBoolean", description: description)
    }

    /// A string array that may be a literal, a data binding or a function call.
    static func dynamicStringList(description: String? = nil) -> JsonMap {
        commonType("DynamicStringList", description: description)
    }

    /// Any value that may be a literal, a data binding or a function call.
    static func dynamicValue(description: String? = nil) -> JsonMap {
        commonType("DynamicValue", description: description)
    }

    /// A reference to a single child component id.
    static func child(description: String? = nil) -> JsonMap {
        commonType("ComponentId", description: description)
    }

    /// A static list of child ids or a template bound to a collection.
    static func children(description: String? = nil) -> JsonMap {
        commonType("ChildList", description: description)
    }

    /// An interaction handler that dispatches an event or calls a function.
    static func action(description: String? = nil) -> JsonMap {
        commonType("Action", description: description)
    }

    /// The property set added to components that support validation checks.
    static func checkable() -> JsonMap {
        commonType("Checkable")
    }

    /// The layout weight property shared by all basic catalog components.
    static func weight() -> JsonMap {
        number(
            description: "The relative weight of this component within a Row or Column, similar to the CSS 'flex-grow' property. This may ONLY be set when the component is a direct descendant of a Row or Column."
        )
    }
}

// The subset of JSON Schema that function arguments use. Agent calls are checked once resolved;
// a component's calls when they arrive, where a binding or call can stand in for any value.
@available(iOS 15.0, macOS 12.0, *)
enum JsonSchemaValidator {
    struct Violation: Equatable {
        let pointer: String
        let message: String
    }

    static func violation(
        of value: (any Sendable)?,
        against schema: JsonMap,
        allowsDynamicValues: Bool = false,
        at pointer: String = ""
    ) -> Violation? {
        if allowsDynamicValues, let map = Json.map(value),
           map[A2UIProtocol.pathKey] != nil || map[A2UIProtocol.callKey] != nil {
            return nil
        }
        func check(_ child: (any Sendable)?, _ childSchema: JsonMap, _ childPointer: String) -> Violation? {
            violation(of: child, against: childSchema, allowsDynamicValues: allowsDynamicValues, at: childPointer)
        }
        func fail(_ message: String) -> Violation {
            Violation(pointer: pointer, message: "\(pointer.isEmpty ? "The arguments" : "'\(pointer)'") \(message)")
        }

        if let reference = schema["$ref"] as? String {
            return referenceViolation(of: value, reference: reference).map(fail)
        }
        if let options = (Json.array(schema["anyOf"]) ?? Json.array(schema["oneOf"]))?.compactMap(Json.map), !options.isEmpty,
           options.allSatisfy({ check(value, $0, pointer) != nil }) {
            return fail("matches none of its allowed shapes")
        }
        for part in Json.array(schema["allOf"])?.compactMap(Json.map) ?? [] {
            if let violation = check(value, part, pointer) { return violation }
        }
        if let types = typeNames(schema["type"]), !types.contains(where: { matches(value, type: $0) }) {
            return fail("must be \(types.joined(separator: " or "))")
        }
        if let options = Json.array(schema["enum"]), !options.contains(where: { Json.isEqual($0, value) }) {
            return fail("must be one of \(Json.encodeToString(options) ?? "")")
        }
        if let constant = schema["const"], !Json.isEqual(constant, value) {
            return fail("must be \(Json.encodeToString(constant) ?? "")")
        }
        if let number = number(value) {
            if let minimum = Json.double(schema["minimum"]), number < minimum { return fail("must be at least \(Json.stringify(minimum))") }
            if let maximum = Json.double(schema["maximum"]), number > maximum { return fail("must be at most \(Json.stringify(maximum))") }
        }
        if let map = Json.map(value) {
            for key in Json.stringArray(schema["required"]) ?? [] where map[key] == nil {
                return fail("must have '\(key)'")
            }
            let properties = Json.map(schema["properties"]) ?? [:]
            for key in map.keys.sorted() {
                let child = "\(pointer)/\(key.replacingOccurrences(of: "~", with: "~0").replacingOccurrences(of: "/", with: "~1"))"
                if let propertySchema = Json.map(properties[key]) {
                    if let violation = check(map[key], propertySchema, child) { return violation }
                } else if schema["additionalProperties"] as? Bool == false {
                    return Violation(pointer: child, message: "'\(key)' is not an allowed property")
                } else if let extra = Json.map(schema["additionalProperties"]), let violation = check(map[key], extra, child) {
                    return violation
                }
            }
        }
        if let array = Json.array(value) {
            if let minimum = Json.int(schema["minItems"]), array.count < minimum { return fail("must have at least \(minimum) items") }
            if let maximum = Json.int(schema["maxItems"]), array.count > maximum { return fail("must have at most \(maximum) items") }
            if let items = Json.map(schema["items"]) {
                for (index, item) in array.enumerated() {
                    if let violation = check(item, items, "\(pointer)/\(index)") { return violation }
                }
            }
        }
        return nil
    }

    private static func referenceViolation(of value: (any Sendable)?, reference: String) -> String? {
        switch reference.split(separator: "/").last.map(String.init) ?? "" {
        case "DynamicString":
            return value is String || number(value) != nil || value is Bool ? nil : "must be a string"
        case "DynamicNumber":
            return number(value) != nil || (value as? String).flatMap(Double.init) != nil ? nil : "must be a number"
        case "DynamicBoolean":
            return value is Bool ? nil : "must be a boolean"
        case "DynamicStringList":
            return Json.array(value) != nil ? nil : "must be a list"
        default:
            return nil
        }
    }

    private static func typeNames(_ raw: (any Sendable)?) -> [String]? {
        if let name = raw as? String { return [name] }
        return Json.stringArray(raw)
    }

    private static func matches(_ value: (any Sendable)?, type: String) -> Bool {
        switch type {
        case "string": return value is String
        case "number": return number(value) != nil
        case "integer": return number(value).map { $0.rounded() == $0 } ?? false
        case "boolean": return value is Bool
        case "object": return Json.map(value) != nil
        case "array": return Json.array(value) != nil
        case "null": return value == nil || value is NSNull
        default: return true
        }
    }

    private static func number(_ value: (any Sendable)?) -> Double? {
        switch value {
        case let value as Int: return Double(value)
        case let value as Double: return value.isFinite ? value : nil
        default: return nil
        }
    }
}
