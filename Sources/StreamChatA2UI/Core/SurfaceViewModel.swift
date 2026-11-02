//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// The observable state of one rendered surface.
///
/// A surface has two sources of change: its component tree, replaced by
/// `updateComponents` messages, and its data model, written both by
/// `updateDataModel` messages and by the user through input components.
/// SwiftUI observes this object and re-evaluates the surface when either
/// changes.
///
/// Instances must be used from the main thread, which is where the message
/// processor applies updates.
@MainActor
public final class SurfaceViewModel: ObservableObject {
    /// The surface this view model represents.
    public let surfaceId: String

    /// The data model backing the surface.
    public let dataModel: DataModel

    /// The current component tree, or `nil` before the surface was created.
    @Published public private(set) var definition: UiDefinition?

    /// A counter bumped whenever the surface's data changes.
    ///
    /// SwiftUI uses it to re-evaluate bindings and function calls, which may
    /// depend on any number of data model paths.
    @Published public private(set) var revision: Int = 0

    /// Creates a view model for a surface that has not been created yet.
    /// The surface renders its placeholder until a definition arrives.
    public init(surfaceId: String, dataModel: DataModel = DataModel()) {
        self.surfaceId = surfaceId
        self.dataModel = dataModel
        _ = dataModel.observe { [weak self] _ in
            self?.revision += 1
        }
    }

    /// Whether the surface has a root component and can be rendered.
    public var isRenderable: Bool {
        definition?.isRenderable ?? false
    }

    /// Installs the definition created by a `createSurface` message.
    /// Replaces any previous definition for this surface.
    public func create(definition: UiDefinition, dataModel initialData: JsonMap?) {
        if let initialData {
            dataModel.replaceAll(with: initialData)
        }
        self.definition = definition
    }

    /// Merges components delivered by an `updateComponents` message.
    /// Components arriving before the surface was created are ignored.
    public func merge(components: [Component]) {
        guard let current = definition else {
            a2uiLogger.warning("Ignoring components for surface '\(surfaceId)' because it was not created yet.")
            return
        }
        definition = current.merging(components)
    }

    /// Applies a data model update.
    /// Observers are notified through ``revision``.
    public func update(path: DataPath, value: (any Sendable)?) {
        dataModel.update(at: path, value: value)
    }

    /// Clears the surface after it was deleted.
    /// Views still bound to it show their placeholder again.
    public func reset() {
        definition = nil
        dataModel.replaceAll(with: [:])
    }

    /// Forces observers to re-evaluate the surface.
    /// Used when an asynchronous function result becomes available.
    public func touch() {
        revision += 1
    }
}
