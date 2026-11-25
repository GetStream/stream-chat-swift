//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChatAI
import XCTest

final class Tokenizer_Tests: XCTestCase {
    // The tokenizer called itself once per character of a token or run of whitespace, which
    // overflowed a 512 KiB stack at 400 characters.
    func test_longTokensAndWhitespace_areTokenizedOnASmallStack() {
        let inputs = [
            String(repeating: "a", count: 100_000),
            "x" + String(repeating: " ", count: 100_000) + "y",
            "x" + String(repeating: "\n", count: 100_000) + "y"
        ]

        for code in inputs {
            let tokens = onSmallStack {
                Tokenizer().segmentsByTokenizing(code, using: SwiftGrammar()).map(\.tokens.current)
            }
            XCTAssertEqual(tokens.joined().filter { !$0.isWhitespace }, code.filter { !$0.isWhitespace })
        }
    }

    func test_segments_lookBackAFixedNumberOfTokens() {
        let code = "<" + String(repeating: "A,", count: 2000) + "\n" + String(repeating: "a.b(", count: 2000)

        var segments = 0
        for segment in Tokenizer().segmentsByTokenizing(code, using: SwiftGrammar()) {
            segments += 1
            XCTAssertLessThanOrEqual(segment.tokens.all.count, Tokenizer.maxPreviousTokens)
            XCTAssertLessThanOrEqual(segment.tokens.onSameLine.count, Tokenizer.maxPreviousTokensOnLine)
        }
        XCTAssertGreaterThan(segments, 8000)
    }

    func test_highlighting_keepsTheTypesOfShortLines() {
        let code = "let value: Int = compute(\"text\") // note"
        let highlighter = SyntaxHighlighter(format: TokenTypesFormat())

        let types = highlighter.highlight(code)

        XCTAssertEqual(types["let"], .keyword)
        XCTAssertEqual(types["Int"], .type)
        XCTAssertEqual(types["compute"], .call)
        XCTAssertEqual(types["\"text\""], .string)
        XCTAssertEqual(types["//"], .comment)
    }
}

private struct TokenTypesFormat: OutputFormat {
    struct Builder: OutputBuilder {
        var types: [String: TokenType] = [:]

        mutating func addToken(_ token: String, ofType type: TokenType) {
            types[token] = type
        }

        mutating func addPlainText(_ text: String) {}

        mutating func addWhitespace(_ whitespace: String) {}

        func build() -> [String: TokenType] {
            types
        }
    }

    func makeBuilder() -> Builder {
        Builder()
    }
}
