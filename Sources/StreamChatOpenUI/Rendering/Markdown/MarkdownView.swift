//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Renders Markdown with native SwiftUI views (headings, paragraphs, lists, task lists, quotes,
/// fenced code, tables and rules; inline emphasis, code and links).
@available(iOS 17.0, macOS 14.0, *)
public struct MarkdownView: View {
    let blocks: [MarkdownBlock]
    let baseFont: Font?
    let foreground: Color?
    @Environment(\.openUITheme) private var theme

    public init(_ text: String, font: Font? = nil, foreground: Color? = nil) {
        self.blocks = MarkdownParser.parse(text)
        self.baseFont = font
        self.foreground = foreground
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.s + 2) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                MarkdownBlockView(block: block, baseFont: baseFont ?? theme.fonts.body, foreground: foreground)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Inline Markdown → `AttributedString` (falls back to plain text when parsing fails).
@available(iOS 17.0, macOS 14.0, *)
enum InlineMarkdown {
    // The model writes the links, so only the schemes react-markdown keeps by default for web
    // links and email open; a link to another app or a phone number shows as plain text.
    static let linkSchemes: Set<String> = ["http", "https", "mailto"]

    static func attributed(_ text: String) -> AttributedString {
        let options = AttributedString.MarkdownParsingOptions(
            allowsExtendedAttributes: false,
            interpretedSyntax: .inlineOnlyPreservingWhitespace,
            failurePolicy: .returnPartiallyParsedIfPossible
        )
        var string = (try? AttributedString(markdown: text, options: options)) ?? AttributedString(text)
        let unsafeLinks = string.runs.filter { run in
            guard let link = run.link else { return false }
            return !linkSchemes.contains(link.scheme?.lowercased() ?? "")
        }.map(\.range)
        for range in unsafeLinks {
            string[range].link = nil
        }
        return string
    }
}

@available(iOS 17.0, macOS 14.0, *)
struct MarkdownBlockView: View {
    let block: MarkdownBlock
    let baseFont: Font
    let foreground: Color?
    @Environment(\.openUITheme) private var theme

    var body: some View {
        switch block {
        case .heading(let level, let text):
            Text(InlineMarkdown.attributed(text))
                .font(headingFont(level))
                .foregroundStyle(foreground ?? theme.colors.textPrimary)
                .padding(.top, level <= 2 ? 4 : 2)
                .fixedSize(horizontal: false, vertical: true)

        case .paragraph(let text):
            Text(InlineMarkdown.attributed(text))
                .font(baseFont)
                .foregroundStyle(foreground ?? theme.colors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

        case .list(let list):
            VStack(alignment: .leading, spacing: theme.spacing.xs + 2) {
                ForEach(Array(list.items.enumerated()), id: \.offset) { offset, item in
                    HStack(alignment: .firstTextBaseline, spacing: theme.spacing.s) {
                        marker(list: list, index: offset, item: item)
                            .font(baseFont)
                            .foregroundStyle(theme.colors.textSecondary)
                            .frame(minWidth: list.ordered ? 22 : 12, alignment: .trailing)
                        VStack(alignment: .leading, spacing: theme.spacing.xs) {
                            Text(InlineMarkdown.attributed(item.text))
                                .font(baseFont)
                                .foregroundStyle(foreground ?? theme.colors.textPrimary)
                                .strikethrough(item.checked == true, color: theme.colors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                            ForEach(Array(item.children.enumerated()), id: \.offset) { _, child in
                                MarkdownBlockView(block: child, baseFont: baseFont, foreground: foreground)
                            }
                        }
                    }
                }
            }

        case .quote(let blocks):
            HStack(alignment: .top, spacing: theme.spacing.m) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(theme.colors.border)
                    .frame(width: 3)
                VStack(alignment: .leading, spacing: theme.spacing.s) {
                    ForEach(Array(blocks.enumerated()), id: \.offset) { _, child in
                        MarkdownBlockView(block: child, baseFont: baseFont, foreground: theme.colors.textSecondary)
                    }
                }
            }
            .fixedSize(horizontal: false, vertical: true)

        case .code(let language, let code):
            CodeBlockView(language: language, code: code)

        case .table(let table):
            MarkdownTableView(table: table, font: baseFont)

        case .rule:
            Divider().padding(.vertical, theme.spacing.xs)
        }
    }

    @ViewBuilder
    private func marker(list: MarkdownList, index: Int, item: MarkdownList.Item) -> some View {
        if let checked = item.checked {
            Image(systemName: checked ? "checkmark.square.fill" : "square")
                .foregroundStyle(checked ? theme.colors.accent : theme.colors.textSecondary)
        } else if list.ordered {
            Text("\(list.start + index).")
                .monospacedDigit()
        } else {
            Text("•")
        }
    }

    private func headingFont(_ level: Int) -> Font {
        switch level {
        case 1: return .title2.weight(.bold)
        case 2: return .title3.weight(.bold)
        case 3: return .headline
        default: return .subheadline.weight(.semibold)
        }
    }
}

@available(iOS 17.0, macOS 14.0, *)
struct MarkdownTableView: View {
    let table: MarkdownTable
    let font: Font
    @Environment(\.openUITheme) private var theme

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Grid(alignment: .leading, horizontalSpacing: 0, verticalSpacing: 0) {
                GridRow {
                    ForEach(Array(table.header.enumerated()), id: \.offset) { column, title in
                        cell(title, column: column)
                            .font(font.weight(.semibold))
                            .background(theme.colors.subtleFill)
                    }
                }
                ForEach(Array(table.rows.enumerated()), id: \.offset) { _, row in
                    Divider().gridCellUnsizedAxes(.horizontal)
                    GridRow {
                        ForEach(Array(row.enumerated()), id: \.offset) { column, value in
                            cell(value, column: column).font(font)
                        }
                    }
                }
            }
            .overlay(RoundedRectangle(cornerRadius: theme.radius.small).stroke(theme.colors.border, lineWidth: 0.5))
            .clipShape(RoundedRectangle(cornerRadius: theme.radius.small))
        }
    }

    private func cell(_ text: String, column: Int) -> some View {
        let alignment: Alignment
        switch column < table.alignments.count ? table.alignments[column] : .leading {
        case .leading: alignment = .leading
        case .center: alignment = .center
        case .trailing: alignment = .trailing
        }
        return Text(InlineMarkdown.attributed(text))
            .foregroundStyle(theme.colors.textPrimary)
            .padding(.horizontal, theme.spacing.m)
            .padding(.vertical, theme.spacing.s)
            .frame(minWidth: 60, maxWidth: 280, alignment: alignment)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// A monospaced code block with an optional language label and copy button.
@available(iOS 17.0, macOS 14.0, *)
public struct CodeBlockView: View {
    let language: String?
    let code: String
    @Environment(\.openUITheme) private var theme
    @State private var copied = false

    public init(language: String?, code: String) {
        self.language = language
        self.code = code
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(language?.isEmpty == false ? language! : L10n.CodeBlock.languageFallback)
                    .font(theme.fonts.caption.weight(.medium))
                    .foregroundStyle(theme.colors.textSecondary)
                Spacer()
                Button {
                    Pasteboard.copy(code)
                    copied = true
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 1_500_000_000)
                        copied = false
                    }
                } label: {
                    Label(copied ? L10n.CodeBlock.copied : L10n.CodeBlock.copy, systemImage: copied ? "checkmark" : "doc.on.doc")
                        .font(theme.fonts.caption)
                }
                .buttonStyle(.borderless)
                .foregroundStyle(theme.colors.textSecondary)
            }
            .padding(.horizontal, theme.spacing.m)
            .padding(.vertical, theme.spacing.s)
            Divider()
            ScrollView(.horizontal, showsIndicators: false) {
                Text(code)
                    .font(theme.fonts.code)
                    .foregroundStyle(theme.colors.textPrimary)
                    .textSelection(.enabled)
                    .padding(theme.spacing.m)
                    .fixedSize(horizontal: true, vertical: true)
            }
        }
        .background(theme.colors.sunkenSurface, in: RoundedRectangle(cornerRadius: theme.radius.small))
    }
}

/// Clipboard access across platforms.
@available(iOS 17.0, macOS 14.0, *)
enum Pasteboard {
    @MainActor
    static func copy(_ string: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = string
        #elseif canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(string, forType: .string)
        #endif
    }
}
