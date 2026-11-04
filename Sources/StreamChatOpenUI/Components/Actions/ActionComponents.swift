//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

@available(iOS 17.0, macOS 14.0, *)
extension ComponentContext {
    /// Fires an action through the runtime (see ``OpenUIRuntime/triggerAction(label:formName:action:)``).
    func trigger(label: String, formName: String? = nil, action: OpenUIValue? = nil) {
        let runtime = self.runtime
        Task { await runtime.triggerAction(label: label, formName: formName, action: action) }
    }
}

/// Merges per-item click context into a card block's shared action (port of `withItemContext`).
@available(iOS 17.0, macOS 14.0, *)
enum ItemActionContext {
    static func merge(_ action: OpenUIValue?, item: OpenUIObject) -> OpenUIValue {
        let context = item
        guard let action, !action.isNull else {
            return ["type": .string(BuiltinActionType.continueConversation), "params": .object(context)]
        }
        if case .array(let steps)? = action["steps"] {
            guard !context.isEmpty, case .object(var plan) = action else { return action }
            let suffix = "Selected item: " + OpenUIJSON.stringify(.object(context))
            plan["steps"] = .array(steps.map { step in
                guard step["type"] == .string(ActionStepType.continueConversation), case .object(var object) = step else { return step }
                if let existing = object["context"]?.stringValue, !existing.isEmpty {
                    object["context"] = .string(existing + "\n" + suffix)
                } else {
                    object["context"] = .string(suffix)
                }
                return .object(object)
            })
            return .object(plan)
        }
        var params = action["params"]?.objectValue ?? [:]
        if let url = action["url"] { params["url"] = url }
        if let actionContext = action["context"], JS.isTruthy(actionContext) { params["context"] = actionContext }
        for (key, value) in context.entries { params[key] = value }
        let type = action["type"].map { JS.toString($0) } ?? BuiltinActionType.continueConversation
        return ["type": .string(type), "params": .object(params)]
    }

    /// Builds an item context object, dropping absent values.
    static func object(_ pairs: [(String, OpenUIValue?)]) -> OpenUIObject {
        var object = OpenUIObject()
        for (key, value) in pairs {
            if let value { object[key] = value }
        }
        return object
    }
}

// MARK: - Buttons

/// `Button(label, action?, variant?, type?, size?)`.
@available(iOS 17.0, macOS 14.0, *)
struct ButtonComponentView: View {
    let context: ComponentContext
    var sizeOverride: String?
    @Environment(\.openUIFormName) private var formName
    @Environment(\.openUIFormValidation) private var validation
    @Environment(\.openUITheme) private var theme

    var body: some View {
        let props = context.props
        let label = props.text("label") ?? ""
        let variant = props.string("variant") ?? "primary"
        let destructive = props.string("type") == "destructive"
        let size = sizeOverride ?? props.string("size") ?? "medium"

        Button(role: destructive ? .destructive : nil) {
            tap(label: label, variant: variant)
        } label: {
            Text(label)
                .font(size == "large" ? theme.fonts.body.weight(.semibold) : theme.fonts.bodySmall.weight(.semibold))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: variant == "tertiary" ? nil : .infinity)
        }
        .modifier(OpenUIButtonStyle(variant: variant))
        .tint(destructive ? theme.colors.danger : theme.colors.accent)
        .controlSize(Self.controlSize(size))
        .disabled(context.isStreaming)
    }

    private func tap(label: String, variant: String) {
        let action = context.props["action"]
        // Primary buttons validate the enclosing form first.
        if let validation, variant == "primary" {
            if case .array(let steps)? = action?["steps"] {
                let needsValidation = steps.contains { step in
                    step["type"] == .string(ActionStepType.continueConversation)
                        || (step["type"] == .string(ActionStepType.run) && step["refType"] == "mutation")
                }
                if needsValidation && !validation.validateForm() { return }
            } else if !validation.validateForm() {
                return
            }
        }
        context.trigger(label: label, formName: formName, action: action)
    }

    static func controlSize(_ size: String) -> ControlSize {
        switch size {
        case "extra-small": return .mini
        case "small": return .small
        case "large": return .large
        default: return .regular
        }
    }
}

@available(iOS 17.0, macOS 14.0, *)
struct OpenUIButtonStyle: ViewModifier {
    let variant: String

    func body(content: Content) -> some View {
        switch variant {
        case "secondary":
            content.buttonStyle(.bordered)
        case "tertiary", "ghost":
            content.buttonStyle(.borderless)
        default:
            content.buttonStyle(.borderedProminent)
        }
    }
}

/// `Buttons(buttons, direction?)`.
@available(iOS 17.0, macOS 14.0, *)
struct ButtonsView: View {
    let context: ComponentContext
    @Environment(\.openUITheme) private var theme

    var body: some View {
        let buttons = context.props.array("buttons")
        if context.props.string("direction") == "column" {
            VStack(spacing: theme.spacing.s) {
                context.render(.array(buttons))
            }
            .frame(maxWidth: .infinity)
        } else {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: theme.spacing.s) {
                    context.render(.array(buttons))
                }
                VStack(spacing: theme.spacing.s) {
                    context.render(.array(buttons))
                }
            }
        }
    }
}

/// `IconButton(name, icon, action?, variant?, size?, shape?)`.
@available(iOS 17.0, macOS 14.0, *)
struct IconButtonView: View {
    let context: ComponentContext
    @Environment(\.openUIFormName) private var formName
    @Environment(\.openUITheme) private var theme
    @ScaledMetric(relativeTo: .body) private var iconSize: CGFloat = 20

    var body: some View {
        let props = context.props
        let name = props.text("name") ?? ""
        let variant = props.string("variant") ?? "secondary"
        Button {
            context.trigger(label: name, formName: formName, action: props["action"])
        } label: {
            OpenUIIconImage(element: props.element("icon"))
                .frame(width: iconSize, height: iconSize)
        }
        .modifier(OpenUIButtonStyle(variant: variant))
        .tint(theme.colors.accent)
        .buttonBorderShape(props.string("shape") == "circle" ? .circle : .roundedRectangle)
        .controlSize(ButtonComponentView.controlSize(props.string("size") ?? "medium"))
        .disabled(context.isStreaming)
        .accessibilityLabel(Text(name.isEmpty ? OpenUIIcons.accessibilityName(for: props.element("icon")?.props["name"]?.stringValue) : name))
    }
}

// MARK: - Lists & follow-ups

/// `FollowUpBlock(items)` — suggestions that send their text as the next user message.
@available(iOS 17.0, macOS 14.0, *)
struct FollowUpBlockView: View {
    let context: ComponentContext
    @Environment(\.openUITheme) private var theme

    var body: some View {
        let items = context.props.elements("items")
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                let text = ComponentProps(item.props).text("text") ?? ""
                Button {
                    context.trigger(label: text)
                } label: {
                    HStack(spacing: theme.spacing.s) {
                        Image(systemName: "arrow.turn.down.right")
                            .font(theme.fonts.bodySmall.weight(.semibold))
                            .foregroundStyle(theme.colors.accent)
                            .accessibilityHidden(true)
                        Text(text)
                            .font(theme.fonts.bodySmall)
                            .foregroundStyle(theme.colors.textPrimary)
                            .multilineTextAlignment(.leading)
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, theme.spacing.s + 2)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(context.isStreaming)
                if index < items.count - 1 {
                    Divider().padding(.leading, 26)
                }
            }
        }
    }
}

/// `ListBlock(items, variant?, size?)` with `ListItem(title, subtitle?, image?, actionLabel?, action?)`.
@available(iOS 17.0, macOS 14.0, *)
struct ListBlockView: View {
    let context: ComponentContext
    var sizeOverride: String?
    @Environment(\.openUITheme) private var theme
    @ScaledMetric(relativeTo: .caption) private var scale: CGFloat = 1

    var body: some View {
        let items = context.props.elements("items")
        let variant = context.props.string("variant") ?? "number"
        let small = (sizeOverride ?? context.props.string("size")) == "small"
        let hasSubtitle = items.contains { ComponentProps($0.props).text("subtitle") != nil }

        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                let props = ComponentProps(item.props)
                let title = props.text("title") ?? ""
                let action = props["action"]
                let hasAction = action.map { !$0.isNull } ?? false
                let row = HStack(alignment: hasSubtitle ? .top : .center, spacing: theme.spacing.m) {
                    if variant == "image", let image = props.object("image") {
                        RemoteImage(url: image["src"]?.stringValue, alt: image["alt"]?.stringValue)
                            .frame(width: (small ? 36 : 48) * scale, height: (small ? 36 : 48) * scale)
                            .clipShape(RoundedRectangle(cornerRadius: theme.radius.small, style: .continuous))
                    } else {
                        Text("\(index + 1)")
                            .font(theme.fonts.caption.weight(.semibold))
                            .monospacedDigit()
                            .foregroundStyle(theme.colors.accent)
                            .frame(width: (small ? 20 : 24) * scale, height: (small ? 20 : 24) * scale)
                            .background(theme.colors.accent.opacity(0.12), in: Circle())
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(InlineMarkdown.cached(title))
                            .font(small ? theme.fonts.caption.weight(.medium) : theme.fonts.bodySmall.weight(.medium))
                            .foregroundStyle(theme.colors.textPrimary)
                        if let subtitle = props.text("subtitle") {
                            Text(InlineMarkdown.cached(subtitle))
                                .font(theme.fonts.caption)
                                .foregroundStyle(theme.colors.textSecondary)
                        }
                    }
                    .multilineTextAlignment(.leading)
                    Spacer(minLength: 0)
                    if hasAction {
                        HStack(spacing: 4) {
                            if let actionLabel = props.text("actionLabel") {
                                Text(actionLabel).font(theme.fonts.caption.weight(.medium))
                            }
                            Image(systemName: "chevron.forward")
                                .font(theme.fonts.caption.weight(.semibold))
                                .accessibilityHidden(true)
                        }
                        .foregroundStyle(theme.colors.textSecondary)
                    }
                }
                .padding(.vertical, small ? theme.spacing.xs + 2 : theme.spacing.s + 2)
                .contentShape(Rectangle())

                Group {
                    if hasAction {
                        Button { context.trigger(label: title, action: action) } label: { row }
                            .buttonStyle(.plain)
                            .disabled(context.isStreaming)
                    } else {
                        row
                    }
                }
                if index < items.count - 1 {
                    Divider().padding(.leading, variant == "image" ? (small ? 48 : 60) : 36)
                }
            }
        }
    }
}

// MARK: - Tags & icons

/// `Icon(name, category?)`.
@available(iOS 17.0, macOS 14.0, *)
struct IconView: View {
    let context: ComponentContext
    @Environment(\.openUITheme) private var theme

    var body: some View {
        OpenUIIconImage(element: context.element)
            .foregroundStyle(theme.colors.textSecondary)
    }
}

/// A capsule tag (`Tag(text, icon?, size?, variant?)`).
@available(iOS 17.0, macOS 14.0, *)
struct TagPill: View {
    let text: String
    var icon: ElementNode?
    var size: String?
    var variant: String?
    @Environment(\.openUITheme) private var theme

    var body: some View {
        let color = variant == nil || variant == "neutral" ? theme.colors.textSecondary : theme.colors.variant(variant)
        HStack(spacing: 4) {
            if let icon {
                OpenUIIconImage(element: icon)
                    .font(font.weight(.semibold))
                    .accessibilityHidden(true)
            }
            Text(text)
                .font(font.weight(.medium))
                .lineLimit(1)
        }
        .foregroundStyle(color)
        .padding(.horizontal, size == "lg" ? 12 : size == "md" ? 10 : 8)
        .padding(.vertical, size == "lg" ? 6 : size == "md" ? 4 : 3)
        .background(
            (variant == nil || variant == "neutral" ? theme.colors.subtleFill : color.opacity(0.14)),
            in: Capsule()
        )
    }

    private var font: Font {
        switch size {
        case "lg": return .subheadline
        case "md": return .footnote
        default: return .caption
        }
    }
}

@available(iOS 17.0, macOS 14.0, *)
struct TagView: View {
    let context: ComponentContext
    var sizeOverride: String?

    var body: some View {
        let props = context.props
        TagPill(
            text: props.text("text") ?? "",
            icon: props.element("icon"),
            size: sizeOverride ?? props.string("size"),
            variant: props.string("variant")
        )
    }
}

/// `TagBlock(tags, size?)`.
@available(iOS 17.0, macOS 14.0, *)
struct TagBlockView: View {
    let context: ComponentContext
    var sizeOverride: String?
    @Environment(\.openUITheme) private var theme

    var body: some View {
        let tags = context.props.strings("tags")
        FlowLayout(horizontalSpacing: theme.spacing.xs + 2, verticalSpacing: theme.spacing.xs + 2) {
            ForEach(Array(tags.enumerated()), id: \.offset) { _, tag in
                TagPill(text: tag, size: sizeOverride ?? context.props.string("size"))
            }
        }
    }
}

/// `EntityList(rows?, size?, header?, footer?)` — two-column key/value rows.
@available(iOS 17.0, macOS 14.0, *)
struct EntityListView: View {
    let context: ComponentContext
    var compact: Bool = false
    @Environment(\.openUITheme) private var theme

    var body: some View {
        let props = context.props
        let small = compact || props.string("size") == "small"
        let rows = props.array("rows").compactMap(\.objectValue)
        VStack(spacing: 0) {
            if !small, let header = props.object("header") {
                row(header, emphasized: true, small: small)
                Divider()
            }
            ForEach(Array(rows.enumerated()), id: \.offset) { index, item in
                row(item, emphasized: false, small: small)
                if index < rows.count - 1 {
                    Divider().opacity(0.6)
                }
            }
            if !small, let footer = props.object("footer") {
                Divider()
                row(footer, emphasized: true, small: small)
            }
        }
    }

    private func row(_ item: OpenUIObject, emphasized: Bool, small: Bool) -> some View {
        let isNumber = item["rightVariant"] == "number"
        let font = small ? theme.fonts.caption : theme.fonts.bodySmall
        return HStack(alignment: .firstTextBaseline, spacing: theme.spacing.m) {
            Text(item["left"].map { JS.toString($0) } ?? "")
                .font(emphasized ? font.weight(.semibold) : font)
                .foregroundStyle(emphasized ? theme.colors.textPrimary : theme.colors.textSecondary)
            Spacer(minLength: theme.spacing.s)
            Text(item["right"].map { JS.toString($0) } ?? "")
                .font(emphasized || !small ? font.weight(.semibold) : font.weight(.medium))
                .foregroundStyle(theme.colors.textPrimary)
                .monospacedDigit(isNumber)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, small ? 5 : 8)
    }
}

@available(iOS 17.0, macOS 14.0, *)
extension View {
    @ViewBuilder
    func monospacedDigit(_ enabled: Bool) -> some View {
        if enabled { monospacedDigit() } else { self }
    }
}
