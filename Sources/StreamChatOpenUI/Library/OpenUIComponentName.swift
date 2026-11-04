//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// The name of a component of OpenUI's libraries, such as ``button``, to replace its view with
/// ``ComponentLibrary/replacingView(of:with:)``.
@available(iOS 17.0, macOS 14.0, *)
public struct OpenUIComponentName: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        rawValue = value
    }
}

@available(iOS 17.0, macOS 14.0, *)
public extension OpenUIComponentName {
    static let accordion: Self = "Accordion"
    static let accordionItem: Self = "AccordionItem"
    static let areaChart: Self = "AreaChart"
    static let barChart: Self = "BarChart"
    static let boldText: Self = "BoldText"
    static let button: Self = "Button"
    static let buttons: Self = "Buttons"
    static let callout: Self = "Callout"
    static let card: Self = "Card"
    static let cardHeader: Self = "CardHeader"
    static let carousel: Self = "Carousel"
    static let checkBoxGroup: Self = "CheckBoxGroup"
    static let checkBoxItem: Self = "CheckBoxItem"
    static let chipItem: Self = "ChipItem"
    static let chips: Self = "Chips"
    static let codeBlock: Self = "CodeBlock"
    static let col: Self = "Col"
    static let compositeCardBlock: Self = "CompositeCardBlock"
    static let compositeCardItem: Self = "CompositeCardItem"
    static let contextCardBlock: Self = "ContextCardBlock"
    static let contextCardItem: Self = "ContextCardItem"
    static let datePicker: Self = "DatePicker"
    static let editableTable: Self = "EditableTable"
    static let entityList: Self = "EntityList"
    static let followUpBlock: Self = "FollowUpBlock"
    static let followUpItem: Self = "FollowUpItem"
    static let form: Self = "Form"
    static let formControl: Self = "FormControl"
    static let horizontalBarChart: Self = "HorizontalBarChart"
    static let icon: Self = "Icon"
    static let iconButton: Self = "IconButton"
    static let iconText: Self = "IconText"
    static let image: Self = "Image"
    static let imageBlock: Self = "ImageBlock"
    static let imageGallery: Self = "ImageGallery"
    static let imageText: Self = "ImageText"
    static let imageTextLarge: Self = "ImageTextLarge"
    static let inlineHeader: Self = "InlineHeader"
    static let input: Self = "Input"
    static let label: Self = "Label"
    static let lineChart: Self = "LineChart"
    static let listBlock: Self = "ListBlock"
    static let listItem: Self = "ListItem"
    static let markDownRenderer: Self = "MarkDownRenderer"
    static let metricIndicatorInline: Self = "MetricIndicatorInline"
    static let metricIndicatorWithStrikethrough: Self = "MetricIndicatorWithStrikethrough"
    static let modal: Self = "Modal"
    static let optionCard: Self = "OptionCard"
    static let optionCards: Self = "OptionCards"
    static let overviewCardBlock: Self = "OverviewCardBlock"
    static let overviewCardItem: Self = "OverviewCardItem"
    static let pieChart: Self = "PieChart"
    static let point: Self = "Point"
    static let radarChart: Self = "RadarChart"
    static let radialChart: Self = "RadialChart"
    static let radioGroup: Self = "RadioGroup"
    static let radioItem: Self = "RadioItem"
    static let scatterChart: Self = "ScatterChart"
    static let scatterSeries: Self = "ScatterSeries"
    static let sectionBlock: Self = "SectionBlock"
    static let sectionItem: Self = "SectionItem"
    static let select: Self = "Select"
    static let selectItem: Self = "SelectItem"
    static let separator: Self = "Separator"
    static let series: Self = "Series"
    static let singleStackedBarChart: Self = "SingleStackedBarChart"
    static let slice: Self = "Slice"
    static let slider: Self = "Slider"
    static let snippetCardBlock: Self = "SnippetCardBlock"
    static let snippetCardItem: Self = "SnippetCardItem"
    static let stack: Self = "Stack"
    static let steps: Self = "Steps"
    static let stepsItem: Self = "StepsItem"
    static let switchGroup: Self = "SwitchGroup"
    static let switchItem: Self = "SwitchItem"
    static let tabItem: Self = "TabItem"
    static let table: Self = "Table"
    static let tabs: Self = "Tabs"
    static let tag: Self = "Tag"
    static let tagBlock: Self = "TagBlock"
    static let text: Self = "Text"
    static let textArea: Self = "TextArea"
    static let textCallout: Self = "TextCallout"
    static let textContent: Self = "TextContent"
    static let visualCardBlock: Self = "VisualCardBlock"
    static let visualCardItem: Self = "VisualCardItem"
}
