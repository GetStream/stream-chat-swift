//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Components an app describes once for every platform and for its agent: a portable definition
/// with a snake_case `name`, a `description`, `parameters` as a JSON Schema object that keeps
/// their order in `x-order`, and the `events` the component reports.
///
/// ```json
/// { "name": "place_card", "description": "A photo and a short summary of a place.",
///   "parameters": { "type": "object", "properties": { "title": { "type": "string" } },
///                   "required": ["title"], "x-order": ["title"] },
///   "events": [{ "name": "ask_about", "description": "The person asks about the place." }] }
/// ```
@available(iOS 17.0, macOS 14.0, *)
public extension ComponentSchema {
    /// The OpenUI name of a portable component: OpenUI Lang calls components by capitalized
    /// names, so `place_card` is `PlaceCard`.
    static func typeName(forPortableName name: String) -> String {
        name.split(whereSeparator: { $0 == "_" || $0 == "-" || $0 == " " })
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined()
    }

    /// The schema of a portable component definition. Its parameters' descriptions and its events
    /// join its description, which is all of a component the model reads besides its signature.
    init(portableDefinition definition: OpenUIValue) throws {
        guard let name = definition["name"]?.stringValue, !name.isEmpty else {
            throw PortableComponentError(message: "A component definition needs a name")
        }
        let parameters = definition["parameters"] ?? .null
        var notes: [String] = []
        if let description = definition["description"]?.stringValue, !description.isEmpty {
            notes.append(Self.sentence(description))
        }
        for (field, schema) in Self.orderedProperties(parameters) {
            if let description = schema["description"]?.stringValue, !description.isEmpty {
                notes.append(Self.sentence("\(field): \(description)"))
            }
        }
        for event in definition["events"]?.arrayValue ?? [] {
            if let description = event["description"]?.stringValue, !description.isEmpty {
                notes.append(Self.sentence(description))
            }
        }
        self.init(
            Self.typeName(forPortableName: name),
            description: notes.joined(separator: " "),
            props: Self.fields(parameters)
        )
    }

    private static func sentence(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard let last = trimmed.last, !".!?".contains(last) else { return trimmed }
        return trimmed + "."
    }

    private static func fields(_ schema: OpenUIValue) -> [PropField] {
        let required = Set((schema["required"]?.arrayValue ?? []).compactMap(\.stringValue))
        return orderedProperties(schema).map { name, property in
            required.contains(name) ? .required(name, PropType(jsonSchema: property)) : .optional(name, PropType(jsonSchema: property))
        }
    }

    // A JSON Schema object's properties in the order of its `x-order`, then as written.
    private static func orderedProperties(_ schema: OpenUIValue) -> [(String, OpenUIValue)] {
        guard let properties = schema["properties"]?.objectValue else { return [] }
        let ordered = (schema["x-order"]?.arrayValue ?? []).compactMap(\.stringValue).filter { properties[$0] != nil }
        let rest = properties.entries.map(\.key).filter { !ordered.contains($0) }
        return (ordered + rest).compactMap { name in properties[name].map { (name, $0) } }
    }
}

@available(iOS 17.0, macOS 14.0, *)
public extension PropType {
    /// The prop type closest to a JSON Schema type.
    init(jsonSchema schema: OpenUIValue) {
        if let values = schema["enum"]?.arrayValue?.compactMap(\.stringValue), !values.isEmpty {
            self = .enumeration(values)
            return
        }
        switch schema["type"]?.stringValue {
        case "string":
            self = .string
        case "number", "integer":
            self = .number
        case "boolean":
            self = .boolean
        case "array":
            self = .array(PropType(jsonSchema: schema["items"] ?? .null))
        case "object" where schema["properties"]?.objectValue?.isEmpty == false:
            let required = Set((schema["required"]?.arrayValue ?? []).compactMap(\.stringValue))
            let properties = schema["properties"]?.objectValue?.entries ?? []
            self = .object(properties.map { name, property in
                required.contains(name) ? .required(name, PropType(jsonSchema: property)) : .optional(name, PropType(jsonSchema: property))
            })
        default:
            self = .any
        }
    }

    /// The type with `names` added to every union of content components in it, such as the
    /// children of a chat `Card`. A union is one of content when it holds `TextContent`.
    func addingContentComponents(_ names: [String]) -> PropType {
        switch self {
        case let .union(options) where options.contains(.component("TextContent")):
            return .union(options + names.map(PropType.component).filter { !options.contains($0) })
        case let .array(items, minItems):
            return .array(items.addingContentComponents(names), minItems: minItems)
        default:
            return self
        }
    }
}

@available(iOS 17.0, macOS 14.0, *)
public extension ComponentLibrary {
    /// A library with `components` added, and placeable wherever the library's own content goes,
    /// such as the children of a chat `Card` or the content of a `TabItem`.
    /// - Parameters:
    ///   - group: The heading the components are listed under in the system prompt.
    ///   - notes: Guidance on using them, listed under the heading.
    func addingContent(_ components: [ComponentDefinition], group: String = "App components", notes: [String] = []) -> ComponentLibrary {
        let names = components.map(\.name)
        let widened = self.components.map { definition -> ComponentDefinition in
            var schema = definition.schema
            schema.props = schema.props.map { field in
                var field = field
                field.type = field.type.addingContentComponents(names)
                return field
            }
            return ComponentDefinition(schema, renderer: definition.renderer)
        }
        return ComponentLibrary(
            root: root,
            components: widened + components,
            componentGroups: componentGroups + [ComponentGroup(name: group, components: names, notes: notes)],
            defaultPromptOptions: defaultPromptOptions
        )
    }
}

/// A portable component definition OpenUI can't read.
@available(iOS 17.0, macOS 14.0, *)
public struct PortableComponentError: Error, LocalizedError, Sendable {
    public let message: String

    public var errorDescription: String? { message }
}
