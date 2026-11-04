//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Schemas specific to the chat library (`openuiChatLibrary`).
@available(iOS 17.0, macOS 14.0, *)
enum ChatSchemas {
    static let card = ComponentSchema(
        "Card",
        description: "Vertical container for all content in a chat response. Children stack top to bottom automatically. Optional sources ([{ title, sourceName, url }]) render as a Sources strip at the bottom and back inline [n] citations in TextContent.",
        props: [
            .required("children", .array(.components(ContentUnions.chatNested + ["SectionBlock", "Tabs", "Carousel"]))),
            .optional("sources", .array(.object([.optional("url", .string), .required("title", .string), .required("sourceName", .string)])))
        ]
    )

    static let followUpBlock = ComponentSchema(
        "FollowUpBlock",
        description: "List of clickable follow-up suggestions placed at the end of a response",
        props: [
            .required("items", .array(.component("FollowUpItem")))
        ]
    )

    static let followUpItem = ComponentSchema(
        "FollowUpItem",
        description: "Clickable follow-up suggestion — when clicked, sends text as user message",
        props: [
            .required("text", .string)
        ]
    )

    static let sectionBlock = ComponentSchema(
        "SectionBlock",
        description: "Collapsible accordion sections. Auto-opens sections as they stream in. Use SectionItem for each section.",
        props: [
            .required("sections", .array(.component("SectionItem"))),
            .optional("isFoldable", .boolean)
        ]
    )

    static let sectionItem = ComponentSchema(
        "SectionItem",
        description: "Section with a label and collapsible content — used inside SectionBlock",
        props: [
            .required("value", .string),
            .required("trigger", .string),
            .required("content", .array(.components(ContentUnions.chatNested + ["Tabs", "Accordion"])))
        ]
    )

    static let tabItem = ComponentSchema(
        "TabItem",
        description: "value is unique id, trigger is tab label, content is array of components",
        props: [
            .required("value", .string),
            .required("trigger", .string),
            .required("content", .array(.components(ContentUnions.chatNested + ["Accordion"])))
        ]
    )

    static let accordionItem = ComponentSchema(
        "AccordionItem",
        description: "value is unique id, trigger is section title",
        props: [
            .required("value", .string),
            .required("trigger", .string),
            .required("content", .array(.components(ContentUnions.chatNested)))
        ]
    )

    static let carousel = ComponentSchema(
        "Carousel",
        description: "Horizontal scrollable carousel",
        props: [
            .required("children", .array(.array(.components(ContentUnions.chatNested)))),
            .optional("variant", .enumeration(["card", "sunk"]))
        ]
    )
}
