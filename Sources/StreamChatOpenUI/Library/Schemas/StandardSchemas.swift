//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Schemas specific to the standard library (`openuiLibrary`).
@available(iOS 17.0, macOS 14.0, *)
enum StandardSchemas {
    static let card = ComponentSchema(
        "Card",
        description: "Styled container. variant: \"card\" (default, elevated) | \"sunk\" (recessed) | \"clear\" (transparent). Always full width. Accepts all Stack flex params (default: direction \"column\"). Cards flex to share space in row/wrap layouts.",
        props: [
            .required("children", .array(.components(ContentUnions.base + ["Tabs", "Carousel", "Stack"]))),
            .optional("variant", .enumeration(["card", "sunk", "clear"])),
            .optional("direction", .enumeration(["row", "column"])),
            .optional("gap", .enumeration(["none", "xs", "s", "m", "l", "xl", "2xl"])),
            .optional("align", .enumeration(["start", "center", "end", "stretch", "baseline"])),
            .optional("justify", .enumeration(["start", "center", "end", "between", "around", "evenly"])),
            .optional("wrap", .boolean)
        ]
    )

    static let stack = ComponentSchema(
        "Stack",
        description: "Flex container. direction: \"row\"|\"column\" (default \"column\"). gap: \"none\"|\"xs\"|\"s\"|\"m\"|\"l\"|\"xl\"|\"2xl\" (default \"m\"). align: \"start\"|\"center\"|\"end\"|\"stretch\"|\"baseline\". justify: \"start\"|\"center\"|\"end\"|\"between\"|\"around\"|\"evenly\".",
        props: [
            .required("children", .array(.any)),
            .optional("direction", .enumeration(["row", "column"])),
            .optional("gap", .enumeration(["none", "xs", "s", "m", "l", "xl", "2xl"])),
            .optional("align", .enumeration(["start", "center", "end", "stretch", "baseline"])),
            .optional("justify", .enumeration(["start", "center", "end", "between", "around", "evenly"])),
            .optional("wrap", .boolean)
        ]
    )

    static let tabItem = ComponentSchema(
        "TabItem",
        description: "value is unique id, trigger is tab label, content is array of components",
        props: [
            .required("value", .string),
            .required("trigger", .string),
            .required("content", .array(.components(ContentUnions.base)))
        ]
    )

    static let accordionItem = ComponentSchema(
        "AccordionItem",
        description: "value is unique id, trigger is section title",
        props: [
            .required("value", .string),
            .required("trigger", .string),
            .required("content", .array(.components(ContentUnions.base)))
        ]
    )

    static let carousel = ComponentSchema(
        "Carousel",
        description: "Horizontal scrollable carousel",
        props: [
            .required("children", .array(.array(.components(ContentUnions.base)))),
            .optional("variant", .enumeration(["card", "sunk"]))
        ]
    )

    static let modal = ComponentSchema(
        "Modal",
        description: "Modal dialog. open is a reactive $boolean binding — set to true to open, X/Escape/backdrop auto-closes. Put Form with buttons inside children.",
        props: [
            .required("title", .string),
            .binding("open", .boolean),
            .required("children", .array(.components(ContentUnions.base))),
            .optional("size", .enumeration(["sm", "md", "lg"]))
        ]
    )
}
