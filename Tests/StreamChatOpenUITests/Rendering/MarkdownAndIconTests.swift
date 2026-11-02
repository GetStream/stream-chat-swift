//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChatOpenUI
import SwiftUI
import Testing

@Suite("Icons")
struct IconAccessibilityTests {
    @Test func iconsReadTheirNameInWords() {
        #expect(OpenUIIcons.accessibilityName(for: "arrow-right") == "arrow right")
        #expect(OpenUIIcons.accessibilityName(for: "bar-chart-2") == "bar chart")
        #expect(OpenUIIcons.accessibilityName(for: "checkmark.circle") == "checkmark circle")
        #expect(OpenUIIcons.accessibilityName(for: nil).isEmpty)
    }
}

@MainActor
@Suite("Markdown cache")
struct MarkdownCacheTests {
    @Test func cachedParsesMatchFreshOnes() {
        let text = "# Title\n\nSome **bold** text"

        #expect(MarkdownCache.blocks(for: text) == MarkdownParser.parse(text))
        #expect(MarkdownCache.blocks(for: text) == MarkdownParser.parse(text))
        #expect(InlineMarkdown.cached("a *b*") == InlineMarkdown.attributed("a *b*"))
    }

    @Test func unchangedBlocksCompareEqual() {
        let block = MarkdownBlock.heading(level: 1, text: "Title")

        #expect(MarkdownBlockView(block: block, baseFont: .body, foreground: nil) == MarkdownBlockView(block: block, baseFont: .body, foreground: nil))
        #expect(MarkdownBlockView(block: block, baseFont: .body, foreground: nil) != MarkdownBlockView(block: .paragraph("Title"), baseFont: .body, foreground: nil))
    }
}
