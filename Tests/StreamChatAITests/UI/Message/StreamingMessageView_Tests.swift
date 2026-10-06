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
}
