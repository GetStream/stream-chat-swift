//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

@available(iOS 17.0, macOS 14.0, *)
public extension ComponentLibrary {
    /// The chat library (`openuiChatLibrary`): every response is a single vertical `Card`.
    /// Use it for assistant messages in a conversation.
    static let openUIChat = ComponentLibrary(
        root: ChatLibraryDefinition.root,
        components: ChatLibraryDefinition.schemas.map { schema in
            OpenUIComponentDefinition(schema, renderer: BuiltInRenderers.renderer(for: schema.name, library: .chat))
        },
        componentGroups: ChatLibraryDefinition.componentGroups,
        defaultPromptOptions: PromptOptions(
            additionalRules: ChatLibraryDefinition.additionalRules,
            examples: ChatLibraryDefinition.examples
        )
    )

    /// The standard library (`openuiLibrary`): `Stack` root with flexible layouts, modals and cards.
    /// Use it for full-screen generative surfaces such as dashboards.
    static let openUI = ComponentLibrary(
        root: StandardLibraryDefinition.root,
        components: StandardLibraryDefinition.schemas.map { schema in
            OpenUIComponentDefinition(schema, renderer: BuiltInRenderers.renderer(for: schema.name, library: .standard))
        },
        componentGroups: StandardLibraryDefinition.componentGroups,
        defaultPromptOptions: PromptOptions(
            additionalRules: StandardLibraryDefinition.additionalRules,
            examples: StandardLibraryDefinition.examples
        )
    )
}

/// Registry of the built-in SwiftUI renderers.
@available(iOS 17.0, macOS 14.0, *)
enum BuiltInRenderers {
    enum Flavor {
        case chat
        case standard
    }

    static func renderer(for name: String, library: Flavor) -> ComponentRenderer? {
        if library == .chat, let renderer = chatOverrides[name] { return renderer }
        if library == .standard, let renderer = standardOverrides[name] { return renderer }
        return shared[name]
    }

    static func make<Content: View>(@ViewBuilder _ view: @escaping @MainActor @Sendable (ComponentContext) -> Content) -> ComponentRenderer {
        { context in AnyView(view(context)) }
    }

    /// Renderers shared by both libraries.
    static let shared: [String: ComponentRenderer] = [
        // Content
        "CardHeader": make { CardHeaderView(context: $0) },
        "TextContent": make { TextContentView(context: $0) },
        "MarkDownRenderer": make { MarkdownRendererView(context: $0) },
        "Callout": make { CalloutView(context: $0) },
        "TextCallout": make { TextCalloutView(context: $0) },
        "Image": make { ImageComponentView(context: $0) },
        "ImageBlock": make { ImageBlockView(context: $0) },
        "ImageGallery": make { ImageGalleryView(context: $0) },
        "CodeBlock": make { CodeBlockComponentView(context: $0) },
        "Separator": make { SeparatorView(context: $0) },
        "InlineHeader": make { InlineHeaderView(context: $0) },
        "Label": make { LabelView(context: $0) },
        // Tables
        "Table": make { TableView(context: $0) },
        "EditableTable": make { EditableTableView(context: $0) },
        // Charts
        "BarChart": make { CartesianChartView(context: $0, kind: .bar) },
        "LineChart": make { CartesianChartView(context: $0, kind: .line) },
        "AreaChart": make { CartesianChartView(context: $0, kind: .area) },
        "HorizontalBarChart": make { CartesianChartView(context: $0, kind: .horizontalBar) },
        "RadarChart": make { RadarChartView(context: $0) },
        "PieChart": make { PieChartView(context: $0) },
        "RadialChart": make { RadialChartView(context: $0) },
        "SingleStackedBarChart": make { SingleStackedBarView(context: $0) },
        "ScatterChart": make { ScatterChartView(context: $0) },
        // Forms
        "Form": make { FormView(context: $0) },
        "FormControl": make { FormControlView(context: $0) },
        "Input": make { TextInputView(context: $0, multiline: false) },
        "TextArea": make { TextInputView(context: $0, multiline: true) },
        "Select": make { SelectView(context: $0) },
        "DatePicker": make { DatePickerView(context: $0) },
        "Slider": make { SliderView(context: $0) },
        "CheckBoxGroup": make { ToggleGroupView(context: $0, isSwitch: false) },
        "SwitchGroup": make { ToggleGroupView(context: $0, isSwitch: true) },
        "RadioGroup": make { RadioGroupView(context: $0) },
        "Chips": make { SelectionFieldView(context: $0, isCards: false) },
        "OptionCards": make { SelectionFieldView(context: $0, isCards: true) },
        // Buttons
        "Button": make { ButtonComponentView(context: $0) },
        "Buttons": make { ButtonsView(context: $0) },
        "IconButton": make { IconButtonView(context: $0) },
        // Layout
        "Tabs": make { TabsView(context: $0) },
        "Accordion": make { AccordionView(context: $0) },
        "Steps": make { StepsView(context: $0) },
        "Carousel": make { CarouselView(context: $0) },
        // Data display
        "TagBlock": make { TagBlockView(context: $0) },
        "Tag": make { TagView(context: $0) },
        "Icon": make { IconView(context: $0) },
        "EntityList": make { EntityListView(context: $0) },
        "ListBlock": make { ListBlockView(context: $0) },
        // Card building blocks
        "Text": make { TextBlockView(context: $0, bold: false) },
        "BoldText": make { TextBlockView(context: $0, bold: true) },
        "IconText": make { IconTextView(context: $0) },
        "ImageText": make { ImageTextView(context: $0) },
        "ImageTextLarge": make { ImageTextLargeView(context: $0) },
        "MetricIndicatorInline": make { MetricInlineView(props: $0.props) },
        "MetricIndicatorWithStrikethrough": make { MetricStrikethroughView(props: $0.props) },
        // Card blocks
        "SnippetCardBlock": make { SnippetCardBlockView(context: $0) },
        "OverviewCardBlock": make { OverviewCardBlockView(context: $0) },
        "ContextCardBlock": make { ContextCardBlockView(context: $0) },
        "CompositeCardBlock": make { CompositeCardBlockView(context: $0) },
        "VisualCardBlock": make { VisualCardBlockView(context: $0) }
    ]

    /// Chat-specific renderers.
    static let chatOverrides: [String: ComponentRenderer] = [
        "Card": make { ChatCardView(context: $0) },
        "FollowUpBlock": make { FollowUpBlockView(context: $0) },
        "SectionBlock": make { SectionBlockView(context: $0) }
    ]

    /// Standard-library-specific renderers.
    static let standardOverrides: [String: ComponentRenderer] = [
        "Card": make { StandardCardView(context: $0) },
        "Stack": make { StackView(context: $0) },
        "Modal": make { ModalView(context: $0) }
    ]
}
