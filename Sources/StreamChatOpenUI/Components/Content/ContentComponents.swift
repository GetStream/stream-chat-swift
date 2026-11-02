//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

// MARK: - Citations

/// Card sources keyed by their 1-based citation index, used to make `[n]` citations tappable.
@available(iOS 17.0, macOS 14.0, *)
private struct CitationSourcesKey: EnvironmentKey {
    static let defaultValue: [Int: String] = [:]
}

@available(iOS 17.0, macOS 14.0, *)
extension EnvironmentValues {
    var openUICitationSources: [Int: String] {
        get { self[CitationSourcesKey.self] }
        set { self[CitationSourcesKey.self] = newValue }
    }
}

@available(iOS 17.0, macOS 14.0, *)
enum Citations {
    /// Turns `[1]` citations into links when a source URL exists for them.
    static func link(_ text: String, sources: [Int: String]) -> String {
        guard !sources.isEmpty, text.contains("[") else { return text }
        let pattern = #"\[(\d{1,2})\](?!\()"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return text }
        let nsText = text as NSString
        var result = ""
        var cursor = 0
        for match in regex.matches(in: text, range: NSRange(location: 0, length: nsText.length)) {
            let number = Int(nsText.substring(with: match.range(at: 1))) ?? 0
            result += nsText.substring(with: NSRange(location: cursor, length: match.range.location - cursor))
            if let url = sources[number], let encoded = url.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed) {
                result += "[[\(number)]](\(encoded))"
            } else {
                result += nsText.substring(with: match.range)
            }
            cursor = match.range.location + match.range.length
        }
        result += nsText.substring(from: cursor)
        return result
    }
}

// MARK: - Card

/// Chat `Card(children, sources?)`: the vertical container for a whole response.
@available(iOS 17.0, macOS 14.0, *)
struct ChatCardView: View {
    let context: ComponentContext
    @Environment(\.openUITheme) private var theme

    private var sources: [OpenUIObject] {
        context.props.array("sources").compactMap(\.objectValue)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            context.render(prop: "children")
                .frame(maxWidth: .infinity, alignment: .leading)
            if !sources.isEmpty {
                SourcesStrip(sources: sources, runtime: context.runtime)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .openUISurface("card")
        .environment(\.openUICitationSources, citationMap)
    }

    private var citationMap: [Int: String] {
        var map: [Int: String] = [:]
        for (index, source) in sources.enumerated() {
            if let url = source["url"]?.stringValue, !url.isEmpty { map[index + 1] = url }
        }
        return map
    }
}

@available(iOS 17.0, macOS 14.0, *)
struct SourcesStrip: View {
    let sources: [OpenUIObject]
    let runtime: OpenUIRuntime
    @Environment(\.openUITheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.s) {
            Divider()
            Text(L10n.Sources.title)
                .font(theme.fonts.caption.weight(.semibold))
                .foregroundStyle(theme.colors.textSecondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: theme.spacing.s) {
                    ForEach(Array(sources.enumerated()), id: \.offset) { index, source in
                        Button {
                            guard let url = source["url"]?.stringValue, !url.isEmpty else { return }
                            Task { await runtime.triggerAction(label: "", action: ["type": "open_url", "url": .string(url)]) }
                        } label: {
                            HStack(alignment: .top, spacing: 6) {
                                Text("\(index + 1)")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(theme.colors.onAccent)
                                    .frame(width: 18, height: 18)
                                    .background(theme.colors.accent, in: Circle())
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(source["title"]?.stringValue ?? L10n.Sources.untitled)
                                        .font(theme.fonts.caption.weight(.medium))
                                        .foregroundStyle(theme.colors.textPrimary)
                                        .lineLimit(2)
                                    Text(source["sourceName"]?.stringValue ?? "")
                                        .font(.caption2)
                                        .foregroundStyle(theme.colors.textSecondary)
                                        .lineLimit(1)
                                }
                            }
                            .frame(width: 180, alignment: .leading)
                            .padding(theme.spacing.s)
                            .background(theme.colors.sunkenSurface, in: RoundedRectangle(cornerRadius: theme.radius.small, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

/// Standard `Card(children, variant?, direction?, gap?, align?, justify?, wrap?)`.
@available(iOS 17.0, macOS 14.0, *)
struct StandardCardView: View {
    let context: ComponentContext
    @Environment(\.openUITheme) private var theme

    var body: some View {
        let props = context.props
        let children = props.array("children")
        FlexContainer(
            direction: props.string("direction") ?? "column",
            gap: theme.spacing.value(props.string("gap"), default: theme.spacing.m),
            align: props.string("align"),
            justify: props.string("justify"),
            wrap: props.bool("wrap") ?? false,
            flexibleChildren: true,
            itemCount: children.count
        ) {
            context.render(prop: "children")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .openUISurface(props.string("variant") ?? "card")
    }
}

/// `Stack(children, direction?, gap?, align?, justify?, wrap?)`.
@available(iOS 17.0, macOS 14.0, *)
struct StackView: View {
    let context: ComponentContext
    @Environment(\.openUITheme) private var theme

    private static let flexibleTypes: Set<String> = ["Card", "Stack", "MarkDownRenderer", "Callout", "TextCallout", "Form", "Table"]

    var body: some View {
        let props = context.props
        let children = props.elements("children")
        let wrap = props.bool("wrap") ?? false
        let justify = wrap && props.string("justify") == "between" ? "start" : props.string("justify")
        FlexContainer(
            direction: props.string("direction") ?? "column",
            gap: theme.spacing.value(props.string("gap"), default: theme.spacing.m),
            align: props.string("align"),
            justify: justify,
            wrap: wrap,
            flexibleChildren: !children.isEmpty && children.allSatisfy { Self.flexibleTypes.contains($0.typeName) },
            itemCount: children.count
        ) {
            context.render(prop: "children")
        }
    }
}

// MARK: - Text

/// `TextContent(text, size?)` — markdown text.
@available(iOS 17.0, macOS 14.0, *)
struct TextContentView: View {
    let context: ComponentContext
    @Environment(\.openUITheme) private var theme
    @Environment(\.openUICitationSources) private var sources

    var body: some View {
        let text = context.props.text("text") ?? ""
        MarkdownView(Citations.link(text, sources: sources), font: font(context.props.string("size")))
            .textSelection(.enabled)
    }

    private func font(_ size: String?) -> Font {
        switch size {
        case "small": return theme.fonts.bodySmall
        case "large": return theme.fonts.bodyLarge
        case "small-heavy": return theme.fonts.bodySmall.weight(.semibold)
        case "large-heavy": return .title2.weight(.bold)
        default: return theme.fonts.body
        }
    }
}

/// `MarkDownRenderer(textMarkdown, variant?)`.
@available(iOS 17.0, macOS 14.0, *)
struct MarkdownRendererView: View {
    let context: ComponentContext
    @Environment(\.openUICitationSources) private var sources

    var body: some View {
        MarkdownView(Citations.link(context.props.text("textMarkdown") ?? "", sources: sources))
            .textSelection(.enabled)
            .openUISurface(context.props.string("variant") ?? "clear")
    }
}

/// `CardHeader(title?, subtitle?)`.
@available(iOS 17.0, macOS 14.0, *)
struct CardHeaderView: View {
    let context: ComponentContext
    @Environment(\.openUITheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            if let title = context.props.text("title"), !title.isEmpty {
                Text(InlineMarkdown.attributed(title))
                    .font(theme.fonts.title)
                    .foregroundStyle(theme.colors.textPrimary)
            }
            if let subtitle = context.props.text("subtitle"), !subtitle.isEmpty {
                Text(InlineMarkdown.attributed(subtitle))
                    .font(theme.fonts.bodySmall)
                    .foregroundStyle(theme.colors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

/// `InlineHeader(heading, description?)`.
@available(iOS 17.0, macOS 14.0, *)
struct InlineHeaderView: View {
    let context: ComponentContext
    @Environment(\.openUITheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(InlineMarkdown.attributed(context.props.text("heading") ?? ""))
                .font(theme.fonts.heading)
                .foregroundStyle(theme.colors.textPrimary)
            if let description = context.props.text("description"), !description.isEmpty {
                Text(InlineMarkdown.attributed(description))
                    .font(theme.fonts.caption)
                    .foregroundStyle(theme.colors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, theme.spacing.xs)
        .accessibilityAddTraits(.isHeader)
    }
}

/// `Label(text)`.
@available(iOS 17.0, macOS 14.0, *)
struct LabelView: View {
    let context: ComponentContext
    @Environment(\.openUITheme) private var theme

    var body: some View {
        Text(context.props.text("text") ?? "")
            .font(theme.fonts.bodySmall.weight(.medium))
            .foregroundStyle(theme.colors.textPrimary)
    }
}

// MARK: - Callouts

/// `Callout(variant, title, description, visible?)` — auto-dismisses after 3s when `visible` is bound.
@available(iOS 17.0, macOS 14.0, *)
struct CalloutView: View {
    let context: ComponentContext
    @Environment(\.openUITheme) private var theme

    var body: some View {
        let field = context.runtime.stateField(name: "visible", binding: context.props["visible"], formName: nil)
        let isVisible = field.isReactive ? (field.value == .bool(true) || field.value == .string("true")) : true
        if isVisible {
            let variant = context.props.string("variant") ?? "info"
            let color = theme.colors.variant(variant)
            HStack(alignment: .top, spacing: theme.spacing.m) {
                Image(systemName: Self.icon(variant))
                    .font(.body.weight(.semibold))
                    .foregroundStyle(color)
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    if let title = context.props.text("title"), !title.isEmpty {
                        Text(title)
                            .font(theme.fonts.bodySmall.weight(.semibold))
                            .foregroundStyle(theme.colors.textPrimary)
                    }
                    if let description = context.props.text("description"), !description.isEmpty {
                        MarkdownView(description, font: theme.fonts.bodySmall, foreground: theme.colors.textSecondary)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(theme.spacing.m)
            .tinted(color, cornerRadius: theme.radius.medium)
            .transition(.opacity.combined(with: .move(edge: .top)))
            .task(id: field.isReactive && isVisible) {
                guard field.isReactive, isVisible else { return }
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                guard !Task.isCancelled else { return }
                withAnimation { field.set(.bool(false)) }
            }
        }
    }

    static func icon(_ variant: String) -> String {
        switch variant {
        case "success": return "checkmark.circle.fill"
        case "warning": return "exclamationmark.triangle.fill"
        case "error", "danger": return "xmark.octagon.fill"
        case "neutral": return "circle.fill"
        default: return "info.circle.fill"
        }
    }
}

/// `TextCallout(variant?, title?, description?)`.
@available(iOS 17.0, macOS 14.0, *)
struct TextCalloutView: View {
    let context: ComponentContext
    @Environment(\.openUITheme) private var theme

    var body: some View {
        let variant = context.props.string("variant") ?? "neutral"
        let color = theme.colors.variant(variant)
        HStack(spacing: 0) {
            Rectangle().fill(color).frame(width: 3)
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                if let title = context.props.text("title"), !title.isEmpty {
                    Text(title)
                        .font(theme.fonts.bodySmall.weight(.semibold))
                        .foregroundStyle(theme.colors.textPrimary)
                }
                if let description = context.props.text("description"), !description.isEmpty {
                    Text(InlineMarkdown.attributed(description))
                        .font(theme.fonts.bodySmall)
                        .foregroundStyle(theme.colors.textSecondary)
                }
            }
            .padding(theme.spacing.m)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .fixedSize(horizontal: false, vertical: true)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: theme.radius.small, style: .continuous))
    }
}

// MARK: - Images

/// `Image(alt, src?)`.
@available(iOS 17.0, macOS 14.0, *)
struct ImageComponentView: View {
    let context: ComponentContext
    var height: CGFloat = 180
    @Environment(\.openUITheme) private var theme

    var body: some View {
        RemoteImage(url: context.props.string("src"), alt: context.props.text("alt"))
            .filling(height: height, cornerRadius: theme.radius.medium)
    }
}

/// `ImageBlock(src, alt?)`.
@available(iOS 17.0, macOS 14.0, *)
struct ImageBlockView: View {
    let context: ComponentContext
    @Environment(\.openUITheme) private var theme

    var body: some View {
        RemoteImage(url: context.props.string("src"), alt: context.props.text("alt"))
            .filling(aspectRatio: 16 / 9, cornerRadius: theme.radius.medium)
    }
}

/// `ImageGallery(images)` — thumbnails with a full-screen preview.
@available(iOS 17.0, macOS 14.0, *)
struct ImageGalleryView: View {
    let context: ComponentContext
    @Environment(\.openUITheme) private var theme
    @State private var selection: Int?

    private var images: [OpenUIObject] {
        context.props.array("images").compactMap(\.objectValue)
    }

    var body: some View {
        if !images.isEmpty {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: theme.spacing.s)], spacing: theme.spacing.s) {
                ForEach(Array(images.enumerated()), id: \.offset) { index, image in
                    Button {
                        selection = index
                    } label: {
                        RemoteImage(url: image["src"]?.stringValue, alt: image["alt"]?.stringValue)
                            .filling(height: 100, cornerRadius: theme.radius.small)
                    }
                    .buttonStyle(.plain)
                }
            }
            .sheet(item: Binding(get: { selection.map(GalleryIndex.init) }, set: { selection = $0?.value })) { item in
                GalleryPreview(images: images, initial: item.value)
            }
        }
    }

    struct GalleryIndex: Identifiable {
        let value: Int
        var id: Int { value }
    }
}

@available(iOS 17.0, macOS 14.0, *)
struct GalleryPreview: View {
    let images: [OpenUIObject]
    @State var index: Int
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openUITheme) private var theme

    init(images: [OpenUIObject], initial: Int) {
        self.images = images
        self._index = State(initialValue: initial)
    }

    var body: some View {
        NavigationStack {
            TabView(selection: $index) {
                ForEach(Array(images.enumerated()), id: \.offset) { offset, image in
                    VStack(spacing: theme.spacing.m) {
                        RemoteImage(url: image["src"]?.stringValue, contentMode: .fit, alt: image["alt"]?.stringValue)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        if let details = image["details"]?.stringValue ?? image["alt"]?.stringValue {
                            Text(details)
                                .font(theme.fonts.bodySmall)
                                .foregroundStyle(theme.colors.textSecondary)
                                .padding(.horizontal)
                        }
                    }
                    .tag(offset)
                }
            }
            #if os(iOS)
            .tabViewStyle(.page)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.Gallery.done) { dismiss() }
                }
            }
        }
    }
}

// MARK: - Misc

/// `CodeBlock(language, codeString)`.
@available(iOS 17.0, macOS 14.0, *)
struct CodeBlockComponentView: View {
    let context: ComponentContext

    var body: some View {
        CodeBlockView(language: context.props.text("language"), code: context.props.text("codeString") ?? "")
    }
}

/// `Separator(orientation?, decorative?)`.
@available(iOS 17.0, macOS 14.0, *)
struct SeparatorView: View {
    let context: ComponentContext

    var body: some View {
        if context.props.string("orientation") == "vertical" {
            Divider().frame(maxHeight: 24)
        } else {
            Divider()
        }
    }
}
