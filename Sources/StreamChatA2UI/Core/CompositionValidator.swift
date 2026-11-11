//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Validates component nesting against catalog composition constraints.
///
/// Catalogs may declare `allowedParents` and `allowedChildren` on component
/// definitions. The message processor checks them when components arrive and
/// reports `UNALLOWED_PARENT` or `UNALLOWED_CHILD` to the agent, pointing at
/// the component, or the child slot, of the message that broke the rule. The
/// renderer doesn't render a component placed where it isn't allowed.
@available(iOS 15.0, macOS 12.0, *)
enum CompositionValidator {
    /// Whether `child` may be placed inside `parent`.
    /// Pass `nil` for the surface root, whose parent is the reserved `Surface` container.
    static func allows(_ child: ComponentDefinition, in parent: ComponentDefinition?) -> Bool {
        let parentType = parent?.name ?? A2UIProtocol.surfaceComponentType
        if let allowedParents = child.allowedParents, !allowedParents.contains(parentType) {
            return false
        }
        if let parent, let allowedChildren = parent.allowedChildren, !allowedChildren.contains(child.name) {
            return false
        }
        return true
    }

    // Only the root is checked against `Surface`: a component nothing holds has no parent yet.
    static func errors(in surface: SurfaceDefinition, batch: [Component], catalogs: CatalogRegistry) -> [RendererError] {
        var batchIndex: [String: Int] = [:]
        for (index, component) in batch.enumerated() where batchIndex[component.id] == nil {
            batchIndex[component.id] = index
        }
        func definition(of component: Component) -> ComponentDefinition? {
            catalogs.resolveCatalog(entityCatalogId: component.catalogId, surfaceCatalogId: surface.catalogId)?
                .component(component.type)
        }

        var errors: [RendererError] = []
        let surfaceType = A2UIProtocol.surfaceComponentType
        if let root = surface.root, let index = batchIndex[root.id], let rootDefinition = definition(of: root),
           let allowedParents = rootDefinition.allowedParents, !allowedParents.contains(surfaceType) {
            errors.append(
                RendererError(
                    code: RendererError.Code.unallowedParent,
                    message: "Component '\(root.id)' (\(root.type)) cannot be placed under parent '\(surfaceType)' "
                        + "(\(surfaceType)). Allowed parents: \(list(allowedParents)).",
                    surfaceId: surface.surfaceId,
                    path: "/components/\(index)"
                )
            )
        }

        let parents = surface.components.values.sorted {
            (batchIndex[$0.id] ?? .max, $0.id) < (batchIndex[$1.id] ?? .max, $1.id)
        }
        for parent in parents {
            guard let parentDefinition = definition(of: parent) else { continue }
            for reference in parentDefinition.childReferences(of: parent) {
                guard let child = surface.component(reference.id), let childDefinition = definition(of: child) else { continue }
                let parentIndex = batchIndex[parent.id]
                let childIndex = batchIndex[child.id]
                guard parentIndex != nil || childIndex != nil else { continue }
                let slot = parentIndex.map { "/components/\($0)\(reference.pointer)" }
                let entry = childIndex.map { "/components/\($0)" }

                if let allowedParents = childDefinition.allowedParents, !allowedParents.contains(parent.type) {
                    errors.append(
                        RendererError(
                            code: RendererError.Code.unallowedParent,
                            message: "Component '\(child.id)' (\(child.type)) cannot be placed under parent "
                                + "'\(parent.id)' (\(parent.type)). Allowed parents: \(list(allowedParents)).",
                            surfaceId: surface.surfaceId,
                            path: entry ?? slot
                        )
                    )
                }
                if let allowedChildren = parentDefinition.allowedChildren, !allowedChildren.contains(child.type) {
                    errors.append(
                        RendererError(
                            code: RendererError.Code.unallowedChild,
                            message: "Container '\(parent.id)' (\(parent.type)) cannot contain child '\(child.id)' "
                                + "(\(child.type)). Allowed children: \(list(allowedChildren)).",
                            surfaceId: surface.surfaceId,
                            path: slot ?? entry
                        )
                    )
                }
            }
        }
        return errors
    }

    private static func list(_ names: [String]) -> String {
        "[" + names.map { "'\($0)'" }.joined(separator: ", ") + "]"
    }
}
