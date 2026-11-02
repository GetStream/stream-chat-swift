//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// A change to the set of rendered surfaces.
public protocol A2UIUpdate {
    /// The surface the update refers to.
    var surfaceId: String { get }
}

/// Emitted when an agent creates a surface.
public struct SurfaceAdded: A2UIUpdate {
    /// The surface that was created.
    public let surfaceId: String

    /// The definition the surface was created with.
    public let definition: UiDefinition

    /// Creates a surface-added update.
    /// The definition may still be incomplete while streaming.
    public init(surfaceId: String, definition: UiDefinition) {
        self.surfaceId = surfaceId
        self.definition = definition
    }
}

/// Emitted when a surface's components or data change.
public struct SurfaceUpdated: A2UIUpdate {
    /// The surface that changed.
    public let surfaceId: String

    /// The definition after the change.
    public let definition: UiDefinition

    /// Creates a surface-updated update.
    public init(surfaceId: String, definition: UiDefinition) {
        self.surfaceId = surfaceId
        self.definition = definition
    }
}

/// Emitted when a surface is deleted.
public struct SurfaceRemoved: A2UIUpdate {
    /// The surface that was removed.
    public let surfaceId: String

    /// Creates a surface-removed update.
    public init(surfaceId: String) {
        self.surfaceId = surfaceId
    }
}

/// The renderer-side host a ``A2UISurface`` binds to.
///
/// The host owns surface state, resolves catalogs and receives the events a
/// surface produces. ``A2UIMessageProcessor`` is the default implementation.
@MainActor
public protocol A2UIHost: AnyObject {
    /// The catalogs this host can render.
    var catalogs: CatalogRegistry { get }

    /// Host capabilities passed to components and functions.
    var services: RendererServices { get }

    /// A stream of surface lifecycle changes.
    var surfaceUpdates: AnyPublisher<A2UIUpdate, Never> { get }

    /// Returns the observable state of a surface, creating it if needed.
    /// Views call this to bind before the surface exists.
    func surfaceViewModel(_ surfaceId: String) -> SurfaceViewModel

    /// Handles a user action produced by a surface.
    /// Implementations forward it to the agent.
    func handle(_ action: RendererAction)

    /// Handles a renderer-side error produced while rendering.
    /// Implementations report it to the agent.
    func report(_ error: RendererError)
}

public extension A2UIHost {
    /// Creates a renderer for a surface definition.
    ///
    /// The renderer is cheap and stateless, so views create one per render pass
    /// with the current definition.
    func makeRenderer(for definition: UiDefinition) -> SurfaceRenderer {
        let evaluator = ExpressionEvaluator(
            catalogs: catalogs,
            surfaceId: definition.surfaceId,
            surfaceCatalogId: definition.catalogId,
            services: services,
            remoteRouter: self as? RemoteFunctionRouter
        )
        return SurfaceRenderer(
            definition: definition,
            catalogs: catalogs,
            evaluator: evaluator,
            onAction: { [weak self] action in self?.handle(action) },
            onError: { [weak self] error in self?.report(error) }
        )
    }
}
