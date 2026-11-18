//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChatAI
import XCTest

@MainActor
final class StreamingMessageView_Tests: XCTestCase {
    private let view = StreamingMessageView(content: "", isGenerating: true)

    func test_getNewChunk_whenNewTextExtendsOldText_returnsTheAddition() {
        XCTAssertEqual(view.getNewChunk(oldText: "Hello", newText: "Hello world"), " world")
    }

    func test_getNewChunk_whenTextsDiverge_returnsTextAfterTheCommonPrefix() {
        XCTAssertEqual(view.getNewChunk(oldText: "Hello there", newText: "Hello world"), "world")
    }

    func test_getNewChunk_whenOldTextIsEmpty_returnsWholeText() {
        XCTAssertEqual(view.getNewChunk(oldText: "", newText: "**Bold** start"), "**Bold** start")
    }

    func test_getNewChunk_whenTextIsUnchanged_returnsNothing() {
        XCTAssertEqual(view.getNewChunk(oldText: "Same", newText: "Same"), "")
    }

    func test_getNewChunk_whenAChunkEndsInsideACharacter_returnsTheRestOfIt() {
        let cases: [(old: String, new: String)] = [
            ("Hello\r", "Hello\r\nWorld"),
            ("Nice 👍", "Nice 👍🏽 work"),
            ("🇺", "🇺🇸 flag"),
            ("family 👨", "family 👨‍👩‍👧 ok"),
            ("cafe", "cafe\u{301} au lait")
        ]
        for (old, new) in cases {
            let chunk = view.getNewChunk(oldText: old, newText: new)
            XCTAssertEqual(old + chunk, new, "\(old) + \(chunk)")
        }
    }

    func test_typing_showsAFewLettersAFrameAtThePaceOfTheLetterInterval() {
        XCTAssertEqual(StreamingMessageView.tickInterval(letterInterval: 0.005), 1.0 / 60)
        XCTAssertEqual(StreamingMessageView.charactersPerTick(letterInterval: 0.005), 4)
        XCTAssertEqual(StreamingMessageView.tickInterval(letterInterval: 0.05), 0.05)
        XCTAssertEqual(StreamingMessageView.charactersPerTick(letterInterval: 0.05), 1)
        XCTAssertEqual(StreamingMessageView.charactersPerTick(letterInterval: 0), .max, "everything at once")
        XCTAssertEqual(StreamingMessageView.tickInterval(letterInterval: .infinity), 1.0 / 60)
        XCTAssertEqual(StreamingMessageView.charactersPerTick(letterInterval: .infinity), 1)
    }

    func test_changeListeners_startFromTheTextTheViewAppearedWith() {
        let listeners = StreamingMessageViewChangeListeners(
            text: "Already streamed",
            isGenerating: true,
            onContentChange: { _, _ in },
            onIsGeneratingChange: { _, _ in }
        )

        XCTAssertEqual(listeners.previousValue, "Already streamed", "so its first change doesn't queue the whole text again")
    }
}
