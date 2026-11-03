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
extension ComponentSchema {
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
            throw OpenUIPortableComponentError(message: "A component definition needs a name")
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
            props: PropType.fields(of: parameters)
        )
    }

    // A component's line in the prompt stays on one line, so a description does too.
    private static func sentence(_ text: String) -> String {
        let trimmed = text.split(whereSeparator: \.isWhitespace).joined(separator: " ")
        guard let last = trimmed.last, !".!?".contains(last) else { return trimmed }
        return trimmed + "."
    }

    // A JSON Schema object's properties in the order of its `x-order`, then as written.
    fileprivate static func orderedProperties(_ schema: OpenUIValue) -> [(String, OpenUIValue)] {
        guard let properties = schema["properties"]?.objectValue else { return [] }
        var seen = Set<String>()
        let ordered = (schema["x-order"]?.arrayValue ?? []).compactMap(\.stringValue).filter { properties[$0] != nil && seen.insert($0).inserted }
        let rest = properties.entries.map(\.key).filter { !seen.contains($0) }
        return (ordered + rest).compactMap { name in properties[name].map { (name, $0) } }
    }
}

@available(iOS 17.0, macOS 14.0, *)
extension PropType {
    /// The prop type closest to a JSON Schema type. `type: ["string", "null"]` reads as a string,
    /// `anyOf`/`oneOf` as a union, `const` as a literal, and an object with only
    /// `additionalProperties` as a record. Anything else it can't describe accepts any value.
    init(jsonSchema schema: OpenUIValue) {
        var type = schema["type"]?.stringValue
        if case .array(let types)? = schema["type"] {
            let named = types.compactMap(\.stringValue).filter { $0 != "null" }
            type = named.count == 1 ? named[0] : nil
        }
        if case .array(let values)? = schema["enum"], !values.isEmpty {
            let strings = values.compactMap(\.stringValue)
            // An enum of other values keeps the type they share, so none of them is rejected.
            if strings.count == values.count {
                self = .enumeration(strings)
                return
            }
        }
        if let constant = schema["const"]?.stringValue {
            self = .literal(constant)
            return
        }
        if let options = (schema["anyOf"] ?? schema["oneOf"])?.arrayValue, !options.isEmpty {
            let types = options.filter { $0["type"]?.stringValue != "null" }.map(PropType.init(jsonSchema:))
            if types.count == 1 {
                self = types[0]
            } else {
                self = types.contains(.any) || types.isEmpty ? .any : .union(types)
            }
            return
        }
        switch type {
        case "string":
            self = .string
        case "number", "integer":
            self = .number
        case "boolean":
            self = .boolean
        case "array":
            self = .array(PropType(jsonSchema: schema["items"] ?? .null))
        case "object" where schema["properties"]?.objectValue?.isEmpty == false:
            self = .object(Self.fields(of: schema))
        case "object":
            if let values = schema["additionalProperties"], case .object = values {
                self = .record(PropType(jsonSchema: values))
            } else {
                self = .any
            }
        default:
            self = .any
        }
    }
}

@available(iOS 17.0, macOS 14.0, *)
extension PropType {
    /// The fields of a JSON Schema object in positional order, with their `default`s.
    static func fields(of schema: OpenUIValue) -> [PropField] {
        let required = Set((schema["required"]?.arrayValue ?? []).compactMap(\.stringValue))
        return ComponentSchema.orderedProperties(schema).map { name, property in
            let defaultValue = property["default"]
            return PropField(
                name,
                PropType(jsonSchema: property),
                isOptional: !required.contains(name) || defaultValue != nil,
                defaultValue: defaultValue
            )
        }
    }

    /// The type with `names` added to every union of content components in it, such as the
    /// children of a chat `Card`. A union is one of content when it holds `TextContent`.
    func addingContentComponents(_ names: [String]) -> PropType {
        switch kind {
        case .union(let options) where options.contains(.component("TextContent")):
            return .union(options + names.map(PropType.component).filter { !options.contains($0) })
        case .array(let items, let minItems):
            return .array(items.addingContentComponents(names), minItems: minItems)
        default:
            return self
        }
    }
}

@available(iOS 17.0, macOS 14.0, *)
extension ComponentLibrary {
    /// A library with `components` added, and placeable wherever the library's own content goes,
    /// such as the children of a chat `Card` or the content of a `TabItem`.
    /// - Parameters:
    ///   - group: The heading the components are listed under in the system prompt.
    ///   - notes: Guidance on using them, listed under the heading.
    ///
    /// A component is left out when the library already has one of that name, or its name can't
    /// be called in a program.
    func addingContent(_ components: [OpenUIComponentDefinition], group: String = "App components", notes: [String] = []) -> ComponentLibrary {
        let components = addable(components)
        guard !components.isEmpty else { return self }
        let names = components.map(\.name)
        let widened = self.components.map { definition -> OpenUIComponentDefinition in
            var schema = definition.schema
            schema.props = schema.props.map { field in
                var field = field
                field.type = field.type.addingContentComponents(names)
                return field
            }
            return OpenUIComponentDefinition(schema, renderer: definition.renderer)
        }
        return ComponentLibrary(
            root: root,
            components: widened + components,
            componentGroups: componentGroups + [ComponentGroup(name: group, components: names, notes: notes)],
            defaultPromptOptions: defaultPromptOptions,
            functions: functions,
            customActions: customActions
        )
    }
}

/// A portable component definition OpenUI can't read.
@available(iOS 17.0, macOS 14.0, *)
struct OpenUIPortableComponentError: Error, LocalizedError, Sendable {
    let message: String

    var errorDescription: String? { message }
}
