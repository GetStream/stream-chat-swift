//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// A change to the set of rendered surfaces.
@available(iOS 15.0, macOS 12.0, *)
protocol A2UIUpdate {
    /// The surface the update refers to.
    var surfaceId: String { get }
}

/// Emitted when an agent creates a surface.
@available(iOS 15.0, macOS 12.0, *)
struct SurfaceAdded: A2UIUpdate {
    /// The surface that was created.
    let surfaceId: String

    /// The definition the surface was created with.
    let definition: SurfaceDefinition

    /// Creates a surface-added update.
    /// The definition may still be incomplete while streaming.
    init(surfaceId: String, definition: SurfaceDefinition) {
        self.surfaceId = surfaceId
        self.definition = definition
    }
}

/// Emitted when a surface's components or data change.
@available(iOS 15.0, macOS 12.0, *)
struct SurfaceUpdated: A2UIUpdate {
    /// The surface that changed.
    let surfaceId: String

    /// The definition after the change.
    let definition: SurfaceDefinition

    /// Creates a surface-updated update.
    init(surfaceId: String, definition: SurfaceDefinition) {
        self.surfaceId = surfaceId
        self.definition = definition
    }
}

/// Emitted when a surface is deleted.
@available(iOS 15.0, macOS 12.0, *)
struct SurfaceRemoved: A2UIUpdate {
    /// The surface that was removed.
    let surfaceId: String

    /// Creates a surface-removed update.
    init(surfaceId: String) {
        self.surfaceId = surfaceId
    }
}

/// The renderer-side host a ``A2UISurface`` binds to.
///
/// The host owns surface state, resolves catalogs and receives the events a
/// surface produces. ``A2UIMessageProcessor`` is the default implementation.
@available(iOS 15.0, macOS 12.0, *)
@MainActor
protocol A2UIHost: AnyObject {
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

@available(iOS 15.0, macOS 12.0, *)
extension A2UIHost {
    /// Creates a renderer for a surface definition.
    ///
    /// The renderer is cheap and stateless, so views create one per render pass
    /// with the current definition.
    func makeRenderer(for definition: SurfaceDefinition) -> SurfaceRenderer {
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
