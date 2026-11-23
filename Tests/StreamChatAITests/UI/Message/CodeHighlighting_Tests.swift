//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChatAI
import SwiftUI
import XCTest

@MainActor
final class CodeHighlighting_Tests: XCTestCase {
    private let format = TextOutputFormat(plainTextColor: .gray, tokenColors: [.keyword: .red])

    func test_highlight_colorsTheCode() async throws {
        let highlighting = CodeHighlighting()

        highlighting.highlight("let first = 1", format: format)
        try await waitUntil { highlighting.highlighted?.code == "let first = 1" }

        let text = highlighting.text(for: "let first = 1", plainTextColor: .gray)
        XCTAssertEqual(String(text.characters), "let first = 1")
        XCTAssertEqual(text.runs.first?.foregroundColor, Color.red)
    }

    func test_text_whileCodeIsWritten_keepsTheHighlightedStartAndShowsTheRestPlain() async throws {
        let highlighting = CodeHighlighting()
        highlighting.highlight("let second = 2", format: format)
        try await waitUntil { highlighting.highlighted != nil }

        let text = highlighting.text(for: "let second = 2\nlet", plainTextColor: .gray)

        XCTAssertEqual(String(text.characters), "let second = 2\nlet")
        XCTAssertEqual(text.runs.first?.foregroundColor, Color.red)
        XCTAssertEqual(text.runs.last?.foregroundColor, Color.gray)
    }

    func test_highlight_whileHighlighting_highlightsTheLatestCodeNext() async throws {
        let highlighting = CodeHighlighting()

        highlighting.highlight("let a", format: format)
        highlighting.highlight("let a = 1", format: format)
        highlighting.highlight("let a = 1 + 2", format: format)
        try await waitUntil { highlighting.highlighted?.code == "let a = 1 + 2" }
    }

    func test_highlight_whenCodeIsLongerThanTheLimit_leavesItPlain() async throws {
        let highlighting = CodeHighlighting()
        let code = String(repeating: "a", count: CodeHighlighting.maxLength + 1)

        highlighting.highlight(code, format: format)
        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNil(highlighting.highlighted)
        XCTAssertEqual(highlighting.text(for: code, plainTextColor: .gray).runs.first?.foregroundColor, Color.gray)
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
