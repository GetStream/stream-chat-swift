//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI

/// Builds SwiftUI views for the components of one surface.
///
/// The renderer walks the adjacency list of a ``SurfaceDefinition`` starting at the
/// `root` component, resolves each component against the surface catalogs, and
/// applies the shared behaviour every component needs: composition validation,
/// accessibility attributes and action dispatch.
@available(iOS 15.0, macOS 12.0, *)
@MainActor
final class SurfaceRenderer {
    /// The maximum nesting depth.
    static let defaultMaxDepth = A2UIProtocol.maxNestingDepth

    // The most child views a surface may build, as `expandedSize` counts them, so a component
    // listed as a child several times on each level can't build millions.
    static let maxExpandedComponents = 5000

    /// The component tree being rendered.
    let definition: SurfaceDefinition

    /// The catalogs used to resolve component types.
    let catalogs: CatalogRegistry

    /// The evaluator used for properties, functions and checks.
    let evaluator: ExpressionEvaluator

    private let onAction: (RendererAction) -> Void
    private let onError: (RendererError) -> Void
    private let maxDepth: Int

    /// Creates a renderer for one surface definition.
    /// A new renderer is created whenever the definition changes.
    init(
        definition: SurfaceDefinition,
        catalogs: CatalogRegistry,
        evaluator: ExpressionEvaluator,
        onAction: @escaping (RendererAction) -> Void,
        onError: @escaping (RendererError) -> Void = { _ in },
        maxDepth: Int = SurfaceRenderer.defaultMaxDepth
    ) {
        self.definition = definition
        self.catalogs = catalogs
        self.evaluator = evaluator
        self.onAction = onAction
        self.onError = onError
        self.maxDepth = maxDepth
    }

    /// Looks up a component of the surface by id.
    /// Used by containers to read child metadata such as layout weight.
    func component(_ id: String) -> Component? {
        definition.component(id)
    }

    /// Builds the view for the surface's `root` component.
    /// Returns an empty view while the root has not arrived yet.
    func rootView(dataContext: DataContext) -> AnyView {
        guard definition.root != nil else {
            return AnyView(EmptyView())
        }
        guard expandedSize(limit: Self.maxExpandedComponents, dataContext: dataContext) <= Self.maxExpandedComponents else {
            report(RendererError(
                code: RendererError.Code.recursionLimitExceeded,
                message: "Surface '\(definition.surfaceId)' expands to more than \(Self.maxExpandedComponents) components. "
                    + "A component listed as a child more than once multiplies the components under it.",
                surfaceId: definition.surfaceId
            ))
            return AnyView(EmptyView())
        }
        return view(
            componentId: A2UIProtocol.rootComponentId,
            dataContext: dataContext,
            parent: nil,
            ancestors: []
        )
    }

    // How many child views the tree from the root builds, up to `limit + 1`: one for the root and
    // for each component listed as a child, whether or not it shows, one for each item of a
    // template whose child shows, and one for a template that builds nothing. Every tab of a
    // `Tabs` and a `Modal`'s content count, though they don't all show at once. The walk stops as
    // soon as the count passes `limit`, so it takes at most about `limit` steps, however long the
    // collections in the data model are.
    func expandedSize(limit: Int, dataContext: DataContext) -> Int {
        var knownReferences: [String: [(id: String, template: DataPath?)]] = [:]
        var ancestors: [String] = []
        var total = 0
        func references(of placed: Placement) -> [(id: String, template: DataPath?)] {
            if let known = knownReferences[placed.component.id] { return known }
            let found = placed.definition.children(of: placed.component).map { (id: $0.id, template: $0.template) }
            knownReferences[placed.component.id] = found
            return found
        }
        // Counts the view built for `componentId` as a child of `parent`, and the views under it
        // when it shows. Returns false once the count passes `limit`.
        func place(_ componentId: String, parent: ComponentDefinition?, in context: DataContext) -> Bool {
            total += 1
            guard total <= limit else { return false }
            guard let placed = placement(of: componentId, parent: parent, ancestors: ancestors, reports: false) else {
                return true
            }
            ancestors.append(componentId)
            defer { ancestors.removeLast() }
            for child in references(of: placed) {
                guard let path = child.template else {
                    guard place(child.id, parent: placed.definition, in: context) else { return false }
                    continue
                }
                // Like `resolvedChildren`, a template whose child doesn't show builds no items. It
                // still counts once, so a component holding many templates can't be walked for free.
                let shows = placement(of: child.id, parent: placed.definition, ancestors: ancestors, reports: false) != nil
                let count = shows ? Json.array(context.value(at: path))?.count ?? 0 : 0
                guard count > 0 else {
                    total += 1
                    guard total <= limit else { return false }
                    continue
                }
                for index in 0..<count {
                    guard place(child.id, parent: placed.definition, in: context.collectionScope(path: path, index: index)) else {
                        return false
                    }
                }
            }
            return true
        }
        _ = place(A2UIProtocol.rootComponentId, parent: nil, in: dataContext)
        return total
    }

    // A component `view` builds, with its catalog definition.
    struct Placement {
        let component: Component
        let definition: ComponentDefinition
    }

    // What `view` builds for `componentId` as a child of `parent`, or nil when it builds nothing,
    // reporting why when `reports` is set and that is a problem of the surface.
    func placement(
        of componentId: String,
        parent: ComponentDefinition?,
        ancestors: [String],
        reports: Bool
    ) -> Placement? {
        if let first = ancestors.firstIndex(of: componentId) {
            if reports {
                report(RendererError(
                    code: RendererError.Code.recursionLimitExceeded,
                    message: "Component '\(componentId)' contains itself: "
                        + (ancestors[first...] + [componentId]).joined(separator: " > ") + ".",
                    surfaceId: definition.surfaceId
                ))
            }
            return nil
        }
        guard ancestors.count < maxDepth else {
            if reports {
                report(RendererError(
                    code: RendererError.Code.recursionLimitExceeded,
                    message: "Component nesting exceeded \(maxDepth) levels at '\(componentId)'.",
                    surfaceId: definition.surfaceId
                ))
            }
            return nil
        }

        guard let component = definition.component(componentId) else {
            if reports {
                a2uiLogger.debug("Component '\(componentId)' is not defined yet on surface '\(definition.surfaceId)'.")
            }
            return nil
        }

        guard let catalog = catalogs.resolveCatalog(
            entityCatalogId: component.catalogId,
            surfaceCatalogId: definition.catalogId
        ) else {
            if reports {
                report(RendererError(
                    code: RendererError.Code.catalogNotFound,
                    message: "Component '\(componentId)' of type '\(component.type)' has no catalog. "
                        + "Neither the component nor its surface names a catalog this renderer supports.",
                    surfaceId: definition.surfaceId
                ))
            }
            return nil
        }
        guard let componentDefinition = catalog.component(component.type) else {
            if reports {
                a2uiLogger.debug("Component type '\(component.type)' is not defined by catalog '\(catalog.catalogId)'.")
            }
            return nil
        }

        // The processor reported this to the agent when the component arrived.
        guard CompositionValidator.allows(componentDefinition, in: parent) else {
            if reports {
                a2uiLogger.debug("Component '\(componentId)' (\(component.type)) is not allowed in '\(parent?.name ?? A2UIProtocol.surfaceComponentType)'.")
            }
            return nil
        }
        return Placement(component: component, definition: componentDefinition)
    }

    /// Builds the view for one component of the surface.
    ///
    /// Unknown ids and unknown component types render as empty views so that a
    /// partially streamed tree still displays, matching the progressive
    /// rendering behaviour required by the specification.
    func view(
        componentId: String,
        dataContext: DataContext,
        parent: ComponentDefinition?,
        ancestors: [String]
    ) -> AnyView {
        guard let placed = placement(of: componentId, parent: parent, ancestors: ancestors, reports: true) else {
            return AnyView(EmptyView())
        }
        let component = placed.component
        let componentDefinition = placed.definition

        let context = ComponentRenderContext(
            component: component,
            definition: componentDefinition,
            surfaceId: definition.surfaceId,
            dataContext: dataContext,
            evaluator: evaluator,
            renderer: self,
            ancestors: ancestors + [componentId]
        )

        if let hidden = evaluator.bool(component.accessibility?.hidden ?? .missing, in: dataContext), hidden {
            return AnyView(componentDefinition.builder(context).accessibilityHidden(true))
        }

        return AnyView(
            componentDefinition.builder(context)
                .modifier(accessibilityModifier(for: component, dataContext: dataContext))
        )
    }

    // A live component announces its explicit label, or else its text, whenever it changes.
    private func accessibilityModifier(for component: Component, dataContext: DataContext) -> AccessibilityAttributesModifier {
        let attributes = component.accessibility
        let label = evaluator.string(attributes?.label ?? .missing, in: dataContext).flatMap { $0.isEmpty ? nil : $0 }
        let live = attributes?.live ?? .off
        return AccessibilityAttributesModifier(
            label: label,
            hint: evaluator.string(attributes?.description ?? .missing, in: dataContext).flatMap { $0.isEmpty ? nil : $0 },
            live: live,
            announcement: live == .off ? nil : label ?? evaluator.string(component.dynamic("text"), in: dataContext),
            announce: evaluator.services.announce
        )
    }

    /// Performs an action triggered by a component.
    ///
    /// Event actions are resolved against the data model and handed to the
    /// host, while function actions are evaluated locally or routed to the
    /// agent by the evaluator.
    func perform(_ action: ActionDefinition, componentId: String, dataContext: DataContext) {
        switch action {
        case let .event(event):
            var context: JsonMap = [:]
            for (key, value) in event.context {
                context[key] = evaluator.evaluate(value, in: dataContext) ?? NSNull()
            }
            let rendererAction = RendererAction(
                name: event.name,
                userMessage: evaluator.string(event.userMessage, in: dataContext),
                surfaceId: definition.surfaceId,
                sourceComponentId: componentId,
                timestamp: evaluator.services.now(),
                context: context
            )
            a2uiLogger.debug("Dispatching action '\(event.name)' from '\(componentId)'.")
            onAction(rendererAction)
        case let .functionCall(call):
            a2uiLogger.debug("Invoking function '\(call.name)' from '\(componentId)'.")
            _ = evaluator.withUserActivation { evaluator.invoke(call, in: dataContext) }
        }
    }

    /// Reports a renderer-side error for this surface.
    /// Components use this for failures they detect while rendering.
    func report(_ error: RendererError) {
        onError(error)
    }
}

@available(iOS 15.0, macOS 12.0, *)
private struct AccessibilityAttributesModifier: ViewModifier {
    let label: String?
    let hint: String?
    let live: AccessibilityAttributes.Live
    let announcement: String?
    let announce: @MainActor @Sendable (String, AccessibilityAttributes.Live) -> Void

    func body(content: Content) -> some View {
        content
            .a2uiAccessibilityLabel(label)
            .a2uiAccessibilityHint(hint)
            .onChange(of: announcement) { text in
                guard let text, !text.isEmpty else { return }
                announce(text, live)
            }
    }
}

@available(iOS 15.0, macOS 12.0, *)
private extension View {
    @ViewBuilder
    func a2uiAccessibilityLabel(_ label: String?) -> some View {
        if let label {
            accessibilityLabel(Text(label))
        } else {
            self
        }
    }

    @ViewBuilder
    func a2uiAccessibilityHint(_ hint: String?) -> some View {
        if let hint {
            accessibilityHint(Text(hint))
        } else {
            self
        }
    }
}
