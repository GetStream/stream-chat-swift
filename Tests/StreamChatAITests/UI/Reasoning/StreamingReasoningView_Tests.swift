//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChatAI
import SwiftUI
import XCTest

final class StreamingReasoningView_Tests: XCTestCase {
    func testParagraphsSplitAtBlankLines() {
        let paragraphs = ReasoningParagraph.split("First thought.\nStill first.\n\n\n\nSecond thought.\n\n")

        XCTAssertEqual(paragraphs.map(\.text), ["First thought.\nStill first.", "Second thought."])
        XCTAssertEqual(paragraphs.map(\.id), [0, 1])
    }

    func testAGrowingParagraphKeepsItsIdentity() {
        let before = ReasoningParagraph.split("Settled.\n\nGrow")
        let after = ReasoningParagraph.split("Settled.\n\nGrowing now")

        XCTAssertEqual(before.first, after.first)
        XCTAssertEqual(before.last?.id, after.last?.id)
    }

    func testTheReasoningIsOpenWhileTheModelThinksAndFoldsWhenItIsDone() {
        XCTAssertTrue(StreamingReasoningView.opens(isThinking: true, showsLiveReasoning: true, initiallyExpanded: false))
        XCTAssertFalse(StreamingReasoningView.opens(isThinking: false, showsLiveReasoning: true, initiallyExpanded: false))
        XCTAssertTrue(StreamingReasoningView.opens(isThinking: false, showsLiveReasoning: true, initiallyExpanded: true))
        XCTAssertFalse(StreamingReasoningView.opens(isThinking: true, showsLiveReasoning: false, initiallyExpanded: false))
        // Live reasoning starts folded and unfolds once it appears; finished reasoning opens as asked.
        XCTAssertFalse(StreamingReasoningView(text: "x", isThinking: true).isOpen)
        XCTAssertTrue(StreamingReasoningView(text: "x", isThinking: false, initiallyExpanded: true).isOpen)
    }

    func testTheHeaderCountsTheSecondsWhileThinking() {
        let locale = Locale(identifier: "en_US")

        XCTAssertEqual(StreamingReasoningView.thinkingTitle(elapsed: 0.4, locale: locale), "Thinking…")
        XCTAssertEqual(StreamingReasoningView.thinkingTitle(elapsed: 7.6, locale: locale), "Thinking… 7s")
        XCTAssertEqual(StreamingReasoningView.thinkingTitle(elapsed: 65, locale: locale), "Thinking… 1m 5s")
    }

    @MainActor
    func testNewThoughtsAreRevealedSteadily() {
        let reveal = TextReveal()
        reveal.update("Weighing", animated: false)
        XCTAssertEqual(reveal.shown, "Weighing", "what is there when the view opens shows at once")

        reveal.update("Weighing the two options.", animated: true)
        XCTAssertEqual(reveal.shown, "Weighing", "new thoughts are not dumped in one go")
        reveal.tick()
        XCTAssertTrue(reveal.shown.count > "Weighing".count && reveal.shown.count < "Weighing the two options.".count)
        for _ in 0..<40 { reveal.tick() }
        XCTAssertEqual(reveal.shown, "Weighing the two options.")

        reveal.update("Something else entirely", animated: true)
        XCTAssertEqual(reveal.shown, "Something else entirely", "text that does not carry on replaces what is shown")
        reveal.update("Something else entirely, done", animated: false)
        XCTAssertEqual(reveal.shown, "Something else entirely, done", "once the model is done the rest shows at once")
    }

    func testInlineMarkdownAndHeadingsReadAsText() {
        let text = ReasoningParagraph.attributed("### Plan\nCheck the **order** first")

        XCTAssertEqual(String(text.characters), "Plan\nCheck the order first")
        let bold = text.runs.filter { $0.inlinePresentationIntent?.contains(.stronglyEmphasized) == true }
            .map { String(text[$0.range].characters) }
        XCTAssertEqual(bold, ["Plan", "order"])
    }

    func testUnclosedMarkdownIsShownAsWritten() {
        XCTAssertEqual(String(ReasoningParagraph.attributed("a **half").characters), "a **half")
    }

    func testTheTitleFollowsTheThinking() {
        let locale = Locale(identifier: "en_US")

        XCTAssertEqual(StreamingReasoningView.title(isThinking: true, duration: 4, locale: locale), "Thinking…")
        XCTAssertEqual(StreamingReasoningView.title(isThinking: false, duration: 12.6, locale: locale), "Thought for 12s")
        XCTAssertEqual(StreamingReasoningView.title(isThinking: false, duration: 65, locale: locale), "Thought for 1m 5s")
        XCTAssertEqual(StreamingReasoningView.title(isThinking: false, duration: 0.2, locale: locale), "Thought for 1s")
        XCTAssertEqual(StreamingReasoningView.title(isThinking: false, duration: nil, locale: locale), "Thought process")
    }
}
