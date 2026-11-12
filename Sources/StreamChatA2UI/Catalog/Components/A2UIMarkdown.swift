//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

/// Renders the limited Markdown subset that A2UI `Text` components may contain.
///
/// The basic catalog only exposes `caption` and `body` text variants, so agents
/// express emphasis and hierarchy with Markdown. HTML, images and links are not
/// part of the supported subset.
@available(iOS 15.0, macOS 12.0, *)
struct A2UIMarkdownText: View {
    let text: String
    let isCaption: Bool

    @Environment(\.a2uiTheme) private var theme

    var body: some View {
        let blocks = A2UIMarkdown.blocks(in: text)
        if blocks.count == 1, case let .paragraph(content) = blocks[0] {
            styled(Text(A2UIMarkdown.inline(content)))
        } else {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                    block.view(isCaption: isCaption, theme: theme)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private func styled(_ view: Text) -> some View {
        if isCaption {
            view.font(theme.caption).foregroundColor(theme.secondaryText)
        } else {
            view.font(theme.body)
        }
    }
}

/// A minimal block-level Markdown parser for `Text` components.
@available(iOS 15.0, macOS 12.0, *)
enum A2UIMarkdown {
    /// One block of parsed Markdown content.
    enum Block {
        case heading(level: Int, text: String)
        case bullet(text: String)
        case ordered(number: Int, text: String)
        case quote(text: String)
        case paragraph(String)

        /// Renders the block with the font matching its kind.
        @ViewBuilder
        func view(isCaption: Bool, theme: A2UITheme) -> some View {
            let font = isCaption ? theme.caption : theme.body
            switch self {
            case let .heading(level, text):
                Text(A2UIMarkdown.inline(text))
                    .font(theme.heading(level))
                    .frame(maxWidth: .infinity, alignment: .leading)
            case let .bullet(text):
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("•")
                    Text(A2UIMarkdown.inline(text))
                }
                .font(font)
                .frame(maxWidth: .infinity, alignment: .leading)
            case let .ordered(number, text):
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(number).")
                    Text(A2UIMarkdown.inline(text))
                }
                .font(font)
                .frame(maxWidth: .infinity, alignment: .leading)
            case let .quote(text):
                Text(A2UIMarkdown.inline(text))
                    .font(font)
                    .italic()
                    .foregroundColor(theme.secondaryText)
                    .padding(.leading, 8)
                    .overlay(alignment: .leading) {
                        Rectangle()
                            .frame(width: 2)
                            .foregroundColor(theme.border)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
            case let .paragraph(text):
                if isCaption {
                    Text(A2UIMarkdown.inline(text))
                        .font(font)
                        .foregroundColor(theme.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text(A2UIMarkdown.inline(text))
                        .font(font)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    /// Splits text into block-level Markdown elements.
    /// Consecutive plain lines are joined into a single paragraph.
    static func blocks(in text: String) -> [Block] {
        var blocks: [Block] = []
        var paragraph: [String] = []

        func flushParagraph() {
            guard !paragraph.isEmpty else { return }
            blocks.append(.paragraph(paragraph.joined(separator: " ")))
            paragraph.removeAll()
        }

        for rawLine in text.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.isEmpty {
                flushParagraph()
                continue
            }
            if let heading = headingLevel(of: line) {
                flushParagraph()
                blocks.append(
                    .heading(
                        level: heading,
                        text: String(line.dropFirst(heading)).trimmingCharacters(in: .whitespaces)
                    )
                )
                continue
            }
            if line.hasPrefix("- ") || line.hasPrefix("* ") {
                flushParagraph()
                blocks.append(.bullet(text: String(line.dropFirst(2))))
                continue
            }
            if line.hasPrefix("> ") {
                flushParagraph()
                blocks.append(.quote(text: String(line.dropFirst(2))))
                continue
            }
            if let (number, content) = orderedItem(in: line) {
                flushParagraph()
                blocks.append(.ordered(number: number, text: content))
                continue
            }
            paragraph.append(line)
        }
        flushParagraph()
        return blocks.isEmpty ? [.paragraph(text)] : blocks
    }

    /// Parses inline Markdown such as bold and italic text.
    ///
    /// Links are dropped: the catalog's Markdown has none, and a tappable link
    /// would open a URL without going through `openUrl`. Falls back to plain
    /// text when the markup cannot be parsed.
    static func inline(_ text: String) -> AttributedString {
        guard var attributed = try? AttributedString(
            markdown: text,
            options: AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .inlineOnlyPreservingWhitespace
            )
        ) else {
            return AttributedString(text)
        }
        for run in attributed.runs where run.link != nil {
            attributed[run.range].link = nil
        }
        return attributed
    }

    private static func headingLevel(of line: String) -> Int? {
        guard line.hasPrefix("#") else { return nil }
        let level = line.prefix(while: { $0 == "#" }).count
        guard level <= 6, line.dropFirst(level).hasPrefix(" ") else { return nil }
        return level
    }

    private static func orderedItem(in line: String) -> (Int, String)? {
        let digits = line.prefix(while: { $0.isNumber })
        guard !digits.isEmpty, let number = Int(digits) else { return nil }
        let rest = line.dropFirst(digits.count)
        guard rest.hasPrefix(". ") else { return nil }
        return (number, String(rest.dropFirst(2)))
    }
}
