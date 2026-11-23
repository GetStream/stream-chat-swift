//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamChatAI
import SwiftUI
import XCTest

@MainActor
final class CodeHighlighting_Tests: XCTestCase {
    private let colors = CodeColors(plainText: .gray, tokens: [.keyword: .red])

    func test_highlight_colorsTheCode() async throws {
        let highlighting = CodeHighlighting()

        highlighting.highlight("let first = 1")
        try await waitUntil { highlighting.highlighted?.code == "let first = 1" }

        let text = highlighting.text(for: "let first = 1", colors: colors)
        XCTAssertEqual(String(text.characters), "let first = 1")
        XCTAssertEqual(text.runs.first?.foregroundColor, Color.red)
        XCTAssertEqual(text.runs.last?.foregroundColor, Color.gray)
    }

    func test_text_whileCodeIsWritten_keepsTheHighlightedStartAndShowsTheRestPlain() async throws {
        let highlighting = CodeHighlighting()
        highlighting.highlight("let second = 2")
        try await waitUntil { highlighting.highlighted != nil }

        let text = highlighting.text(for: "let second = 2\nlet", colors: colors)

        XCTAssertEqual(String(text.characters), "let second = 2\nlet")
        XCTAssertEqual(text.runs.first?.foregroundColor, Color.red)
        XCTAssertEqual(text.runs.last?.foregroundColor, Color.gray)
    }

    func test_highlight_whileHighlighting_highlightsTheLatestCodeNext() async throws {
        let highlighting = CodeHighlighting()

        highlighting.highlight("let a")
        highlighting.highlight("let a = 1")
        highlighting.highlight("let a = 1 + 2")
        try await waitUntil { highlighting.highlighted?.code == "let a = 1 + 2" }
    }

    func test_highlight_whenALaterVersionIsCached_isNotReplacedByAnEarlierOneStillBeingHighlighted() async throws {
        let earlier = "let \(uniqueName())"
        let later = earlier + " = 1"
        let elsewhere = CodeHighlighting()
        elsewhere.highlight(later)
        try await waitUntil { elsewhere.highlighted?.code == later }
        let highlighting = CodeHighlighting()

        highlighting.highlight(earlier)
        highlighting.highlight(later)
        XCTAssertEqual(highlighting.highlighted?.code, later)
        try await waitUntil { !highlighting.isHighlighting }

        XCTAssertEqual(highlighting.highlighted?.code, later)
    }

    func test_highlight_whenOtherCodeIsAskedForMeanwhile_neverShowsTheOldCode() async throws {
        let old = "let \(uniqueName()) = 1"
        let new = "var \(uniqueName()) = 2"
        let highlighting = CodeHighlighting()
        var shown: [String?] = []
        let subscription = highlighting.$highlighted.sink { shown.append($0?.code) }

        highlighting.highlight(old)
        highlighting.highlight(new)
        try await waitUntil { highlighting.highlighted?.code == new }

        XCTAssertEqual(shown, [nil, new])
        subscription.cancel()
    }

    func test_text_withOtherColors_colorsTheCodeWithThem() async throws {
        let code = "let \(uniqueName()) = 3"
        let blue = CodeColors(plainText: .gray, tokens: [.keyword: .blue])
        let highlighting = CodeHighlighting()
        highlighting.highlight(code)
        try await waitUntil { highlighting.highlighted?.code == code }
        XCTAssertEqual(highlighting.text(for: code, colors: colors).runs.first?.foregroundColor, Color.red)

        XCTAssertEqual(highlighting.text(for: code, colors: blue).runs.first?.foregroundColor, Color.blue)

        let shownAgain = CodeHighlighting()
        shownAgain.highlight(code)
        XCTAssertEqual(shownAgain.text(for: code, colors: blue).runs.first?.foregroundColor, Color.blue)
    }

    func test_highlight_whenCodeIsLongerThanTheLimit_leavesItPlain() async throws {
        let highlighting = CodeHighlighting()
        let code = String(repeating: "a", count: CodeHighlighting.maxLength + 1)

        highlighting.highlight(code)

        XCTAssertFalse(highlighting.isHighlighting)
        XCTAssertNil(highlighting.highlighted)
        XCTAssertEqual(highlighting.text(for: code, colors: colors).runs.first?.foregroundColor, Color.gray)
    }

    // Highlighted code is cached for all code blocks, so a test that needs code highlighted for the
    // first time names something new in it.
    private func uniqueName() -> String {
        "name" + UUID().uuidString.replacingOccurrences(of: "-", with: "")
    }

    private func waitUntil(timeout: TimeInterval = 5, _ condition: () -> Bool) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() {
            guard Date() < deadline else {
                return XCTFail("Timed out")
            }
            try await Task.sleep(nanoseconds: 10_000_000)
        }
    }
}
