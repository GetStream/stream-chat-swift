//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Component content unions (mirrors `unions.ts`).
@available(iOS 17.0, macOS 14.0, *)
enum ContentUnions {
    /// Components allowed inside layout containers.
    static let base: [String] = [
        "TextContent",
        "MarkDownRenderer",
        "CardHeader",
        "Callout",
        "TextCallout",
        "CodeBlock",
        "Image",
        "ImageBlock",
        "ImageGallery",
        "Separator",
        "HorizontalBarChart",
        "RadarChart",
        "PieChart",
        "RadialChart",
        "SingleStackedBarChart",
        "ScatterChart",
        "AreaChart",
        "BarChart",
        "LineChart",
        "Table",
        "TagBlock",
        "Form",
        "Buttons",
        "IconButton",
        "Steps",
        "InlineHeader",
        "EntityList",
        "EditableTable",
        "SnippetCardBlock",
        "OverviewCardBlock",
        "ContextCardBlock",
        "CompositeCardBlock",
        "VisualCardBlock"
    ]

    /// Everything a nested chat container may hold.
    static let chatNested: [String] = base + ["ListBlock", "FollowUpBlock"]
}

@available(iOS 17.0, macOS 14.0, *)
extension PropType {
    /// A union of component references.
    static func components(_ names: [String]) -> PropType {
        .union(names.map(PropType.component))
    }

    /// Structured form validation rules: `{required: true, email: true, minLength: 8, ...}`.
    static let validationRules: PropType = .object([.optional("required", .boolean), .optional("email", .boolean), .optional("url", .boolean), .optional("numeric", .boolean), .optional("min", .number), .optional("max", .number), .optional("minLength", .number), .optional("maxLength", .number), .optional("pattern", .string)])
}

/// Schemas shared by the chat and standard libraries.
@available(iOS 17.0, macOS 14.0, *)
extension ComponentSchema {
    static let cardHeader = ComponentSchema(
        "CardHeader",
        description: "Header with optional title and subtitle",
        props: [
            .optional("title", .string),
            .optional("subtitle", .string)
        ]
    )

    static let textContent = ComponentSchema(
        "TextContent",
        description: "Text block. Supports markdown. Optional size: \"small\" | \"default\" | \"large\" | \"small-heavy\" | \"large-heavy\".",
        props: [
            .required("text", .string),
            .optional("size", .enumeration(["small", "default", "large", "small-heavy", "large-heavy"]))
        ]
    )

    static let markDownRenderer = ComponentSchema(
        "MarkDownRenderer",
        description: "Renders markdown text with optional container variant",
        props: [
            .required("textMarkdown", .string),
            .optional("variant", .enumeration(["clear", "card", "sunk"]))
        ]
    )

    static let callout = ComponentSchema(
        "Callout",
        description: "Callout banner. Optional visible is a reactive $boolean — auto-dismisses after 3s by setting $visible to false.",
        props: [
            .required("variant", .enumeration(["info", "warning", "error", "success", "neutral"])),
            .required("title", .string),
            .required("description", .string),
            .binding("visible", .boolean)
        ]
    )

    static let textCallout = ComponentSchema(
        "TextCallout",
        description: "Text callout with variant, title, and description",
        props: [
            .optional("variant", .enumeration(["neutral", "info", "warning", "success", "danger"])),
            .optional("title", .string),
            .optional("description", .string)
        ]
    )

    static let image = ComponentSchema(
        "Image",
        description: "Image with alt text and optional URL",
        props: [
            .required("alt", .string),
            .optional("src", .string)
        ]
    )

    static let imageBlock = ComponentSchema(
        "ImageBlock",
        description: "Image block with loading state",
        props: [
            .required("src", .string),
            .optional("alt", .string)
        ]
    )

    static let imageGallery = ComponentSchema(
        "ImageGallery",
        description: "Gallery grid of images with modal preview",
        props: [
            .required("images", .array(.object([.required("src", .string), .optional("alt", .string), .optional("details", .string)])))
        ]
    )

    static let codeBlock = ComponentSchema(
        "CodeBlock",
        description: "Syntax-highlighted code block",
        props: [
            .required("language", .string),
            .required("codeString", .string)
        ]
    )

    static let separator = ComponentSchema(
        "Separator",
        description: "Visual divider between content sections",
        props: [
            .optional("orientation", .enumeration(["horizontal", "vertical"])),
            .optional("decorative", .boolean)
        ]
    )

    static let table = ComponentSchema(
        "Table",
        description: "Data table — column-oriented. Each Col holds its own data array.",
        props: [
            .required("columns", .array(.component("Col")))
        ]
    )

    static let col = ComponentSchema(
        "Col",
        description: "Column definition — holds label + data array",
        props: [
            .required("label", .string),
            .required("data", .any),
            .optional("type", .enumeration(["string", "number", "action"]))
        ]
    )

    static let barChart = ComponentSchema(
        "BarChart",
        description: "Vertical bars; use for comparing values across categories with one or more series",
        props: [
            .required("labels", .array(.string)),
            .required("series", .array(.component("Series"))),
            .optional("variant", .enumeration(["grouped", "stacked"])),
            .optional("xLabel", .string),
            .optional("yLabel", .string),
            .optional("height", .number)
        ]
    )

    static let lineChart = ComponentSchema(
        "LineChart",
        description: "Lines over categories; use for trends and continuous data over time",
        props: [
            .required("labels", .array(.string)),
            .required("series", .array(.component("Series"))),
            .optional("variant", .enumeration(["linear", "natural", "step"])),
            .optional("xLabel", .string),
            .optional("yLabel", .string),
            .optional("height", .number)
        ]
    )

    static let areaChart = ComponentSchema(
        "AreaChart",
        description: "Filled area under lines; use for cumulative totals or volume trends over time",
        props: [
            .required("labels", .array(.string)),
            .required("series", .array(.component("Series"))),
            .optional("variant", .enumeration(["linear", "natural", "step"])),
            .optional("xLabel", .string),
            .optional("yLabel", .string),
            .optional("height", .number)
        ]
    )

    static let radarChart = ComponentSchema(
        "RadarChart",
        description: "Spider/web chart; use for comparing multiple variables across one or more entities",
        props: [
            .required("labels", .array(.string)),
            .required("series", .array(.component("Series")))
        ]
    )

    static let horizontalBarChart = ComponentSchema(
        "HorizontalBarChart",
        description: "Horizontal bars; prefer when category labels are long or for ranked lists",
        props: [
            .required("labels", .array(.string)),
            .required("series", .array(.component("Series"))),
            .optional("variant", .enumeration(["grouped", "stacked"])),
            .optional("xLabel", .string),
            .optional("yLabel", .string)
        ]
    )

    static let series = ComponentSchema(
        "Series",
        description: "One data series",
        props: [
            .required("category", .string),
            .required("values", .array(.number))
        ]
    )

    static let pieChart = ComponentSchema(
        "PieChart",
        description: "Circular slices; use plucked arrays: PieChart(data.categories, data.values)",
        props: [
            .required("labels", .array(.string)),
            .required("values", .array(.number)),
            .optional("variant", .enumeration(["pie", "donut"])),
            .optional("appearance", .enumeration(["circular", "semiCircular"]))
        ]
    )

    static let radialChart = ComponentSchema(
        "RadialChart",
        description: "Radial bars; use plucked arrays: RadialChart(data.categories, data.values)",
        props: [
            .required("labels", .array(.string)),
            .required("values", .array(.number))
        ]
    )

    static let singleStackedBarChart = ComponentSchema(
        "SingleStackedBarChart",
        description: "Single horizontal stacked bar; use plucked arrays: SingleStackedBarChart(data.categories, data.values)",
        props: [
            .required("labels", .array(.string)),
            .required("values", .array(.number))
        ]
    )

    static let slice = ComponentSchema(
        "Slice",
        description: "One slice with label and numeric value",
        props: [
            .required("category", .string),
            .required("value", .number)
        ]
    )

    static let scatterChart = ComponentSchema(
        "ScatterChart",
        description: "X/Y scatter plot; use for correlations, distributions, and clustering",
        props: [
            .required("datasets", .array(.component("ScatterSeries"))),
            .optional("xLabel", .string),
            .optional("yLabel", .string)
        ]
    )

    static let scatterSeries = ComponentSchema(
        "ScatterSeries",
        description: "Named dataset",
        props: [
            .required("name", .string),
            .required("points", .array(.component("Point")))
        ]
    )

    static let point = ComponentSchema(
        "Point",
        description: "Data point with numeric coordinates",
        props: [
            .required("x", .number),
            .required("y", .number),
            .optional("z", .number)
        ]
    )

    static let form = ComponentSchema(
        "Form",
        description: "Form container with fields and explicit action buttons",
        props: [
            .required("name", .string),
            .required("buttons", .component("Buttons")),
            .defaulted("fields", .array(.component("FormControl")), [])
        ]
    )

    static let formControl = ComponentSchema(
        "FormControl",
        description: "Field with label, input component, and optional hint text",
        props: [
            .required("label", .string),
            .required("input", .components(["Input", "TextArea", "Select", "DatePicker", "Slider", "CheckBoxGroup", "RadioGroup", "Chips", "OptionCards"])),
            .optional("hint", .string)
        ]
    )

    static let label = ComponentSchema(
        "Label",
        description: "Text label",
        props: [
            .required("text", .string)
        ]
    )

    static let input = ComponentSchema(
        "Input",
        description: "",
        props: [
            .required("name", .string),
            .optional("placeholder", .string),
            .optional("type", .enumeration(["text", "email", "password", "number", "url"])),
            .optional("rules", .validationRules),
            .binding("value", .string)
        ]
    )

    static let textArea = ComponentSchema(
        "TextArea",
        description: "",
        props: [
            .required("name", .string),
            .optional("placeholder", .string),
            .optional("rows", .number),
            .optional("rules", .validationRules),
            .binding("value", .string)
        ]
    )

    static let select = ComponentSchema(
        "Select",
        description: "",
        props: [
            .required("name", .string),
            .required("items", .array(.component("SelectItem"))),
            .optional("placeholder", .string),
            .optional("rules", .validationRules),
            .binding("value", .string),
            .optional("size", .enumeration(["small", "medium", "large"]))
        ]
    )

    static let selectItem = ComponentSchema(
        "SelectItem",
        description: "Option for Select",
        props: [
            .required("value", .string),
            .required("label", .string)
        ]
    )

    static let datePicker = ComponentSchema(
        "DatePicker",
        description: "",
        props: [
            .required("name", .string),
            .optional("mode", .enumeration(["single", "range"])),
            .optional("rules", .validationRules),
            .binding("value", .any)
        ]
    )

    static let slider = ComponentSchema(
        "Slider",
        description: "Numeric slider input; supports continuous and discrete (stepped) variants",
        props: [
            .required("name", .string),
            .required("variant", .enumeration(["continuous", "discrete"])),
            .required("min", .number),
            .required("max", .number),
            .optional("step", .number),
            .optional("defaultValue", .array(.number)),
            .optional("label", .string),
            .optional("rules", .validationRules),
            .binding("value", .array(.number))
        ]
    )

    static let checkBoxGroup = ComponentSchema(
        "CheckBoxGroup",
        description: "",
        props: [
            .required("name", .string),
            .required("items", .array(.component("CheckBoxItem"))),
            .optional("rules", .validationRules),
            .binding("value", .record(.boolean))
        ]
    )

    static let checkBoxItem = ComponentSchema(
        "CheckBoxItem",
        description: "",
        props: [
            .required("label", .string),
            .required("description", .string),
            .required("name", .string),
            .optional("defaultChecked", .boolean)
        ]
    )

    static let radioGroup = ComponentSchema(
        "RadioGroup",
        description: "",
        props: [
            .required("name", .string),
            .required("items", .array(.component("RadioItem"))),
            .optional("defaultValue", .string),
            .optional("rules", .validationRules),
            .binding("value", .string)
        ]
    )

    static let radioItem = ComponentSchema(
        "RadioItem",
        description: "",
        props: [
            .required("label", .string),
            .required("description", .string),
            .required("value", .string)
        ]
    )

    static let switchGroup = ComponentSchema(
        "SwitchGroup",
        description: "Group of switch toggles",
        props: [
            .required("name", .string),
            .required("items", .array(.component("SwitchItem"))),
            .optional("variant", .enumeration(["clear", "card", "sunk"])),
            .binding("value", .record(.boolean))
        ]
    )

    static let switchItem = ComponentSchema(
        "SwitchItem",
        description: "Individual switch toggle",
        props: [
            .optional("label", .string),
            .optional("description", .string),
            .required("name", .string),
            .optional("defaultChecked", .boolean)
        ]
    )

    static let button = ComponentSchema(
        "Button",
        description: "Clickable button",
        props: [
            .required("label", .string),
            .optional("action", .action),
            .optional("variant", .enumeration(["primary", "secondary", "tertiary"])),
            .optional("type", .enumeration(["normal", "destructive"])),
            .optional("size", .enumeration(["extra-small", "small", "medium", "large"]))
        ]
    )

    static let buttons = ComponentSchema(
        "Buttons",
        description: "Group of Button components. direction: \"row\" (default) | \"column\".",
        props: [
            .required("buttons", .array(.component("Button"))),
            .optional("direction", .enumeration(["row", "column"]))
        ]
    )

    static let listBlock = ComponentSchema(
        "ListBlock",
        description: "A list of items with number or image indicators. Each item can optionally have an action. size small renders a compact list.",
        props: [
            .required("items", .array(.component("ListItem"))),
            .optional("variant", .enumeration(["number", "image"])),
            .optional("size", .enumeration(["default", "small"]))
        ]
    )

    static let listItem = ComponentSchema(
        "ListItem",
        description: "Item in a ListBlock — displays a title with an optional subtitle and image. When action is provided, the item becomes clickable.",
        props: [
            .required("title", .string),
            .optional("subtitle", .string),
            .optional("image", .object([.required("src", .string), .required("alt", .string)])),
            .optional("actionLabel", .string),
            .optional("action", .action)
        ]
    )

    static let tabs = ComponentSchema(
        "Tabs",
        description: "Tabbed container",
        props: [
            .required("items", .array(.component("TabItem")))
        ]
    )

    static let accordion = ComponentSchema(
        "Accordion",
        description: "Collapsible sections",
        props: [
            .required("items", .array(.component("AccordionItem")))
        ]
    )

    static let steps = ComponentSchema(
        "Steps",
        description: "Step-by-step guide",
        props: [
            .required("items", .array(.component("StepsItem")))
        ]
    )

    static let stepsItem = ComponentSchema(
        "StepsItem",
        description: "title and details text for one step",
        props: [
            .required("title", .string),
            .required("details", .string)
        ]
    )

    static let tagBlock = ComponentSchema(
        "TagBlock",
        description: "tags is an array of strings; optional size sm | md | lg",
        props: [
            .required("tags", .array(.string)),
            .optional("size", .enumeration(["sm", "md", "lg"]))
        ]
    )

    static let tag = ComponentSchema(
        "Tag",
        description: "Styled tag/badge with optional Icon and variant",
        props: [
            .required("text", .string),
            .optional("icon", .component("Icon")),
            .optional("size", .enumeration(["sm", "md", "lg"])),
            .optional("variant", .enumeration(["neutral", "info", "success", "warning", "danger"]))
        ]
    )

    static let entityList = ComponentSchema(
        "EntityList",
        description: "Two-column key/value rows (left label, right value). size 'default' supports optional header and footer rows; rightVariant 'number' uses tabular numbers.",
        props: [
            .defaulted("rows", .array(.object([.required("left", .string), .required("right", .string), .defaulted("rightVariant", .enumeration(["text", "number"]), "text")])), []),
            .defaulted("size", .enumeration(["small", "default"]), "default"),
            .optional("header", .object([.required("left", .string), .required("right", .string), .defaulted("rightVariant", .enumeration(["text", "number"]), "text")])),
            .optional("footer", .object([.required("left", .string), .required("right", .string), .defaulted("rightVariant", .enumeration(["text", "number"]), "text")]))
        ]
    )

    static let inlineHeader = ComponentSchema(
        "InlineHeader",
        description: "Compact section heading with an optional one-line description, for use inside cards.",
        props: [
            .required("heading", .string),
            .optional("description", .string)
        ]
    )

    static let icon = ComponentSchema(
        "Icon",
        description: "A lucide icon by kebab-case name (e.g. 'circle-check'). Optional category picks a topical fallback when the name doesn't resolve.",
        props: [
            .required("name", .string),
            .optional("category", .string)
        ]
    )

    static let iconButton = ComponentSchema(
        "IconButton",
        description: "Icon-only button. name is the accessible label and the action label; icon is an Icon; action fires on click.",
        props: [
            .required("name", .string),
            .required("icon", .component("Icon")),
            .optional("action", .action),
            .optional("variant", .enumeration(["primary", "secondary", "tertiary"])),
            .optional("size", .enumeration(["extra-small", "small", "medium", "large"])),
            .optional("shape", .enumeration(["square", "circle"]))
        ]
    )

    static let editableTable = ComponentSchema(
        "EditableTable",
        description: "Spreadsheet-like table whose cells the user can edit inline (text, number, url, date, select columns); edits are saved back as a form field",
        props: [
            .defaulted("name", .string, ""),
            .defaulted("columns", .array(.object([.required("type", .enumeration(["text", "number", "date-single", "select", "url"])), .defaulted("key", .string, "default"), .defaulted("header", .string, ""), .optional("width", .number), .optional("options", .array(.object([.required("value", .string), .required("label", .string)])))])), []),
            .defaulted("data", .array(.object([.required("id", .string), .required("values", .array(.union([.string, .number])))])), [])
        ]
    )

    static let chipItem = ComponentSchema(
        "ChipItem",
        description: "A single selectable chip inside a Chips group, with a value, label and optional icon.",
        props: [
            .required("value", .string),
            .required("label", .string),
            .optional("icon", .component("Icon")),
            .optional("disabled", .boolean)
        ]
    )

    static let chips = ComponentSchema(
        "Chips",
        description: "A form field of compact selectable chips for choosing one or many short options; the selection is stored under `name`.",
        props: [
            .required("name", .string),
            .defaulted("type", .enumeration(["single", "multiple"]), "multiple"),
            .defaulted("items", .array(.component("ChipItem")), []),
            .optional("rules", .validationRules),
            .optional("defaultValue", .union([.string, .array(.string)]))
        ]
    )

    static let optionCard = ComponentSchema(
        "OptionCard",
        description: "A single selectable card inside an OptionCards group, with a value, title, optional subtitle and an optional Icon or Image on top.",
        props: [
            .required("value", .string),
            .required("title", .string),
            .optional("subtitle", .string),
            .optional("topContent", .components(["Icon", "Image"])),
            .optional("disabled", .boolean)
        ]
    )

    static let optionCards = ComponentSchema(
        "OptionCards",
        description: "A form field of selectable cards (title, optional subtitle, optional icon or image) laid out in a responsive grid for choosing one or many options; the selection is stored under `name`.",
        props: [
            .required("name", .string),
            .defaulted("type", .enumeration(["single", "multiple"]), "single"),
            .defaulted("items", .array(.component("OptionCard")), []),
            .optional("rules", .validationRules),
            .optional("defaultValue", .union([.string, .array(.string)]))
        ]
    )

    static let text = ComponentSchema(
        "Text",
        description: "Plain text line with optional subtext. variant 'number' uses tabular number styling; subtextVariant 'metric' colors a leading +/- subtext green/red.",
        props: [
            .defaulted("variant", .enumeration(["text", "number"]), "text"),
            .required("value", .string),
            .optional("subtext", .string),
            .defaulted("subtextVariant", .enumeration(["text", "number", "metric"]), "text"),
            .defaulted("size", .enumeration(["xs", "sm", "md", "lg"]), "sm")
        ]
    )

    static let boldText = ComponentSchema(
        "BoldText",
        description: "Emphasized (bold) text line with optional subtext. variant 'number' uses tabular number styling; subtextVariant 'metric' colors a leading +/- subtext green/red.",
        props: [
            .defaulted("variant", .enumeration(["text", "number"]), "text"),
            .required("value", .string),
            .optional("subtext", .string),
            .defaulted("subtextVariant", .enumeration(["text", "number", "metric"]), "text"),
            .defaulted("size", .enumeration(["xs", "sm", "md", "lg"]), "sm")
        ]
    )

    static let iconText = ComponentSchema(
        "IconText",
        description: "An icon badge with a title and optional subtitle, laid out horizontally or vertically. iconVariant sets the badge color.",
        props: [
            .required("icon", .component("Icon")),
            .defaulted("iconVariant", .enumeration(["neutral", "info", "success", "warning", "danger", "inverted", "filled", "soft"]), "neutral"),
            .defaulted("iconSize", .enumeration(["xs", "s", "m", "l", "xl", "sm", "md", "lg"]), "m"),
            .required("title", .string),
            .optional("subtitle", .string),
            .defaulted("bold", .boolean, false),
            .defaulted("layout", .enumeration(["horizontal", "vertical"]), "horizontal")
        ]
    )

    static let imageText = ComponentSchema(
        "ImageText",
        description: "A small square image (thumbnail/avatar) with a title and optional subtitle. src must be a real image URL.",
        props: [
            .required("src", .string),
            .optional("alt", .string),
            .required("title", .string),
            .optional("subtitle", .string),
            .defaulted("bold", .boolean, false),
            .defaulted("layout", .enumeration(["horizontal", "vertical"]), "horizontal"),
            .optional("imageSize", .number)
        ]
    )

    static let imageTextLarge = ComponentSchema(
        "ImageTextLarge",
        description: "A full-width banner image above a bold title and optional subtitle. src must be a real image URL.",
        props: [
            .required("src", .string),
            .optional("alt", .string),
            .required("title", .string),
            .optional("subtitle", .string),
            .defaulted("bold", .boolean, false)
        ]
    )

    static let metricIndicatorInline = ComponentSchema(
        "MetricIndicatorInline",
        description: "Headline metric value with an optional +/- percentage trend and subtext, all on one line.",
        props: [
            .required("value", .string),
            .optional("subtext", .string),
            .optional("trend", .object([.required("direction", .enumeration(["up", "down"])), .required("value", .number)]))
        ]
    )

    static let metricIndicatorWithStrikethrough = ComponentSchema(
        "MetricIndicatorWithStrikethrough",
        description: "Headline metric value with an optional struck-through previousValue, a +/- percentage trend, and subtext below.",
        props: [
            .required("value", .string),
            .optional("subtext", .string),
            .optional("previousValue", .string),
            .optional("trend", .object([.required("direction", .enumeration(["up", "down"])), .required("value", .number)]))
        ]
    )

    static let snippetCardItem = ComponentSchema(
        "SnippetCardItem",
        description: "One row-style snippet card: a label on the left (IconText or ImageText) and an optional value on the right (Text or BoldText).",
        props: [
            .optional("id", .string),
            .required("lhs", .components(["IconText", "ImageText"])),
            .optional("rhs", .components(["Text", "BoldText"]))
        ]
    )

    static let snippetCardBlock = ComponentSchema(
        "SnippetCardBlock",
        description: "A responsive grid of compact label/value cards (2 per row) for showing several short facts side by side; optionally clickable with a shared action.",
        props: [
            .required("items", .array(.component("SnippetCardItem"), minItems: 2)),
            .defaulted("layout", .enumeration(["grid"]), "grid"),
            .defaulted("responsive", .boolean, true),
            .optional("action", .action),
            .optional("gap", .union([.number, .string]))
        ]
    )

    static let overviewCardItem = ComponentSchema(
        "OverviewCardItem",
        description: "One overview card: a heading slot at the top (IconText, ImageText or Text) and an optional MetricIndicatorInline at the bottom.",
        props: [
            .optional("id", .string),
            .required("top", .components(["IconText", "ImageText", "Text"])),
            .optional("bottom", .component("MetricIndicatorInline"))
        ]
    )

    static let overviewCardBlock = ComponentSchema(
        "OverviewCardBlock",
        description: "A grid or horizontal carousel of compact overview cards, each with a heading (icon/image/text) on top and an inline metric below; optionally clickable with a shared action.",
        props: [
            .required("items", .array(.component("OverviewCardItem"), minItems: 2)),
            .defaulted("layout", .enumeration(["grid", "carousel"]), "grid"),
            .defaulted("responsive", .boolean, true),
            .optional("action", .action),
            .optional("gap", .union([.number, .string]))
        ]
    )

    static let contextCardItem = ComponentSchema(
        "ContextCardItem",
        description: "A single card inside a ContextCardBlock: a title (plain string or Tag), an optional markdown body, and an optional gray tint or background image.",
        props: [
            .optional("id", .string),
            .required("title", .union([.string, .component("Tag")])),
            .optional("body", .string),
            .optional("bgColor", .enumeration(["gray"])),
            .optional("bgImageSrc", .string),
            .optional("bgImageAlt", .string)
        ]
    )

    static let contextCardBlock = ComponentSchema(
        "ContextCardBlock",
        description: "A grid or carousel of compact tinted context cards (title or tag plus a short bold body); an optional action makes every card clickable.",
        props: [
            .required("items", .array(.component("ContextCardItem"), minItems: 2)),
            .defaulted("layout", .enumeration(["grid", "carousel"]), "grid"),
            .defaulted("responsive", .boolean, true),
            .optional("action", .action),
            .optional("gap", .union([.number, .string]))
        ]
    )

    static let compositeCardItem = ComponentSchema(
        "CompositeCardItem",
        description: "A single card inside a CompositeCardBlock: an optional header (icon/image/text), a stack of body elements (text, metrics, charts, lists, tags), and an optional price/button footer.",
        props: [
            .optional("id", .string),
            .optional("header", .components(["IconText", "ImageText", "ImageTextLarge", "Text", "Image"])),
            .defaulted("body", .array(.components(["Text", "BoldText", "MetricIndicatorInline", "IconText", "Image", "AreaChart", "BarChart", "LineChart", "ListBlock", "TagBlock", "EntityList"])), []),
            .optional("footer", .object([.optional("price", .components(["BoldText", "MetricIndicatorWithStrikethrough"])), .optional("button", .component("Button"))]))
        ]
    )

    static let compositeCardBlock = ComponentSchema(
        "CompositeCardBlock",
        description: "A two-per-row grid or carousel of rich cards, each with an optional header, stacked body content (text, metrics, charts, lists, tags) and a price/button footer; an optional action makes every card clickable.",
        props: [
            .required("items", .array(.component("CompositeCardItem"), minItems: 2)),
            .defaulted("layout", .enumeration(["grid", "carousel"]), "grid"),
            .defaulted("responsive", .boolean, true),
            .optional("action", .action),
            .optional("gap", .union([.number, .string]))
        ]
    )

    static let visualCardItem = ComponentSchema(
        "VisualCardItem",
        description: "A single photo-first card inside a VisualCardBlock: a BoldText body panel, an optional Tag, and a background image (bgImageSrc must be a real URL; bgImageAlt is its alt text).",
        props: [
            .required("body", .component("BoldText")),
            .optional("id", .string),
            .optional("bgImageSrc", .string),
            .optional("tag", .component("Tag")),
            .optional("bgImageAlt", .string)
        ]
    )

    static let visualCardBlock = ComponentSchema(
        "VisualCardBlock",
        description: "A grid or carousel of photo-first cards: a full-bleed background image with a tag on top and a bold text panel at the bottom; an optional action makes every card clickable.",
        props: [
            .required("items", .array(.component("VisualCardItem"), minItems: 2)),
            .defaulted("layout", .enumeration(["grid", "carousel"]), "grid"),
            .defaulted("responsive", .boolean, true),
            .optional("action", .action),
            .optional("gap", .union([.number, .string]))
        ]
    )
}
