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

    // The most components a surface may expand to, counting a component once for each place it
    // shows, so a component listed as a child several times on each level can't build millions.
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
        guard expandedSize(limit: Self.maxExpandedComponents) <= Self.maxExpandedComponents else {
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

    // How many components the tree from the root expands to, up to `limit + 1`. A child that is
    // one of its own ancestors counts nothing, as it doesn't show.
    func expandedSize(limit: Int) -> Int {
        var sizes: [String: Int] = [:]
        var visiting: Set<String> = []
        func size(of componentId: String, depth: Int) -> Int {
            if let known = sizes[componentId] { return known }
            guard depth < maxDepth, !visiting.contains(componentId), let component = definition.component(componentId) else {
                return 0
            }
            visiting.insert(componentId)
            defer { visiting.remove(componentId) }
            let children = catalogs.resolveCatalog(entityCatalogId: component.catalogId, surfaceCatalogId: definition.catalogId)?
                .component(component.type)?
                .childReferences(of: component) ?? []
            var total = 1
            for child in children where total <= limit {
                total = min(total + size(of: child.id, depth: depth + 1), limit + 1)
            }
            sizes[componentId] = total
            return total
        }
        return size(of: A2UIProtocol.rootComponentId, depth: 0)
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
        if let first = ancestors.firstIndex(of: componentId) {
            report(RendererError(
                code: RendererError.Code.recursionLimitExceeded,
                message: "Component '\(componentId)' contains itself: "
                    + (ancestors[first...] + [componentId]).joined(separator: " > ") + ".",
                surfaceId: definition.surfaceId
            ))
            return AnyView(EmptyView())
        }
        let depth = ancestors.count
        guard depth < maxDepth else {
            let error = RendererError(
                code: RendererError.Code.recursionLimitExceeded,
                message: "Component nesting exceeded \(maxDepth) levels at '\(componentId)'.",
                surfaceId: definition.surfaceId
            )
            onError(error)
            return AnyView(EmptyView())
        }

        guard let component = definition.component(componentId) else {
            a2uiLogger.debug("Component '\(componentId)' is not defined yet on surface '\(definition.surfaceId)'.")
            return AnyView(EmptyView())
        }

        guard let catalog = catalogs.resolveCatalog(
            entityCatalogId: component.catalogId,
            surfaceCatalogId: definition.catalogId
        ) else {
            let error = RendererError(
                code: RendererError.Code.catalogNotFound,
                message: "Component '\(componentId)' of type '\(component.type)' has no catalog. "
                    + "Neither the component nor its surface names a catalog this renderer supports.",
                surfaceId: definition.surfaceId
            )
            onError(error)
            return AnyView(EmptyView())
        }
        guard let componentDefinition = catalog.component(component.type) else {
            a2uiLogger.debug("Component type '\(component.type)' is not defined by catalog '\(catalog.catalogId)'.")
            return AnyView(EmptyView())
        }

        // The processor reported this to the agent when the component arrived.
        guard CompositionValidator.allows(componentDefinition, in: parent) else {
            a2uiLogger.debug("Component '\(componentId)' (\(component.type)) is not allowed in '\(parent?.name ?? A2UIProtocol.surfaceComponentType)'.")
            return AnyView(EmptyView())
        }

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
