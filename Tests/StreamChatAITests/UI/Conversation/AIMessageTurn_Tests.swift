//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChatAI
import XCTest

final class AIMessageTurn_Tests: XCTestCase {
    private struct Message: Identifiable {
        var id: String
        var isSentByCurrentUser: Bool
    }

    func test_turns_whenThereAreNoMessages_isEmpty() {
        XCTAssertTrue(turns(of: []).isEmpty)
    }

    func test_turns_startOneTurnForEachMessageThePersonSent() {
        let turns = turns(of: [
            .init(id: "q1", isSentByCurrentUser: true),
            .init(id: "a1", isSentByCurrentUser: false),
            .init(id: "q2", isSentByCurrentUser: true),
            .init(id: "a2", isSentByCurrentUser: false),
            .init(id: "a2-more", isSentByCurrentUser: false)
        ])

        XCTAssertEqual(turns.map(\.id), ["q1", "q2"])
        XCTAssertEqual(turns.map { $0.messages.map(\.id) }, [["q1", "a1"], ["q2", "a2", "a2-more"]])
    }

    func test_turns_whenTheConversationStartsWithReplies_groupsThemInALeadingTurn() {
        let turns = turns(of: [
            .init(id: "greeting", isSentByCurrentUser: false),
            .init(id: "tip", isSentByCurrentUser: false),
            .init(id: "q1", isSentByCurrentUser: true)
        ])

        XCTAssertEqual(turns.map { $0.messages.map(\.id) }, [["greeting", "tip"], ["q1"]])
    }

    func test_turns_whenThePersonSendsSeveralMessagesInARow_startsATurnForEach() {
        let turns = turns(of: [
            .init(id: "q1", isSentByCurrentUser: true),
            .init(id: "q2", isSentByCurrentUser: true),
            .init(id: "a2", isSentByCurrentUser: false)
        ])

        XCTAssertEqual(turns.map { $0.messages.map(\.id) }, [["q1"], ["q2", "a2"]])
    }

    private func turns(of messages: [Message]) -> [AIMessageTurn<Message>] {
        AIMessageTurn.turns(of: messages, isSentByCurrentUser: \.isSentByCurrentUser)
    }
}
