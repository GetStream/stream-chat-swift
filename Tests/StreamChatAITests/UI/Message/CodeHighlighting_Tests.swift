//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChatAI
import SwiftUI
import XCTest

@MainActor
final class CodeHighlighting_Tests: XCTestCase {
    private let colors = CodeColors(plainText: .gray, tokens: [.keyword: .red, .number: .blue])

    func test_highlight_colorsTheCode() async {
        let highlighting = CodeHighlighting()

        await highlighting.highlight("let first = 1")

        let text = highlighting.text(for: "let first = 1", colors: colors)
        XCTAssertEqual(String(text.characters), "let first = 1")
        XCTAssertEqual(text.runs.first?.foregroundColor, Color.red)
        XCTAssertEqual(text.runs.last?.foregroundColor, Color.blue)
    }

    func test_text_whileCodeIsWritten_keepsTheHighlightedStartAndShowsTheRestPlain() async {
        let highlighting = CodeHighlighting()
        await highlighting.highlight("let second = 2")

        let text = highlighting.text(for: "let second = 2\nlet", colors: colors)

        XCTAssertEqual(String(text.characters), "let second = 2\nlet")
        XCTAssertEqual(text.runs.first?.foregroundColor, Color.red)
        XCTAssertEqual(text.runs.last?.foregroundColor, Color.gray)
    }

    func test_text_forCodeThatDoesNotStartWithHighlightedCode_isPlain() async {
        let highlighting = CodeHighlighting()
        await highlighting.highlight("let \(uniqueName()) = 1")

        let text = highlighting.text(for: "let \(uniqueName()) = 2", colors: colors)

        XCTAssertEqual(text.runs.count, 1)
        XCTAssertEqual(text.runs.first?.foregroundColor, Color.gray)
    }

    func test_highlight_severalCodeBlocks_keepsEachHighlighted() async {
        let first = "let \(uniqueName()) = 1"
        let second = "var \(uniqueName()) = 2"
        let highlighting = CodeHighlighting()

        await highlighting.highlight(first)
        await highlighting.highlight(second)

        XCTAssertEqual(highlighting.highlighted.map { $0.code }, [first, second])
        XCTAssertEqual(highlighting.text(for: first + "\n", colors: colors).runs.first?.foregroundColor, Color.red)
        XCTAssertEqual(highlighting.text(for: second + "\n", colors: colors).runs.first?.foregroundColor, Color.red)
    }

    // MarkdownUI makes a code block's view anew each time its code changes, and cancels the task of
    // the view it replaces.
    func test_highlight_whileHighlighting_skipsCodeWhoseViewWentAway() async {
        let first = "let \(uniqueName())"
        let replaced = first + " = 1"
        let latest = first + " = 2"
        let highlighting = CodeHighlighting()

        let highlightingFirst = Task { await highlighting.highlight(first) }
        let highlightingReplaced = Task { await highlighting.highlight(replaced) }
        highlightingReplaced.cancel()
        let highlightingLatest = Task { await highlighting.highlight(latest) }
        await highlightingFirst.value
        await highlightingReplaced.value
        await highlightingLatest.value

        XCTAssertEqual(highlighting.highlighted.map { $0.code }, [latest])
        XCTAssertEqual(highlighting.text(for: replaced, colors: colors).runs.first?.foregroundColor, Color.gray)
    }

    func test_highlight_whenALaterVersionIsCached_isNotReplacedByAnEarlierOneStillBeingHighlighted() async {
        let earlier = "let \(uniqueName())"
        let later = earlier + " = 1"
        await CodeHighlighting().highlight(later)
        let highlighting = CodeHighlighting()

        let highlightingEarlier = Task { await highlighting.highlight(earlier) }
        let highlightingLater = Task { await highlighting.highlight(later) }
        await highlightingLater.value
        await highlightingEarlier.value

        let text = highlighting.text(for: later, colors: colors)
        XCTAssertEqual(String(text.characters), later)
        XCTAssertEqual(text.runs.last?.foregroundColor, Color.blue)
    }

    func test_text_whenAnotherCodeBlockContinuesTheCode_keepsItHighlighted() async {
        let code = "let \(uniqueName()) = 1"
        let continued = code + "\nlet other = 2"
        let highlighting = CodeHighlighting()

        await highlighting.highlight(code)
        await highlighting.highlight(continued)

        XCTAssertEqual(highlighting.highlighted.map { $0.code }, [continued])
        let text = highlighting.text(for: code, colors: colors)
        XCTAssertEqual(text.runs.first?.foregroundColor, Color.red)
        XCTAssertEqual(text.runs.last?.foregroundColor, Color.blue)
    }

    func test_text_withOtherColors_colorsTheCodeWithThem() async {
        let code = "let \(uniqueName()) = 3"
        let green = CodeColors(plainText: .gray, tokens: [.keyword: .green])
        let highlighting = CodeHighlighting()
        await highlighting.highlight(code)
        XCTAssertEqual(highlighting.text(for: code, colors: colors).runs.first?.foregroundColor, Color.red)

        XCTAssertEqual(highlighting.text(for: code, colors: green).runs.first?.foregroundColor, Color.green)

        let shownAgain = CodeHighlighting()
        XCTAssertEqual(shownAgain.text(for: code, colors: green).runs.first?.foregroundColor, Color.green)
    }

    func test_highlight_whenCodeIsLongerThanTheLimit_leavesItPlain() async {
        let highlighting = CodeHighlighting()
        let code = String(repeating: "a", count: CodeHighlighting.maxLength + 1)

        await highlighting.highlight(code)

        XCTAssertTrue(highlighting.highlighted.isEmpty)
        XCTAssertEqual(highlighting.text(for: code, colors: colors).runs.first?.foregroundColor, Color.gray)
    }

    // Highlighted code is cached for all code blocks, so a test that needs code highlighted for the
    // first time names something new in it.
    private func uniqueName() -> String {
        "name" + UUID().uuidString.replacingOccurrences(of: "-", with: "")
    }
}
