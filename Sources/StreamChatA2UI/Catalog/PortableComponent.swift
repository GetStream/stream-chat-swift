//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Components an app describes once for every platform and for its agent, as A2UI components.
///
/// A portable definition has a snake_case `name`, a `description`, `parameters` as a JSON Schema
/// object, and the `events` the component reports:
///
/// ```json
/// { "name": "place_card", "description": "A photo and a short summary of a place.",
///   "parameters": { "type": "object", "properties": { "title": { "type": "string" } },
///                   "required": ["title"] },
///   "events": [{ "name": "ask_about", "description": "Tapping it asks about the place." }] }
/// ```
@available(iOS 15.0, macOS 12.0, *)
enum PortableComponent {
    /// The A2UI type of a portable component, named as the basic catalog names its own:
    /// `place_card` is `PlaceCard`.
    static func typeName(_ name: String) -> String {
        name.split(whereSeparator: { $0 == "_" || $0 == "-" || $0 == " " })
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined()
    }

    /// The catalog entry of a portable component, which `builder` renders.
    ///
    /// Its parameters are its properties, each described in its own schema. What its events do
    /// joins its description: the component reports them itself, rather than through an A2UI
    /// `action` the agent writes.
    static func definition(_ portable: JsonMap, builder: @escaping ComponentViewBuilder) throws -> ComponentDefinition {
        guard let name = portable["name"] as? String, !name.isEmpty else {
            throw PortableComponentError(message: "A component definition needs a name")
        }
        let type = typeName(name)
        guard A2UIIdentifier.isValid(type), type != A2UIProtocol.surfaceComponentType else {
            throw PortableComponentError(
                message: "The component name '\(name)' must be a Unicode identifier (UAX #31) other than 'Surface'"
            )
        }
        let parameters = Json.map(portable["parameters"]) ?? [:]
        let properties = (Json.map(parameters["properties"]) ?? [:]).compactMapValues(Json.map)
        if let property = properties.keys.sorted().first(where: { !A2UIIdentifier.isValid($0) }) {
            throw PortableComponentError(
                message: "The parameter '\(property)' of '\(name)' must be a Unicode identifier (UAX #31)"
            )
        }
        var notes: [String] = []
        if let description = portable["description"] as? String, !description.isEmpty {
            notes.append(sentence(description))
        }
        for event in Json.array(portable["events"]) ?? [] {
            if let description = Json.map(event)?["description"] as? String, !description.isEmpty {
                notes.append(sentence(description))
            }
        }
        return ComponentDefinition(
            name: type,
            description: notes.joined(separator: " "),
            properties: properties,
            required: Json.stringArray(parameters["required"]) ?? [],
            builder: builder
        )
    }

    private static func sentence(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard let last = trimmed.last, !".!?".contains(last) else { return trimmed }
        return trimmed + "."
    }
}

/// A portable component definition A2UI can't read.
@available(iOS 15.0, macOS 12.0, *)
struct PortableComponentError: Error, LocalizedError, Sendable {
    let message: String

    init(message: String) {
        self.message = message
    }

    var errorDescription: String? { message }
}
