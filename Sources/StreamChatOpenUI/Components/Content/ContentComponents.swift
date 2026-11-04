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

// Turns `[1]` citations into links to their sources, leaving code spans and fenced code as written.
@available(iOS 17.0, macOS 14.0, *)
enum Citations {
    static func link(_ text: String, sources: [Int: String]) -> String {
        guard !sources.isEmpty, text.contains("[") else { return text }
        var result = ""
        result.reserveCapacity(text.utf8.count)
        var fence: Substring?
        for (index, line) in text.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
            if index > 0 { result += "\n" }
            let trimmed = line.drop { $0 == " " || $0 == "\t" }
            if let marker = fence {
                if trimmed.hasPrefix(marker) { fence = nil }
                result += line
            } else if trimmed.hasPrefix("```") || trimmed.hasPrefix("~~~") {
                fence = trimmed.prefix(3)
                result += line
            } else {
                result += linkLine(Array(line), sources: sources)
            }
        }
        return result
    }

    private static func linkLine(_ line: [Character], sources: [Int: String]) -> String {
        var result = ""
        var index = 0
        while index < line.count {
            let character = line[index]
            if character == "`" {
                let end = codeSpanEnd(line, from: index)
                result += String(line[index..<end])
                index = end
            } else if character == "[", let (number, end) = citation(line, at: index), let url = sources[number], let destination = destination(url) {
                result += "[[\(number)]](\(destination))"
                index = end
            } else {
                result.append(character)
                index += 1
            }
        }
        return result
    }

    // The end of the code span opened at `start`, or just past its backticks when it isn't closed.
    private static func codeSpanEnd(_ line: [Character], from start: Int) -> Int {
        var openEnd = start
        while openEnd < line.count, line[openEnd] == "`" { openEnd += 1 }
        let length = openEnd - start
        var index = openEnd
        while index < line.count {
            guard line[index] == "`" else {
                index += 1
                continue
            }
            var runEnd = index
            while runEnd < line.count, line[runEnd] == "`" { runEnd += 1 }
            if runEnd - index == length { return runEnd }
            index = runEnd
        }
        return openEnd
    }

    // `[n]` with one or two digits that isn't already a link, a link's text or an escaped bracket.
    private static func citation(_ line: [Character], at start: Int) -> (number: Int, end: Int)? {
        if start > 0, line[start - 1] == "[" || line[start - 1] == "\\" { return nil }
        var index = start + 1
        var digits = ""
        while index < line.count, digits.count < 3, let digit = line[index].wholeNumberValue, line[index].isASCII {
            digits.append(String(digit))
            index += 1
        }
        guard (1...2).contains(digits.count), index < line.count, line[index] == "]", let number = Int(digits) else { return nil }
        let end = index + 1
        if end < line.count, line[end] == "(" || line[end] == ":" { return nil }
        return (number, end)
    }

    // The URL as a Markdown link destination: invalid characters are percent-encoded once, and
    // parentheses are encoded so they can't end the link early.
    static func destination(_ url: String) -> String? {
        guard let parsed = URL(string: url.trimmingCharacters(in: .whitespacesAndNewlines)), parsed.scheme != nil else { return nil }
        return parsed.absoluteString
            .replacingOccurrences(of: "(", with: "%28")
            .replacingOccurrences(of: ")", with: "%29")
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
    @ScaledMetric(relativeTo: .caption2) private var badgeSize: CGFloat = 18
    @ScaledMetric(relativeTo: .caption) private var cardWidth: CGFloat = 180

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
                                    .font(theme.fonts.caption.weight(.bold))
                                    .foregroundStyle(theme.colors.onAccent)
                                    .frame(width: badgeSize, height: badgeSize)
                                    .background(theme.colors.accent, in: Circle())
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(source["title"]?.stringValue ?? L10n.Sources.untitled)
                                        .font(theme.fonts.caption.weight(.medium))
                                        .foregroundStyle(theme.colors.textPrimary)
                                        .lineLimit(2)
                                    Text(source["sourceName"]?.stringValue ?? "")
                                        .font(theme.fonts.caption)
                                        .foregroundStyle(theme.colors.textSecondary)
                                        .lineLimit(1)
                                }
                            }
                            .frame(width: cardWidth, alignment: .leading)
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
                Text(InlineMarkdown.cached(title))
                    .font(theme.fonts.title)
                    .foregroundStyle(theme.colors.textPrimary)
            }
            if let subtitle = context.props.text("subtitle"), !subtitle.isEmpty {
                Text(InlineMarkdown.cached(subtitle))
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
            Text(InlineMarkdown.cached(context.props.text("heading") ?? ""))
                .font(theme.fonts.heading)
                .foregroundStyle(theme.colors.textPrimary)
            if let description = context.props.text("description"), !description.isEmpty {
                Text(InlineMarkdown.cached(description))
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
                    .font(theme.fonts.body.weight(.semibold))
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
                    Text(InlineMarkdown.cached(description))
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
