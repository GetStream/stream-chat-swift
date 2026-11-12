//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// The A2UI v1.0 basic catalog, implemented in SwiftUI.
///
/// The basic catalog is the baseline set of components and functions every A2UI
/// renderer is expected to support. `A2UIRenderer` writes with it by default. To change how
/// one of its components looks, replace that component's view:
///
/// ```swift
/// let catalog = BasicCatalog.catalog.replacingView(of: "Card") { context in
///     AnyView(BrandCard { context.childView(context.childId()) })
/// }
/// A2UIRenderer(catalog: catalog)
/// ```
@available(iOS 15.0, macOS 12.0, *)
public enum BasicCatalog {
    /// The catalog id agents use to target the basic catalog.
    public static let catalogId = basicCatalogId

    /// Every component of the basic catalog.
    static var components: [ComponentDefinition] {
        TextComponents.all
            + MediaComponents.all
            + LayoutComponents.all
            + ContainerComponents.all
            + ButtonComponent.all
            + InputComponents.all
    }

    /// Every function of the basic catalog.
    static var functions: [FunctionDefinition] {
        ValidationFunctions.all + FormatFunctions.all + ActionFunctions.all + LogicFunctions.all
    }

    /// Design guidance sent to agents that generate for this catalog.
    static let instructions = """
    For layout, use the Row and Column components to organize other components.

    ## Catalog Guidelines

    1. String Concatenation & Formatting: A2UI does not support binary operators like '+' or formatting \
    symbols. To concatenate strings or dynamically inject data bindings into text, you must use the catalog \
    function `formatString(value)` where the value string contains placeholders formatted as `${expression}`:
       formatString("Hello ${/user/name}")

    2. Strict Hierarchy: You must strictly adhere to the requested component nesting and hierarchy. If the \
    prompt specifies that a component is 'inside' or 'contained in' another component, you MUST place it as \
    a child of that specific component, not as a sibling or in a different container.

    3. Validation Checks: When components support validation checks, specify any custom error messages \
    directly as the 'message' inside the check. Do NOT create separate text-display components to display \
    validation errors.

    4. Text Hierarchy: The Text component only offers the 'body' and 'caption' variants. Use Markdown \
    headings ('#' to '####') inside the text for visual hierarchy.

    5. Component Ids: Every surface must contain exactly one component with the id 'root'. Children are \
    always referenced by id; components are never nested inline.
    """

    /// The basic catalog.
    public static var catalog: Catalog {
        Catalog(
            catalogId: catalogId,
            title: "A2UI Basic Catalog",
            description: "Unified catalog of basic A2UI components and functions.",
            instructions: instructions,
            components: components,
            functions: functions
        )
    }
}
