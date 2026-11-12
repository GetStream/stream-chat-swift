//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

/// The layout components of the A2UI basic catalog.
@available(iOS 15.0, macOS 12.0, *)
enum LayoutComponents {
    /// All layout components, in catalog order.
    static var all: [ComponentDefinition] {
        [row, column, list, card, divider]
    }

    private static let justifyValues = [
        "center", "end", "spaceAround", "spaceBetween", "spaceEvenly", "start", "stretch"
    ]
    private static let alignValues = ["start", "center", "end", "stretch"]

    /// Arranges its children horizontally.
    static let row = ComponentDefinition(
        name: "Row",
        description: "A layout component that arranges its children horizontally. "
            + "To create a grid layout, nest Columns within this Row.",
        properties: [
            "children": JsonSchema.children(
                description: "Defines the children. Use an array of strings for a fixed set of children, "
                    + "or a template object to generate children from a data list. Children cannot be "
                    + "defined inline, they must be referred to by ID."
            ),
            "justify": JsonSchema.string(
                description: "Defines the arrangement of children along the main axis (horizontally).",
                enumValues: justifyValues,
                defaultValue: "start"
            ),
            "align": JsonSchema.string(
                description: "Defines the alignment of children along the cross axis (vertically).",
                enumValues: alignValues,
                defaultValue: "stretch"
            ),
            "weight": JsonSchema.weight()
        ],
        required: ["children"],
        examples: [
            """
            [
              {"id": "root", "component": "Row", "children": ["a", "b"], "justify": "spaceBetween"},
              {"id": "a", "component": "Text", "text": "Left"},
              {"id": "b", "component": "Text", "text": "Right"}
            ]
            """
        ]
    ) { context in
        AnyView(
            A2UIFlexStack(
                axis: .horizontal,
                justify: context.option("justify", default: "start"),
                align: context.option("align", default: "stretch"),
                children: context.resolvedChildren(),
                context: context
            )
        )
    }

    /// Arranges its children vertically.
    static let column = ComponentDefinition(
        name: "Column",
        description: "A layout component that arranges its children vertically. "
            + "To create a grid layout, nest Rows within this Column.",
        properties: [
            "children": JsonSchema.children(
                description: "Defines the children. Use an array of strings for a fixed set of children, "
                    + "or a template object to generate children from a data list. Children cannot be "
                    + "defined inline, they must be referred to by ID."
            ),
            "justify": JsonSchema.string(
                description: "Defines the arrangement of children along the main axis (vertically).",
                enumValues: justifyValues,
                defaultValue: "start"
            ),
            "align": JsonSchema.string(
                description: "Defines the alignment of children along the cross axis (horizontally).",
                enumValues: alignValues,
                defaultValue: "stretch"
            ),
            "weight": JsonSchema.weight()
        ],
        required: ["children"],
        examples: [
            """
            [
              {"id": "root", "component": "Column", "children": ["title", "body"], "align": "stretch"},
              {"id": "title", "component": "Text", "text": "### Title"},
              {"id": "body", "component": "Text", "text": "Body copy."}
            ]
            """
        ]
    ) { context in
        AnyView(
            A2UIFlexStack(
                axis: .vertical,
                justify: context.option("justify", default: "start"),
                align: context.option("align", default: "stretch"),
                children: context.resolvedChildren(),
                context: context
            )
        )
    }

    /// A list of components, laid out vertically or horizontally.
    ///
    /// Vertical lists deliberately do not add their own scroll view: agent UI
    /// is normally embedded in a scrollable host, and nesting scroll views
    /// collapses the layout. Horizontal lists scroll, because that direction is
    /// safe inside a vertical scroll view.
    static let list = ComponentDefinition(
        name: "List",
        description: "A list of components. Vertical lists grow with their content; horizontal lists scroll.",
        properties: [
            "children": JsonSchema.children(
                description: "Defines the children. Use an array of strings for a fixed set of children, "
                    + "or a template object to generate children from a data list."
            ),
            "direction": JsonSchema.string(
                description: "The direction in which the list items are laid out.",
                enumValues: ["vertical", "horizontal"],
                defaultValue: "vertical"
            ),
            "align": JsonSchema.string(
                description: "Defines the alignment of children along the cross axis.",
                enumValues: alignValues,
                defaultValue: "stretch"
            ),
            "weight": JsonSchema.weight()
        ],
        required: ["children"],
        examples: [
            """
            [
              {"id": "root", "component": "List", "children": {"componentId": "item", "path": "/items"}},
              {"id": "item", "component": "Text", "text": {"@path": "name"}}
            ]
            """
        ]
    ) { context in
        let isHorizontal = context.option("direction", default: "vertical") == "horizontal"
        let align = context.option("align", default: "stretch")
        let children = context.resolvedChildren()

        if isHorizontal {
            return AnyView(
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(alignment: A2UILayout.verticalAlignment(align), spacing: A2UILayout.spacing) {
                        ForEach(children) { child in
                            context.childView(child)
                        }
                    }
                }
            )
        }
        return AnyView(
            LazyVStack(alignment: A2UILayout.horizontalAlignment(align), spacing: A2UILayout.spacing) {
                ForEach(children) { child in
                    context.childView(child)
                        .frame(
                            maxWidth: align == "stretch" ? .infinity : nil,
                            alignment: A2UILayout.frameAlignment(align, axis: .vertical)
                        )
                }
            }
        )
    }

    /// A single child wrapped in card styling.
    static let card = ComponentDefinition(
        name: "Card",
        description: "A container with card-like styling.",
        properties: [
            "child": JsonSchema.child(
                description: "The ID of the single child component to be rendered inside the card. "
                    + "To display multiple elements, wrap them in a layout component and pass that "
                    + "container's ID here."
            ),
            "weight": JsonSchema.weight()
        ],
        required: ["child"],
        examples: [
            """
            [
              {"id": "root", "component": "Card", "child": "content"},
              {"id": "content", "component": "Text", "text": "Inside a card."}
            ]
            """
        ]
    ) { context in
        AnyView(A2UICardView(context: context))
    }

    /// A horizontal or vertical separator.
    static let divider = ComponentDefinition(
        name: "Divider",
        description: "A horizontal or vertical dividing line.",
        properties: [
            "axis": JsonSchema.string(
                description: "The orientation of the divider.",
                enumValues: ["horizontal", "vertical"],
                defaultValue: "horizontal"
            ),
            "weight": JsonSchema.weight()
        ],
        examples: [
            """
            [
              {"id": "root", "component": "Divider"}
            ]
            """
        ]
    ) { context in
        AnyView(A2UIDividerView(isVertical: context.option("axis", default: "horizontal") == "vertical"))
    }
}

@available(iOS 15.0, macOS 12.0, *)
private struct A2UICardView: View {
    let context: ComponentRenderContext

    @Environment(\.a2uiTheme) private var theme

    var body: some View {
        context.childView(context.childId())
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous))
    }
}

@available(iOS 15.0, macOS 12.0, *)
private struct A2UIDividerView: View {
    let isVertical: Bool

    @Environment(\.a2uiTheme) private var theme

    var body: some View {
        if isVertical {
            Rectangle()
                .fill(theme.border)
                .frame(width: 1)
                .frame(maxHeight: .infinity)
        } else {
            Divider().overlay(theme.border)
        }
    }
}
