//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChatAI
import XCTest

final class AIConversationExchange_Tests: XCTestCase {
    private let conversation: [ChatMessage] = [.user("u1"), .reply("a1"), .user("u2"), .reply("a2")]

    func test_aMessage_isOnItsWayAndReplacesNothing() {
        let photo = URL(fileURLWithPath: "/tmp/alfama.jpg")
        let exchange = AIConversationExchange(
            id: 1,
            request: AIConversationRequest<ChatMessage>(kind: .message, text: "Hi", attachments: [photo], messageID: "m1"),
            conversation: conversation
        )

        XCTAssertEqual(exchange.pending?.id, "m1")
        XCTAssertEqual(exchange.pending?.text, "Hi")
        XCTAssertEqual(exchange.pending?.attachments.map(\.url), [photo])
        XCTAssertTrue(exchange.replaced.isEmpty)
        XCTAssertEqual(exchange.known, Set(conversation.map { AnyHashable($0.id) }))
    }

    func test_aKindOfItsOwn_isOnItsWayLikeAMessage() {
        let exchange = AIConversationExchange(
            id: 1,
            request: AIConversationRequest<ChatMessage>(kind: "ui_action", text: "Picked Alfama", message: .reply("a2")),
            conversation: conversation
        )

        XCTAssertEqual(exchange.pending?.text, "Picked Alfama")
        XCTAssertTrue(exchange.replaced.isEmpty)
    }

    func test_regenerating_replacesTheReplyAndThoseAfterIt() {
        let exchange = AIConversationExchange(
            id: 1,
            request: AIConversationRequest<ChatMessage>(kind: .regenerate, text: "", message: .reply("a1")),
            conversation: conversation
        )

        XCTAssertNil(exchange.pending)
        XCTAssertEqual(exchange.replaced, ["a1", "u2", "a2"])
    }

    func test_regenerating_aReplyNotInTheConversation_replacesNothing() {
        let exchange = AIConversationExchange(
            id: 1,
            request: AIConversationRequest<ChatMessage>(kind: .regenerate, text: "", message: .reply("gone")),
            conversation: conversation
        )

        XCTAssertTrue(exchange.replaced.isEmpty)
    }

    func test_editing_replacesTheMessageAndThoseAfterIt() {
        let exchange = AIConversationExchange(
            id: 1,
            request: AIConversationRequest<ChatMessage>(kind: .edit, text: "Porto for two", message: .user("u2")),
            conversation: conversation
        )

        XCTAssertEqual(exchange.replaced, ["u2", "a2"])
        XCTAssertEqual(exchange.pending?.text, "Porto for two")
    }

    func test_theReplyStarts_whenANewReplyShowsSomething() {
        let exchange = message()

        XCTAssertFalse(exchange.hasReplyStarted(in: conversation), "the latest reply was there before")
        XCTAssertFalse(exchange.hasReplyStarted(in: conversation + [.user("u3")]))
        XCTAssertFalse(exchange.hasReplyStarted(in: conversation + [.user("u3"), .reply("a3", "", generating: true)]))
        XCTAssertTrue(exchange.hasReplyStarted(in: conversation + [.user("u3"), .reply("a3", "Sure", generating: true)]))
        XCTAssertTrue(exchange.hasReplyStarted(in: conversation + [.user("u3"), .reply("a3", "Sure")]))
        XCTAssertTrue(exchange.hasReplyStarted(in: conversation + [.user("u3"), .reply("a3", "")]), "finished, with nothing to show")
        XCTAssertFalse(exchange.hasReplyStarted(in: []))
    }

    func test_theReplyStarts_whenTheOneWrittenAgainIsRewritten() {
        let exchange = AIConversationExchange(
            id: 1,
            request: AIConversationRequest<ChatMessage>(kind: .regenerate, text: "", message: .reply("a2")),
            conversation: conversation
        )
        let rewriting = Array(conversation.dropLast())

        XCTAssertFalse(exchange.hasReplyStarted(in: conversation), "not rewritten yet")
        XCTAssertFalse(exchange.hasReplyStarted(in: rewriting + [.reply("a2", "", generating: true)]))
        XCTAssertTrue(exchange.hasReplyStarted(in: rewriting + [.reply("a2", "Another", generating: true)]))
    }

    func test_anOldReplyStillBeingWritten_isNotTheNewOne() {
        let writing: [ChatMessage] = [.user("u1"), .reply("a1", "Day one", generating: true)]
        let exchange = AIConversationExchange(
            id: 1,
            request: AIConversationRequest<ChatMessage>(kind: .message, text: "Make it three days"),
            conversation: writing
        )

        XCTAssertFalse(exchange.hasReplyStarted(in: [.user("u1"), .reply("a1", "Day one, day two", generating: true)]))
    }

    func test_requestKinds() {
        XCTAssertEqual(AIConversationRequestKind.message.rawValue, "message")
        XCTAssertEqual(AIConversationRequestKind.regenerate.rawValue, "regenerate")
        XCTAssertEqual(AIConversationRequestKind.edit.description, "edit")
        XCTAssertEqual(AIConversationRequest<ChatMessage>.Kind(rawValue: "edit"), .edit)
    }

    func test_request_hasAMessageIDOfItsOwnByDefault() {
        let first = AIConversationRequest<ChatMessage>(kind: .message, text: "Hi")
        let second = AIConversationRequest<ChatMessage>(kind: .message, text: "Hi")

        XCTAssertFalse(first.messageID.isEmpty)
        XCTAssertNotEqual(first.messageID, second.messageID)
        XCTAssertTrue(first.attachments.isEmpty)
        XCTAssertNil(first.chatOption)
        XCTAssertNil(first.message)
    }

    private func message() -> AIConversationExchange<ChatMessage> {
        AIConversationExchange(id: 1, request: AIConversationRequest(kind: .message, text: "Hi"), conversation: conversation)
    }
}
