//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChatAI
import XCTest

final class MarkdownParser_Tests: XCTestCase {
    func test_nestedQuotes_keepTheirNesting() {
        let blocks = [BlockNode](markdown: "> a\n>> b\n>>> c")

        XCTAssertEqual(quoteDepth(blocks), 3)
    }

    func test_deeplyNestedQuotes_showAsTextPastTheNestingLimit() {
        let markdown = String(repeating: ">", count: 5000) + " deep"

        let blocks = onSmallStack { [BlockNode](markdown: markdown) }

        XCTAssertEqual(quoteDepth(blocks), MarkdownLimits.maxDepth)
        XCTAssertTrue(texts(blocks).contains { $0.contains("deep") })
    }

    func test_deeplyNestedLists_showAsTextPastTheNestingLimit() {
        let markdown = (0..<200).map { String(repeating: "  ", count: $0) + "- item \($0)" }.joined(separator: "\n")

        let blocks = onSmallStack { [BlockNode](markdown: markdown) }

        XCTAssertEqual(listDepth(blocks), MarkdownLimits.maxDepth)
        XCTAssertTrue(texts(blocks).contains { $0.contains("item 199") })
    }

    // cmark's plain text renderer indents every line by each list around it, so its text can be
    // many times longer than the Markdown.
    func test_textPastTheNestingLimit_isAsLongAsTheContentAtMost() {
        let markdown = String(repeating: "- ", count: 10000) + "x" + String(repeating: "\ny", count: 10000)

        let blocks = onSmallStack { [BlockNode](markdown: markdown) }

        XCTAssertEqual(listDepth(blocks), MarkdownLimits.maxDepth)
        XCTAssertLessThanOrEqual(texts(blocks).joined().utf8.count, markdown.utf8.count)
        XCTAssertTrue(texts(blocks).contains { $0.contains("x y y") })
    }

    func test_deeplyNestedEmphasis_showsAsTextPastTheNestingLimit() {
        let levels = 2000
        let open = (0..<levels).map { $0.isMultiple(of: 2) ? "*a " : "_b " }.joined()
        let close = (0..<levels).reversed().map { $0.isMultiple(of: 2) ? " a*" : " b_" }.joined()

        let blocks = onSmallStack { [BlockNode](markdown: open + "deep" + close) }

        guard case let .paragraph(inlines) = blocks.first else {
            return XCTFail("Expected a paragraph, got \(blocks)")
        }
        XCTAssertLessThanOrEqual(inlineDepth(inlines), MarkdownLimits.maxDepth)
        XCTAssertTrue(texts(blocks).contains { $0.contains("deep") })
    }

    func test_tables_keepTheirCells() {
        let blocks = [BlockNode](markdown: "| a | b |\n| --- | :-: |\n| 1 | 2 |\n| 3 |")

        guard case let .table(alignments, rows) = blocks.first else {
            return XCTFail("Expected a table, got \(blocks)")
        }
        XCTAssertEqual(alignments, [.none, .center])
        XCTAssertEqual(rows.map(\.cells.count), [2, 2, 2])
    }

    // cmark-gfm fills short rows with empty cells: this 8 KB table has 526,000 of them.
    func test_largeTables_showTheColumnsAndRowsThatFitTheLimits() {
        let markdown = "|" + String(repeating: "x|", count: 1000) + "\n|" + String(repeating: "-|", count: 1000) + "\n"
            + String(repeating: "a\n", count: 2000)

        let blocks = [BlockNode](markdown: markdown)

        guard case let .table(alignments, rows) = blocks.first else {
            return XCTFail("Expected a table, got \(blocks.prefix(1))")
        }
        XCTAssertEqual(alignments.count, MarkdownLimits.maxTableColumns)
        XCTAssertTrue(rows.allSatisfy { $0.cells.count == MarkdownLimits.maxTableColumns })
        XCTAssertLessThanOrEqual(rows.count * MarkdownLimits.maxTableColumns, MarkdownLimits.maxTableCells)
    }

    // Each of these took over 3 seconds to parse on a Mac with cmark-gfm 0.29.0.gfm.4, which StreamChatAI
    // bundled before.
    func test_inputsQuadraticInOldCMark_parseQuickly() {
        let inputs = [
            String(repeating: "|-\nt>|-\n", count: 5000),
            String(repeating: "z_www.", count: 10000),
            String(repeating: " -", count: 20000) + "x" + String(repeating: "\n", count: 20000),
            "|" + String(repeating: "x|", count: 5000) + "\n|" + String(repeating: "-|", count: 5000) + "\n"
                + String(repeating: "a\n", count: 5000)
        ]

        for markdown in inputs {
            let start = Date()
            _ = [BlockNode](markdown: markdown)
            XCTAssertLessThan(Date().timeIntervalSince(start), 1, "\(markdown.prefix(12))…")
        }
    }

    private func quoteDepth(_ blocks: [BlockNode]) -> Int {
        blocks.map { block in
            guard case let .blockquote(children) = block else { return 0 }
            return 1 + quoteDepth(children)
        }.max() ?? 0
    }

    private func listDepth(_ blocks: [BlockNode]) -> Int {
        blocks.map { block in
            guard case let .bulletedList(_, items) = block else { return 0 }
            return 1 + (items.map { listDepth($0.children) }.max() ?? 0)
        }.max() ?? 0
    }

    private func inlineDepth(_ inlines: [InlineNode]) -> Int {
        inlines.map { $0.children.isEmpty ? 0 : 1 + inlineDepth($0.children) }.max() ?? 0
    }

    private func texts(_ blocks: [BlockNode]) -> [String] {
        blocks.flatMap { block -> [String] in
            switch block {
            case let .paragraph(inlines):
                return inlines.collect { inline -> [String] in
                    if case let .text(text) = inline { return [text] }
                    return []
                }
            case let .blockquote(children):
                return texts(children)
            case let .bulletedList(_, items):
                return items.flatMap { texts($0.children) }
            default:
                return []
            }
        }
    }
}

// Runs `body` on a thread with half the stack of an iOS app's main thread, where the parser
// overflowed the stack at a few thousand levels of nesting.
func onSmallStack<Result>(_ body: @escaping @Sendable () -> Result) -> Result {
    let box = ResultBox<Result>()
    let done = DispatchSemaphore(value: 0)
    let thread = Thread {
        box.value = body()
        done.signal()
    }
    thread.stackSize = 512 * 1024
    thread.start()
    done.wait()
    return box.value!
}

private final class ResultBox<Value>: @unchecked Sendable {
    var value: Value?
}
