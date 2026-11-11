//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

/// Renders one agent-driven surface.
///
/// The view binds to the host's state for `surfaceId` and rebuilds whenever the
/// surface's components or data change. Before the agent creates the surface,
/// or while its `root` component has not arrived yet, the placeholder is shown.
///
/// ```swift
/// A2UISurface(host: conversation.host, surfaceId: "main") {
///     ProgressView()
/// }
/// ```
@available(iOS 15.0, macOS 12.0, *)
struct A2UISurface<Placeholder: View>: View {
    private let host: A2UIHost
    private let placeholder: Placeholder

    /// The surface being rendered.
    let surfaceId: String

    @ObservedObject private var viewModel: SurfaceViewModel

    /// Creates a surface view bound to a host.
    /// The placeholder shows while the surface is empty.
    init(host: A2UIHost, surfaceId: String, @ViewBuilder placeholder: () -> Placeholder) {
        self.host = host
        self.surfaceId = surfaceId
        self.placeholder = placeholder()
        self.viewModel = host.surfaceViewModel(surfaceId)
    }

    @Environment(\.a2uiTheme) private var theme

    var body: some View {
        // `revision` is read so SwiftUI re-evaluates bindings and function
        // calls whenever the surface's data model changes.
        content(revision: viewModel.revision)
            .foregroundColor(theme.text)
    }

    @ViewBuilder
    private func content(revision _: Int) -> some View {
        if let definition = viewModel.definition, definition.isRenderable {
            host.makeRenderer(for: definition)
                .rootView(dataContext: DataContext(viewModel.dataModel, "/"))
        } else {
            placeholder
        }
    }
}

@available(iOS 15.0, macOS 12.0, *)
extension A2UISurface where Placeholder == EmptyView {
    /// Creates a surface view that shows nothing while the surface is empty.
    init(host: A2UIHost, surfaceId: String) {
        self.init(host: host, surfaceId: surfaceId) { EmptyView() }
    }
}
