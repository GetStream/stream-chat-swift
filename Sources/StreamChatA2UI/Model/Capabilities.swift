//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// The catalogs and features a renderer supports.
///
/// Sent to the agent in transport metadata (for A2A, under the
/// `a2uiRendererCapabilities` key of every outgoing message) so the agent knows
/// which components and functions it may generate.
public struct RendererCapabilities: Equatable {
    /// The ids of the catalogs this renderer can render.
    public let supportedCatalogIds: [String]

    /// Full catalog definitions provided inline by the renderer.
    ///
    /// Only send these when the agent advertises `acceptsInlineCatalogs`.
    public let inlineCatalogs: [JsonMap]

    /// Creates a renderer capabilities payload.
    /// Inline catalogs let an app expose its own design system to the agent.
    public init(supportedCatalogIds: [String], inlineCatalogs: [JsonMap] = []) {
        self.supportedCatalogIds = supportedCatalogIds
        self.inlineCatalogs = inlineCatalogs
    }

    /// The serialized wire representation, keyed by protocol version.
    public func toJson() -> JsonMap {
        var payload: JsonMap = ["supportedCatalogIds": supportedCatalogIds]
        if !inlineCatalogs.isEmpty {
            payload["inlineCatalogs"] = inlineCatalogs
        }
        return [A2UIProtocol.version: payload]
    }

    /// Parses a renderer capabilities payload.
    /// Returns `nil` when the payload does not describe this protocol version.
    public static func fromJson(_ json: JsonMap) -> RendererCapabilities? {
        guard let payload = Json.map(json[A2UIProtocol.version]),
              let ids = Json.stringArray(payload["supportedCatalogIds"]) else {
            return nil
        }
        let inline = (Json.array(payload["inlineCatalogs"]) ?? []).compactMap { Json.map($0) }
        return RendererCapabilities(supportedCatalogIds: ids, inlineCatalogs: inline)
    }

    /// Compares two capability payloads.
    public static func == (lhs: RendererCapabilities, rhs: RendererCapabilities) -> Bool {
        lhs.supportedCatalogIds == rhs.supportedCatalogIds
            && Json.isEqual(lhs.inlineCatalogs, rhs.inlineCatalogs)
    }
}

/// The A2UI features an agent advertises, usually through its agent card.
public struct AgentCapabilities: Equatable {
    /// The catalogs the agent can generate content for.
    public let supportedCatalogIds: [String]

    /// Whether the agent accepts inline catalog definitions from the renderer.
    public let acceptsInlineCatalogs: Bool

    /// Creates an agent capabilities payload.
    /// Agents advertise this in the A2UI extension params of their agent card.
    public init(supportedCatalogIds: [String], acceptsInlineCatalogs: Bool = false) {
        self.supportedCatalogIds = supportedCatalogIds
        self.acceptsInlineCatalogs = acceptsInlineCatalogs
    }

    /// The serialized wire representation, keyed by protocol version.
    public func toJson() -> JsonMap {
        [
            A2UIProtocol.version: [
                "supportedCatalogIds": supportedCatalogIds,
                "acceptsInlineCatalogs": acceptsInlineCatalogs
            ] as JsonMap
        ]
    }

    /// Parses an agent capabilities payload.
    /// Accepts both the versioned wrapper and a bare params object.
    public static func fromJson(_ json: JsonMap) -> AgentCapabilities? {
        let payload = Json.map(json[A2UIProtocol.version]) ?? json
        guard let ids = Json.stringArray(payload["supportedCatalogIds"]) else { return nil }
        return AgentCapabilities(
            supportedCatalogIds: ids,
            acceptsInlineCatalogs: Json.bool(payload["acceptsInlineCatalogs"]) ?? false
        )
    }
}

/// A snapshot of the data models of all surfaces that opted into synchronization.
public struct RendererDataModel: Equatable {
    /// The current data model of each surface, keyed by surface id.
    public let surfaces: [String: JsonMap]

    /// Creates a data model snapshot.
    /// Only surfaces created with `sendDataModel` should be included.
    public init(surfaces: [String: JsonMap]) {
        self.surfaces = surfaces
    }

    /// Whether the snapshot contains any surfaces.
    public var isEmpty: Bool {
        surfaces.isEmpty
    }

    /// The serialized wire representation of the snapshot.
    public func toJson() -> JsonMap {
        [A2UIProtocol.versionKey: A2UIProtocol.version, "surfaces": surfaces]
    }

    /// Parses a data model snapshot.
    /// Returns `nil` when the payload is not a v1.0 snapshot.
    public static func fromJson(_ json: JsonMap) -> RendererDataModel? {
        guard let surfaces = Json.map(json["surfaces"]) else { return nil }
        return RendererDataModel(surfaces: surfaces.compactMapValues { Json.map($0) })
    }

    /// Compares two snapshots structurally.
    public static func == (lhs: RendererDataModel, rhs: RendererDataModel) -> Bool {
        Json.isEqual(lhs.surfaces, rhs.surfaces)
    }
}
