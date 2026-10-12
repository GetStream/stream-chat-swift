//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChatAI
import XCTest

final class AILocalModel_Tests: XCTestCase {
    func testTheNewestTurnsFitTheBudget() {
        let long = String(repeating: "word ", count: 300) // about 500 tokens
        let turns: [AIConversationTurn] = [
            .user("First question \(long)"),
            .assistant("First answer \(long)"),
            .user("Second question"),
            .assistant("Second answer"),
            .user("Third question")
        ]

        XCTAssertEqual(AIConversationTurn.fitting(turns, tokens: 4000), turns)
        XCTAssertEqual(
            AIConversationTurn.fitting(turns, tokens: 600).map(\.text),
            ["First answer \(long)", "Second question", "Second answer", "Third question"]
        )
        XCTAssertEqual(AIConversationTurn.fitting(turns, tokens: 1), [.user("Third question")], "the question always stays")
        XCTAssertEqual(AIConversationTurn.fitting([], tokens: 100), [])
    }

    func testRepeatedTurnsOfOneRoleMergeAndEmptyOnesGo() {
        let turns: [AIConversationTurn] = [.user("Are you there?"), .user("  "), .user("Hello?"), .assistant(""), .user("Anyone?")]

        XCTAssertEqual(AIConversationTurn.fitting(turns, tokens: 1000), [.user("Are you there?\n\nHello?\n\nAnyone?")])
    }

    func testAnUnavailableModelFailsAtOnce() async {
        let model = AIOnDeviceModel()
        guard !model.isAvailable else { return }

        do {
            for try await _ in model.reply(instructions: "", turns: [.user("Hi")]) {}
            XCTFail("expected an error")
        } catch {
            XCTAssertTrue(error is AIOnDeviceModel.Unavailable)
        }
    }
}
