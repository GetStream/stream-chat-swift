//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// A component's description, the same on every platform and for the agent: its name, what it
/// shows, the parameters the agent fills in and the events it reports.
///
/// It reads and writes JSON, so one description can be shared by an app's iOS, Android and web
/// versions and by the agent's backend. Its parameters are a JSON Schema object, as a tool's
/// are, which keeps their order in `x-order`:
///
/// ```json
/// {
///   "name": "place_card",
///   "description": "A photo and a short summary of a place.",
///   "parameters": {
///     "type": "object",
///     "properties": { "title": { "type": "string", "description": "The place's Wikipedia title." } },
///     "required": ["title"],
///     "x-order": ["title"]
///   },
///   "events": [{ "name": "ask_about", "description": "The person asks about the place." }]
/// }
/// ```
public struct AIUIComponentDefinition: Codable, Equatable, Sendable {
    /// Something a component reports when the person uses it, such as tapping a place.
    public struct Event: Equatable, Sendable {
        /// The name it is reported by, such as `ask_about`.
        public var name: String
        /// When it happens, for the agent.
        public var description: String
        /// What it carries, in order.
        public var parameters: [AIUIParameter]

        public init(name: String, description: String, parameters: [AIUIParameter] = []) {
            self.name = name
            self.description = description
            self.parameters = parameters
        }
    }

    /// The name the agent places it by, such as `place_card`.
    public var name: String
    /// What it shows and when to use it, for the agent.
    public var description: String
    /// What the agent fills in, in order: a format such as OpenUI Lang passes arguments by
    /// position.
    public var parameters: [AIUIParameter]
    /// What it reports when the person uses it.
    public var events: [Event]

    public init(name: String, description: String, parameters: [AIUIParameter] = [], events: [Event] = []) {
        self.name = name
        self.description = description
        self.parameters = parameters
        self.events = events
    }

    /// The parameters as a JSON Schema object, the way a tool's are described.
    public var parametersSchema: [String: RawJSON] {
        AIUIParameter.objectSchema(parameters)
    }

    private enum CodingKeys: String, CodingKey {
        case name, description, parameters, events
    }

    private struct EventJSON: Codable {
        var name: String
        var description: String?
        var parameters: [String: RawJSON]?
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        let schema = try container.decodeIfPresent([String: RawJSON].self, forKey: .parameters) ?? [:]
        parameters = AIUIParameter.parameters(fromObjectSchema: schema)
        events = try (container.decodeIfPresent([EventJSON].self, forKey: .events) ?? []).map { event in
            Event(
                name: event.name,
                description: event.description ?? "",
                parameters: AIUIParameter.parameters(fromObjectSchema: event.parameters ?? [:])
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(parametersSchema, forKey: .parameters)
        let events = events.map { event in
            EventJSON(
                name: event.name,
                description: event.description,
                parameters: event.parameters.isEmpty ? nil : AIUIParameter.objectSchema(event.parameters)
            )
        }
        try container.encode(events, forKey: .events)
    }
}
