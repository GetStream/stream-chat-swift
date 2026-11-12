//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// The component-tree state of a single surface.
///
/// A definition is created by a `createSurface` message and then refined by any
/// number of `updateComponents` messages. Components are stored by id so that
/// out-of-order and partial updates can be applied while streaming.
@available(iOS 15.0, macOS 12.0, *)
struct SurfaceDefinition: Equatable {
    /// The id of the surface this definition belongs to.
    let surfaceId: String

    /// The default catalog used to resolve components and functions.
    let catalogId: String?

    /// Whether the renderer sends this surface's data model to the agent.
    let sendDataModel: Bool

    /// Surface-level extension metadata.
    let metadata: JsonMap?

    /// All known components of the surface, keyed by id.
    private(set) var components: [String: Component]

    /// Creates a surface definition.
    /// Components may be empty while the agent is still streaming.
    init(
        surfaceId: String,
        catalogId: String? = nil,
        sendDataModel: Bool = false,
        metadata: JsonMap? = nil,
        components: [String: Component] = [:]
    ) {
        self.surfaceId = surfaceId
        self.catalogId = catalogId
        self.sendDataModel = sendDataModel
        self.metadata = metadata
        self.components = components
    }

    /// The root component of the surface, if it has arrived.
    var root: Component? {
        components[A2UIProtocol.rootComponentId]
    }

    /// Whether the surface can be rendered.
    /// A surface renders once its `root` component is known.
    var isRenderable: Bool {
        root != nil
    }

    /// Looks up a component by id.
    /// Returns `nil` for dangling references, which the renderer skips.
    func component(_ id: String) -> Component? {
        components[id]
    }

    /// Adds or replaces components.
    /// Existing components with the same id are overwritten.
    mutating func merge(_ newComponents: [Component]) {
        for component in newComponents {
            components[component.id] = component
        }
    }

    /// Returns a copy with additional components merged in.
    /// Use this to keep definitions immutable in observable state.
    func merging(_ newComponents: [Component]) -> SurfaceDefinition {
        var copy = self
        copy.merge(newComponents)
        return copy
    }

    /// The serialized wire representation of the surface.
    func toJson() -> JsonMap {
        var json: JsonMap = [
            surfaceIdKey: surfaceId,
            "components": components.keys.sorted().compactMap { components[$0]?.toJson() }
        ]
        if let catalogId { json["catalogId"] = catalogId }
        if sendDataModel { json["sendDataModel"] = true }
        if let metadata { json["metadata"] = metadata }
        return json
    }

    /// A textual description of the surface for conversation history.
    /// Agents use this to understand what the user is currently looking at.
    func asContextDescriptionText() -> String {
        let text = Json.encodeToString(toJson(), pretty: true) ?? "{}"
        return "A user interface is shown with the following content:\n\(text)."
    }

    /// Compares two definitions by surface metadata and components.
    static func == (lhs: SurfaceDefinition, rhs: SurfaceDefinition) -> Bool {
        lhs.surfaceId == rhs.surfaceId
            && lhs.catalogId == rhs.catalogId
            && lhs.sendDataModel == rhs.sendDataModel
            && lhs.components == rhs.components
    }
}
