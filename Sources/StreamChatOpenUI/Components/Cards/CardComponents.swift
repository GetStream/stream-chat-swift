//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

// MARK: - Inline building blocks

/// `Text(variant?, value, subtext?, subtextVariant?, size?)` and `BoldText(...)`.
@available(iOS 17.0, macOS 14.0, *)
struct TextBlockView: View {
    let context: ComponentContext
    let bold: Bool
    var sizeOverride: String?
    @Environment(\.openUITheme) private var theme

    var body: some View {
        let props = context.props
        let size = sizeOverride ?? props.string("size") ?? "md"
        let isNumber = props.string("variant") == "number"
        VStack(alignment: .leading, spacing: 2) {
            Text(InlineMarkdown.cached(props.text("value") ?? ""))
                .font(primaryFont(size).weight(bold ? .semibold : .regular))
                .monospacedDigit(isNumber)
                .foregroundStyle(theme.colors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            if let subtext = props.text("subtext"), !subtext.isEmpty {
                Text(subtext)
                    .font(subtextFont(size))
                    .monospacedDigit(props.string("subtextVariant") != "text")
                    .foregroundStyle(subtextColor(subtext, variant: props.string("subtextVariant")))
            }
        }
    }

    private func primaryFont(_ size: String) -> Font {
        switch size {
        case "xs": return .footnote
        case "sm": return .subheadline
        case "lg": return bold ? .title2 : .title3
        default: return bold ? .title3 : .body
        }
    }

    private func subtextFont(_ size: String) -> Font {
        size == "xs" || size == "sm" ? .caption2 : .caption
    }

    private func subtextColor(_ subtext: String, variant: String?) -> Color {
        guard variant == "metric" else { return theme.colors.textSecondary }
        if subtext.hasPrefix("+") { return theme.colors.success }
        if subtext.hasPrefix("-") || subtext.hasPrefix("−") { return theme.colors.danger }
        return theme.colors.textSecondary
    }
}

/// An icon in a tinted rounded badge.
@available(iOS 17.0, macOS 14.0, *)
struct IconBadge: View {
    let icon: ElementNode?
    let variant: String?
    let size: String?
    @Environment(\.openUITheme) private var theme
    @ScaledMetric(relativeTo: .body) private var scale: CGFloat = 1

    var body: some View {
        let dimension = Self.dimension(size) * scale
        let color: Color = {
            switch variant {
            case "inverted", "filled": return theme.colors.onAccent
            case "info", "success", "warning", "danger": return theme.colors.variant(variant)
            default: return theme.colors.textPrimary
            }
        }()
        let background: Color = {
            switch variant {
            case "inverted": return theme.colors.textPrimary
            case "filled": return theme.colors.accent
            case "info", "success", "warning", "danger": return theme.colors.variant(variant).opacity(0.14)
            case "soft": return theme.colors.accent.opacity(0.12)
            default: return theme.colors.sunkenSurface
            }
        }()
        OpenUIIconImage(element: icon)
            .font(.system(size: dimension * 0.45, weight: .semibold))
            .foregroundStyle(variant == "soft" ? theme.colors.accent : color)
            .frame(width: dimension, height: dimension)
            .background(background, in: RoundedRectangle(cornerRadius: dimension * 0.28, style: .continuous))
            .accessibilityHidden(true)
    }

    static func dimension(_ size: String?) -> CGFloat {
        switch size {
        case "xs": return 24
        case "s", "sm": return 30
        case "l", "lg": return 44
        case "xl": return 52
        default: return 36
        }
    }
}

/// `IconText(icon, iconVariant?, iconSize?, title, subtitle?, bold?, layout?)`.
@available(iOS 17.0, macOS 14.0, *)
struct IconTextView: View {
    let context: ComponentContext
    @Environment(\.openUITheme) private var theme

    var body: some View {
        let props = context.props
        let vertical = props.string("layout") == "vertical"
        let bold = props.bool("bold") ?? false
        let layout = vertical
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: theme.spacing.s))
            : AnyLayout(HStackLayout(alignment: .center, spacing: theme.spacing.m))
        layout {
            IconBadge(icon: props.element("icon"), variant: props.string("iconVariant"), size: props.string("iconSize"))
            TitleSubtitle(title: props.text("title") ?? "", subtitle: props.text("subtitle"), bold: bold)
        }
    }
}

@available(iOS 17.0, macOS 14.0, *)
struct TitleSubtitle: View {
    let title: String
    let subtitle: String?
    var bold: Bool = false
    @Environment(\.openUITheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(InlineMarkdown.cached(title))
                .font(theme.fonts.bodySmall.weight(bold ? .semibold : .medium))
                .foregroundStyle(theme.colors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            if let subtitle, !subtitle.isEmpty {
                Text(InlineMarkdown.cached(subtitle))
                    .font(theme.fonts.caption)
                    .foregroundStyle(theme.colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

/// `ImageText(src, alt?, title, subtitle?, bold?, layout?, imageSize?)`.
@available(iOS 17.0, macOS 14.0, *)
struct ImageTextView: View {
    let context: ComponentContext
    @Environment(\.openUITheme) private var theme

    var body: some View {
        let props = context.props
        let size = CGFloat(props.number("imageSize") ?? 40)
        let vertical = props.string("layout") == "vertical"
        let layout = vertical
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: theme.spacing.s))
            : AnyLayout(HStackLayout(alignment: .center, spacing: theme.spacing.m))
        layout {
            RemoteImage(url: props.string("src"), alt: props.text("alt"))
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: theme.radius.small, style: .continuous))
            TitleSubtitle(title: props.text("title") ?? "", subtitle: props.text("subtitle"), bold: props.bool("bold") ?? false)
        }
    }
}

/// `ImageTextLarge(src, alt?, title, subtitle?, bold?)`.
@available(iOS 17.0, macOS 14.0, *)
struct ImageTextLargeView: View {
    let context: ComponentContext
    @Environment(\.openUITheme) private var theme

    var body: some View {
        let props = context.props
        VStack(alignment: .leading, spacing: theme.spacing.s) {
            RemoteImage(url: props.string("src"), alt: props.text("alt"))
                .filling(height: 140, cornerRadius: theme.radius.medium)
            TitleSubtitle(title: props.text("title") ?? "", subtitle: props.text("subtitle"), bold: true)
        }
    }
}

/// A `{direction: "up" | "down", value: number}` trend badge.
@available(iOS 17.0, macOS 14.0, *)
struct TrendBadge: View {
    let trend: OpenUIObject?
    @Environment(\.openUITheme) private var theme

    var body: some View {
        if let trend, let direction = trend["direction"]?.stringValue {
            let up = direction == "up"
            let value = JS.toNumber(trend["value"])
            let color = up ? theme.colors.success : theme.colors.danger
            HStack(spacing: 2) {
                Image(systemName: up ? "arrow.up.right" : "arrow.down.right")
                    .accessibilityHidden(true)
                Text(NumberFormatting.percent(abs(value)))
            }
            .font(theme.fonts.caption.weight(.semibold))
            .monospacedDigit()
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.12), in: Capsule())
            .accessibilityLabel(Text(up ? L10n.Trend.up(NumberFormatting.decimal(abs(value))) : L10n.Trend.down(NumberFormatting.decimal(abs(value)))))
        }
    }
}

/// `MetricIndicatorInline(value, subtext?, trend?)`.
@available(iOS 17.0, macOS 14.0, *)
struct MetricInlineView: View {
    let props: ComponentProps
    @Environment(\.openUITheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: theme.spacing.s) {
                Text(props.text("value") ?? "")
                    .font(theme.fonts.metric)
                    .foregroundStyle(theme.colors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                TrendBadge(trend: props.object("trend"))
            }
            if let subtext = props.text("subtext"), !subtext.isEmpty {
                Text(subtext)
                    .font(theme.fonts.caption)
                    .foregroundStyle(theme.colors.textSecondary)
            }
        }
    }
}

/// `MetricIndicatorWithStrikethrough(value, subtext?, previousValue?, trend?)`.
@available(iOS 17.0, macOS 14.0, *)
struct MetricStrikethroughView: View {
    let props: ComponentProps
    @Environment(\.openUITheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: theme.spacing.s) {
                Text(props.text("value") ?? "")
                    .font(theme.fonts.metric)
                    .foregroundStyle(theme.colors.textPrimary)
                if let previous = props.text("previousValue"), !previous.isEmpty {
                    Text(previous)
                        .font(theme.fonts.bodySmall)
                        .strikethrough()
                        .foregroundStyle(theme.colors.textTertiary)
                }
                TrendBadge(trend: props.object("trend"))
            }
            if let subtext = props.text("subtext"), !subtext.isEmpty {
                Text(subtext)
                    .font(theme.fonts.caption)
                    .foregroundStyle(theme.colors.textSecondary)
            }
        }
    }
}

// MARK: - Card blocks

/// Shared layout for card blocks: a responsive grid or a horizontal carousel of tappable cards.
@available(iOS 17.0, macOS 14.0, *)
struct CardBlockLayout<Item: View>: View {
    let count: Int
    let layout: String
    let minItemWidth: CGFloat
    let carouselItemWidth: CGFloat
    let gap: CGFloat?
    let isClickable: Bool
    let onTap: (Int) -> Void
    @ViewBuilder let item: (Int) -> Item
    @Environment(\.openUITheme) private var theme

    var body: some View {
        let spacing = gap ?? theme.spacing.m
        if layout == "carousel" {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .top, spacing: spacing) {
                    ForEach(0..<count, id: \.self) { index in
                        tappable(index).frame(width: carouselItemWidth)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
        } else {
            ResponsiveGridLayout(spacing: spacing, minItemWidth: minItemWidth, maxColumns: 3) {
                ForEach(0..<count, id: \.self) { index in
                    tappable(index)
                }
            }
        }
    }

    @ViewBuilder
    private func tappable(_ index: Int) -> some View {
        if isClickable {
            Button { onTap(index) } label: {
                item(index).contentShape(Rectangle())
            }
            .buttonStyle(CardPressStyle())
        } else {
            item(index)
        }
    }
}

@available(iOS 17.0, macOS 14.0, *)
struct CardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// Common props of the five card blocks.
@available(iOS 17.0, macOS 14.0, *)
@MainActor
private struct CardBlockProps {
    let items: [ElementNode]
    let layout: String
    let action: OpenUIValue?
    let gap: CGFloat?

    init(_ context: ComponentContext, theme: OpenUITheme) {
        let props = context.props
        items = props.elements("items")
        layout = props.string("layout") ?? "grid"
        action = props["action"].flatMap { $0.isNull ? nil : $0 }
        switch props["gap"] {
        case .number(let number)?: gap = CGFloat(number)
        case .string(let token)?: gap = theme.spacing.value(token, default: theme.spacing.m)
        default: gap = nil
        }
    }
}

@available(iOS 17.0, macOS 14.0, *)
private func stringProp(_ element: ElementNode?, _ key: String) -> String? {
    element?.props[key]?.stringValue
}

@available(iOS 17.0, macOS 14.0, *)
@MainActor
private func cardTap(_ context: ComponentContext, action: OpenUIValue?, label: String, item: OpenUIObject, formName: String?) {
    guard action != nil, !context.isStreaming else { return }
    context.trigger(label: label, formName: formName, action: ItemActionContext.merge(action, item: item))
}

/// `SnippetCardBlock(items, layout?, responsive?, action?, gap?)` with `SnippetCardItem(id?, lhs, rhs?)`.
@available(iOS 17.0, macOS 14.0, *)
struct SnippetCardBlockView: View {
    let context: ComponentContext
    @Environment(\.openUITheme) private var theme
    @Environment(\.openUIFormName) private var formName

    var body: some View {
        let block = CardBlockProps(context, theme: theme)
        CardBlockLayout(
            count: block.items.count,
            layout: "grid",
            minItemWidth: 150,
            carouselItemWidth: 220,
            gap: block.gap,
            isClickable: block.action != nil && !context.isStreaming,
            onTap: { index in
                let item = block.items[index]
                let lhs = item.props["lhs"]?.elementValue
                let rhs = item.props["rhs"]?.elementValue
                let id = stringProp(item, "id")
                cardTap(
                    context,
                    action: block.action,
                    label: stringProp(lhs, "title") ?? id ?? L10n.CardBlock.snippet(index + 1),
                    item: ItemActionContext.object([
                        ("itemIndex", .number(Double(index))), ("itemId", id.map(OpenUIValue.string)),
                        ("itemTitle", stringProp(lhs, "title").map(OpenUIValue.string)),
                        ("itemSubtitle", stringProp(lhs, "subtitle").map(OpenUIValue.string)),
                        ("itemValue", stringProp(rhs, "value").map(OpenUIValue.string))
                    ]),
                    formName: formName
                )
            }
        ) { index in
            let item = block.items[index]
            let rhs = item.props["rhs"]?.elementValue.map { ComponentContext.overriding($0, ["size": "xs"]) }
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: theme.spacing.s) {
                    context.render(item.props["lhs"]).fixedSize()
                    Spacer(minLength: theme.spacing.s)
                    if let rhs {
                        OpenUIElementView(element: rhs).fixedSize()
                    }
                }
                VStack(alignment: .leading, spacing: theme.spacing.s) {
                    context.render(item.props["lhs"])
                    if let rhs {
                        OpenUIElementView(element: rhs)
                    }
                }
            }
            .padding(theme.spacing.m)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .background(theme.colors.sunkenSurface, in: RoundedRectangle(cornerRadius: theme.radius.medium, style: .continuous))
        }
    }
}

/// `OverviewCardBlock(items, layout?, ...)` with `OverviewCardItem(id?, top, bottom?)`.
@available(iOS 17.0, macOS 14.0, *)
struct OverviewCardBlockView: View {
    let context: ComponentContext
    @Environment(\.openUITheme) private var theme
    @Environment(\.openUIFormName) private var formName

    var body: some View {
        let block = CardBlockProps(context, theme: theme)
        CardBlockLayout(
            count: block.items.count,
            layout: block.layout,
            minItemWidth: 140,
            carouselItemWidth: 180,
            gap: block.gap,
            isClickable: block.action != nil && !context.isStreaming,
            onTap: { index in
                let item = block.items[index]
                let top = item.props["top"]?.elementValue
                let bottom = item.props["bottom"]?.elementValue
                let id = stringProp(item, "id")
                let title = stringProp(top, "title") ?? stringProp(top, "value")
                cardTap(
                    context,
                    action: block.action,
                    label: title ?? id ?? L10n.CardBlock.overview(index + 1),
                    item: ItemActionContext.object([
                        ("itemIndex", .number(Double(index))), ("itemId", id.map(OpenUIValue.string)),
                        ("itemTitle", title.map(OpenUIValue.string)),
                        ("itemSubtitle", (stringProp(top, "subtitle") ?? stringProp(top, "subtext")).map(OpenUIValue.string)),
                        ("itemMetricValue", bottom?.props["value"])
                    ]),
                    formName: formName
                )
            }
        ) { index in
            let item = block.items[index]
            VStack(alignment: .leading, spacing: theme.spacing.m) {
                context.render(item.props["top"])
                Spacer(minLength: 0)
                if let bottom = item.props["bottom"]?.elementValue {
                    MetricInlineView(props: ComponentProps(bottom.props))
                }
            }
            .padding(theme.spacing.m)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(theme.colors.sunkenSurface, in: RoundedRectangle(cornerRadius: theme.radius.medium, style: .continuous))
        }
    }
}

/// `ContextCardBlock(items, layout?, ...)` with `ContextCardItem(id?, title, body?, bgColor?, bgImageSrc?, bgImageAlt?)`.
@available(iOS 17.0, macOS 14.0, *)
struct ContextCardBlockView: View {
    let context: ComponentContext
    @Environment(\.openUITheme) private var theme
    @Environment(\.openUIFormName) private var formName

    var body: some View {
        let block = CardBlockProps(context, theme: theme)
        CardBlockLayout(
            count: block.items.count,
            layout: block.layout,
            minItemWidth: 150,
            carouselItemWidth: 210,
            gap: block.gap,
            isClickable: block.action != nil && !context.isStreaming,
            onTap: { index in
                let item = block.items[index]
                let props = ComponentProps(item.props)
                let title = titleText(item)
                cardTap(
                    context,
                    action: block.action,
                    label: title.isEmpty ? (props.text("id") ?? L10n.CardBlock.context(index + 1)) : title,
                    item: ItemActionContext.object([
                        ("itemIndex", .number(Double(index))), ("itemId", props["id"]),
                        ("itemTitle", .string(title)), ("itemBody", props["body"]),
                        ("itemBgColor", props["bgColor"]), ("itemBgImageSrc", props["bgImageSrc"]),
                        ("itemBgImageAlt", props["bgImageAlt"])
                    ]),
                    formName: formName
                )
            }
        ) { index in
            ContextCard(item: block.items[index])
        }
    }

    private func titleText(_ item: ElementNode) -> String {
        switch item.props["title"] {
        case .string(let title)?: return title
        case .element(let tag)?: return tag.props["text"]?.stringValue ?? ""
        default: return ""
        }
    }
}

@available(iOS 17.0, macOS 14.0, *)
private struct ContextCard: View {
    let item: ElementNode
    @Environment(\.openUITheme) private var theme

    var body: some View {
        let props = ComponentProps(item.props)
        let imageSource = props.string("bgImageSrc")
        let hasImage = imageSource?.isEmpty == false
        VStack(alignment: .leading, spacing: theme.spacing.s) {
            switch item.props["title"] {
            case .element(let tag)?:
                TagPill(text: tag.props["text"].map { JS.toString($0) } ?? "", icon: tag.props["icon"]?.elementValue, size: "sm", variant: tag.props["variant"]?.stringValue ?? "neutral")
            case let title?:
                Text(JS.toString(title))
                    .font(theme.fonts.caption.weight(.semibold))
                    .foregroundStyle(hasImage ? .white.opacity(0.9) : theme.colors.textSecondary)
            case nil:
                EmptyView()
            }
            Spacer(minLength: hasImage ? 40 : 0)
            if let body = props.text("body"), !body.isEmpty {
                Text(InlineMarkdown.cached(body))
                    .font(theme.fonts.bodySmall.weight(.semibold))
                    .foregroundStyle(hasImage ? .white : theme.colors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(theme.spacing.m)
        .frame(maxWidth: .infinity, minHeight: hasImage ? 150 : 100, maxHeight: .infinity, alignment: .topLeading)
        .background {
            if hasImage {
                Color.clear
                    .overlay { RemoteImage(url: imageSource, alt: props.text("bgImageAlt")) }
                    .overlay(LinearGradient(colors: [.black.opacity(0.15), .black.opacity(0.7)], startPoint: .top, endPoint: .bottom))
                    .clipped()
            } else {
                theme.colors.sunkenSurface
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: theme.radius.medium, style: .continuous))
    }
}

/// `CompositeCardBlock(items, layout?, ...)` with `CompositeCardItem(id?, header?, body?, footer?)`.
@available(iOS 17.0, macOS 14.0, *)
struct CompositeCardBlockView: View {
    let context: ComponentContext
    @Environment(\.openUITheme) private var theme
    @Environment(\.openUIFormName) private var formName

    var body: some View {
        let block = CardBlockProps(context, theme: theme)
        CardBlockLayout(
            count: block.items.count,
            layout: block.layout,
            minItemWidth: 250,
            carouselItemWidth: 270,
            gap: block.gap,
            isClickable: block.action != nil && !context.isStreaming,
            onTap: { index in
                let item = block.items[index]
                let header = item.props["header"]?.elementValue
                let headerProps = header.map { ComponentProps($0.props) }
                let title = headerProps?.string("title") ?? headerProps?.string("value")
                let subtitle = headerProps?.string("subtitle") ?? headerProps?.string("subtext")
                let alt = headerProps?.string("alt")
                let footer = item.props["footer"]?.objectValue
                let id = stringProp(item, "id")
                cardTap(
                    context,
                    action: block.action,
                    label: title ?? alt ?? id ?? L10n.CardBlock.composite(index + 1),
                    item: ItemActionContext.object([
                        ("itemIndex", .number(Double(index))), ("itemId", id.map(OpenUIValue.string)),
                        ("itemHeaderTitle", title.map(OpenUIValue.string)), ("itemHeaderSubtitle", subtitle.map(OpenUIValue.string)),
                        ("itemHeaderAlt", alt.map(OpenUIValue.string)),
                        ("itemBodyCount", .number(Double(item.props["body"]?.arrayValue?.count ?? 0))),
                        ("itemFooterPrice", footer?["price"]?.elementValue?.props["value"]),
                        ("itemFooterButtonLabel", footer?["button"]?.elementValue?.props["label"])
                    ]),
                    formName: formName
                )
            }
        ) { index in
            CompositeCard(item: block.items[index], context: context)
        }
    }
}

@available(iOS 17.0, macOS 14.0, *)
private struct CompositeCard: View {
    let item: ElementNode
    let context: ComponentContext
    @Environment(\.openUITheme) private var theme

    var body: some View {
        let body = item.props["body"]?.arrayValue ?? []
        let footer = item.props["footer"]?.objectValue
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            if let header = item.props["header"] {
                context.render(header)
            }
            ForEach(Array(body.enumerated()), id: \.offset) { _, node in
                if let element = node.elementValue {
                    OpenUIElementView(element: Self.normalized(element, location: .body))
                }
            }
            Spacer(minLength: 0)
            if let footer {
                HStack(alignment: .center, spacing: theme.spacing.m) {
                    if let price = footer["price"]?.elementValue {
                        OpenUIElementView(element: Self.normalized(price, location: .footer))
                    }
                    Spacer(minLength: 0)
                    if let button = footer["button"]?.elementValue {
                        OpenUIElementView(element: ComponentContext.overriding(button, ["size": "small"]))
                            .fixedSize()
                    }
                }
            }
        }
        .padding(theme.spacing.m)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(theme.colors.sunkenSurface, in: RoundedRectangle(cornerRadius: theme.radius.medium, style: .continuous))
    }

    enum Location { case body, footer }

    /// Keeps text size, chart height and list density consistent inside composite cards.
    static func normalized(_ element: ElementNode, location: Location) -> ElementNode {
        switch element.typeName {
        case "Text", "BoldText":
            return location == .body ? ComponentContext.overriding(element, ["size": "xs"]) : element
        case "AreaChart", "BarChart", "LineChart":
            return ComponentContext.overriding(element, ["height": 180])
        case "ListBlock":
            return ComponentContext.overriding(element, ["size": "small"])
        case "EntityList":
            var copy = ComponentContext.overriding(element, ["size": "small"])
            copy.props["header"] = nil
            copy.props["footer"] = nil
            return copy
        case "TagBlock":
            return ComponentContext.overriding(element, ["size": "sm"])
        case "Button":
            return ComponentContext.overriding(element, ["size": "small"])
        default:
            return element
        }
    }
}

/// `VisualCardBlock(items, layout?, ...)` with `VisualCardItem(body, id?, bgImageSrc?, tag?, bgImageAlt?)`.
@available(iOS 17.0, macOS 14.0, *)
struct VisualCardBlockView: View {
    let context: ComponentContext
    @Environment(\.openUITheme) private var theme
    @Environment(\.openUIFormName) private var formName

    var body: some View {
        let block = CardBlockProps(context, theme: theme)
        CardBlockLayout(
            count: block.items.count,
            layout: block.layout,
            minItemWidth: 150,
            carouselItemWidth: 200,
            gap: block.gap,
            isClickable: block.action != nil && !context.isStreaming,
            onTap: { index in
                let item = block.items[index]
                let props = ComponentProps(item.props)
                let body = props.element("body")
                let tag = props.element("tag")
                let bodyValue = body?.props["value"]?.stringValue
                let tagText = tag?.props["text"]?.stringValue
                cardTap(
                    context,
                    action: block.action,
                    label: bodyValue ?? tagText ?? props.text("id") ?? L10n.CardBlock.visual(index + 1),
                    item: ItemActionContext.object([
                        ("itemIndex", .number(Double(index))), ("itemId", props["id"]),
                        ("itemTag", tagText.map(OpenUIValue.string)), ("itemBody", bodyValue.map(OpenUIValue.string)),
                        ("itemBodySubtext", body?.props["subtext"]), ("itemBgImageSrc", props["bgImageSrc"]),
                        ("itemBgImageAlt", props["bgImageAlt"])
                    ]),
                    formName: formName
                )
            }
        ) { index in
            VisualCard(item: block.items[index])
        }
    }
}

@available(iOS 17.0, macOS 14.0, *)
private struct VisualCard: View {
    let item: ElementNode
    @Environment(\.openUITheme) private var theme

    var body: some View {
        let props = ComponentProps(item.props)
        let bodyProps = props.element("body").map { ComponentProps($0.props) }
        ZStack(alignment: .bottomLeading) {
            RemoteImage(url: props.string("bgImageSrc"), alt: props.text("bgImageAlt"))
                .filling(height: 190, cornerRadius: 0)
            LinearGradient(colors: [.clear, .black.opacity(0.75)], startPoint: .center, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 2) {
                Text(bodyProps?.text("value") ?? "")
                    .font(theme.fonts.bodySmall.weight(.semibold))
                    .foregroundStyle(.white)
                if let subtext = bodyProps?.text("subtext"), !subtext.isEmpty {
                    Text(subtext)
                        .font(theme.fonts.caption)
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
            .padding(theme.spacing.m)
        }
        .overlay(alignment: .topLeading) {
            if let tag = props.element("tag") {
                TagPill(text: tag.props["text"].map { JS.toString($0) } ?? "", icon: tag.props["icon"]?.elementValue, size: "sm", variant: tag.props["variant"]?.stringValue ?? "neutral")
                    .background(theme.colors.surface.opacity(0.92), in: Capsule())
                    .padding(theme.spacing.s)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: theme.radius.medium, style: .continuous))
    }
}
