//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChatAI
import XCTest

final class MarkdownParser_Tests: XCTestCase {
    // Each of these took over 3 seconds to parse on a Mac with cmark-gfm 0.29.0.gfm.4, which StreamChatAI
    // bundled before.
    func test_inputsQuadraticInOldCMark_parseQuickly() {
        let inputs = [
            String(repeating: "|-\nt>|-\n", count: 5000),
            String(repeating: "z_www.", count: 10000),
            String(repeating: " -", count: 20000) + "x" + String(repeating: "\n", count: 20000)
        ]

        for markdown in inputs {
            let start = Date()
            _ = [BlockNode](markdown: markdown)
            XCTAssertLessThan(Date().timeIntervalSince(start), 1, "\(markdown.prefix(12))…")
        }
    }
}
