//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChatAI
import XCTest

final class AIConversationScroll_Tests: XCTestCase {
    func test_init_whenATurnIsAddedAfterTheLastOne_scrollsItToTheTop() {
        let scroll = AIConversationScroll(previousLastTurnID: "q1", turnIDs: ["q1", "q2"])

        XCTAssertEqual(scroll, .toTop("q2"))
    }

    func test_init_whenSeveralTurnsAreAdded_scrollsTheLastToTheTop() {
        let scroll = AIConversationScroll(previousLastTurnID: "q1", turnIDs: ["q1", "q2", "q3"])

        XCTAssertEqual(scroll, .toTop("q3"))
    }

    func test_init_whenTheConversationLoads_scrollsToTheEnd() {
        let scroll = AIConversationScroll(previousLastTurnID: nil, turnIDs: ["q1", "q2"])

        XCTAssertEqual(scroll, .toEnd)
    }

    func test_init_whenTheConversationIsReplaced_scrollsToTheEnd() {
        let scroll = AIConversationScroll(previousLastTurnID: "q1", turnIDs: ["other-q1", "other-q2"])

        XCTAssertEqual(scroll, .toEnd)
    }

    func test_init_whenTheLastTurnIsUnchanged_doesNotScroll() {
        let scroll = AIConversationScroll(previousLastTurnID: "q2", turnIDs: ["q0", "q1", "q2"])

        XCTAssertEqual(scroll, .none, "so older messages loading above, or a reply streaming in, keep the position")
    }

    func test_init_whenTheConversationIsCleared_doesNotScroll() {
        let scroll = AIConversationScroll(previousLastTurnID: "q1", turnIDs: [])

        XCTAssertEqual(scroll, .none)
    }
}
