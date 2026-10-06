//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

struct ReasoningParagraph: Identifiable, Equatable {
    let id: Int
    let text: String

    /// Splits reasoning at blank lines. Reasoning only grows at its end, so a paragraph's
    /// position is a stable identity.
    static func split(_ text: String) -> [ReasoningParagraph] {
        text.components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .enumerated()
            .map { ReasoningParagraph(id: $0.offset, text: $0.element) }
    }

    /// Inline Markdown as reasoning models write it: bold, italics, code and links. A
    /// heading reads as a bold line, since a paragraph of thinking has no document to
    /// structure.
    static func attributed(_ paragraph: String) -> AttributedString {
        let source = paragraph
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { line -> String in
                let trimmed = line.drop { $0 == " " }
                guard trimmed.hasPrefix("#") else { return String(line) }
                let heading = trimmed.drop { $0 == "#" }.trimmingCharacters(in: .whitespaces)
                return heading.isEmpty ? String(line) : "**\(heading)**"
            }
            .joined(separator: "\n")
        let options = AttributedString.MarkdownParsingOptions(
            interpretedSyntax: .inlineOnlyPreservingWhitespace,
            failurePolicy: .returnPartiallyParsedIfPossible
        )
        return (try? AttributedString(markdown: source, options: options)) ?? AttributedString(paragraph)
    }
}
