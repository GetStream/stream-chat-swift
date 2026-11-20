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
        XCTAssertEqual(Set(exchange.replaced.keys), ["a1", "u2", "a2"])
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

        XCTAssertEqual(Set(exchange.replaced.keys), ["u2", "a2"])
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
        XCTAssertNotNil(exchange.reply(in: rewriting + [.reply("a2", "", generating: true)]), "it is the reply, which shows nothing yet")
        XCTAssertTrue(exchange.hasReplyStarted(in: rewriting + [.reply("a2", "Another", generating: true)]))
    }

    func test_theReplyStarts_whenTheOneWrittenAgainArrivesFinished() {
        let exchange = AIConversationExchange(
            id: 1,
            request: AIConversationRequest<ChatMessage>(kind: .regenerate, text: "", message: .reply("a2")),
            conversation: conversation
        )
        let rewriting = Array(conversation.dropLast())

        XCTAssertTrue(exchange.hasReplyStarted(in: rewriting + [.reply("a2", "Another plan")]), "an agent that doesn't stream")
        XCTAssertFalse(exchange.hasReplyStarted(in: rewriting + [.reply("a2")]), "the reply as it was")
    }

    func test_theReplyStarts_whenAnEditsReplyIsRewritten() {
        let exchange = AIConversationExchange(
            id: 1,
            request: AIConversationRequest<ChatMessage>(kind: .edit, text: "Porto for two", message: .user("u2")),
            conversation: conversation
        )
        let edited: [ChatMessage] = [.user("u1"), .reply("a1"), .user("u2", "Porto for two")]

        XCTAssertFalse(exchange.hasReplyStarted(in: conversation), "nothing changed yet")
        XCTAssertFalse(exchange.hasReplyStarted(in: edited), "the person's message isn't the reply")
        XCTAssertFalse(exchange.hasReplyStarted(in: edited + [.reply("a2")]), "the reply as it was")
        XCTAssertTrue(exchange.hasReplyStarted(in: edited + [.reply("a2", "For two", generating: true)]))
        XCTAssertTrue(exchange.hasReplyStarted(in: edited + [.reply("a2", "For two")]))
    }

    func test_anAnswerThatFailedMidway_isNotRewrittenUntilItChanges() {
        let writing: [ChatMessage] = [.user("u1"), .reply("a1", "Day one", generating: true)]
        let exchange = AIConversationExchange(
            id: 1,
            request: AIConversationRequest<ChatMessage>(kind: .regenerate, text: "", message: writing[1]),
            conversation: writing
        )

        XCTAssertNil(exchange.reply(in: writing))
        XCTAssertNil(exchange.reply(in: [.user("u1"), .reply("a1", "Day one")]))
        XCTAssertNotNil(exchange.reply(in: [.user("u1"), .reply("a1", "Day one, day two", generating: true)]))
    }

    func test_theMessageArrives_withItsIDOrAsTheirFirstNewMessage() {
        let exchange = AIConversationExchange(
            id: 1,
            request: AIConversationRequest<ChatMessage>(kind: .message, text: "Hi", messageID: "m1"),
            conversation: conversation
        )

        XCTAssertFalse(exchange.hasMessageArrived(in: conversation))
        XCTAssertTrue(exchange.hasMessageArrived(in: conversation + [.user("m1")]))
        XCTAssertTrue(exchange.hasMessageArrived(in: conversation + [.user("u3")]))
        XCTAssertFalse(exchange.hasMessageArrived(in: [.user("u0"), .reply("a0")] + conversation), "older messages loaded above")
        XCTAssertFalse(exchange.hasMessageArrived(in: conversation + [.reply("a3")]))
    }

    func test_retry_sendsTheRequestAgain_unlessTheAgentCouldntAnswerAMessageItHas() {
        var exchange = AIConversationExchange(
            id: 1,
            request: AIConversationRequest<ChatMessage>(kind: .message, text: "Hi", messageID: "m1"),
            conversation: conversation
        )
        exchange.state = .failed

        XCTAssertEqual(exchange.retryRequest(in: conversation + [.user("m1")]).messageID, "m1", "the same message, which the transport can tell")
        XCTAssertEqual(exchange.retryRequest(in: conversation + [.user("m1")]).kind, .message)

        exchange.state = .unanswered

        XCTAssertEqual(exchange.retryRequest(in: conversation).kind, .message, "its message never arrived")
        let reply = exchange.retryRequest(in: conversation + [.user("m1")])
        XCTAssertEqual(reply.kind, .regenerate)
        XCTAssertEqual(reply.text, "Hi")
        XCTAssertNil(reply.message, "a reply to the latest message")
    }

    func test_thePersonsMessage_showsUntilItsReply_andAfterwardsOnlyForANewMessage() {
        var send = message()
        var edit = AIConversationExchange(
            id: 1,
            request: AIConversationRequest<ChatMessage>(kind: .edit, text: "Porto for two", message: .user("u2")),
            conversation: conversation
        )
        XCTAssertNotNil(send.shownPending)
        XCTAssertNotNil(edit.shownPending)

        for state in [AIConversationExchange<ChatMessage>.State.stopped, .failed, .unanswered] {
            send.state = state
            edit.state = state
            XCTAssertNotNil(send.shownPending)
            XCTAssertNil(edit.shownPending, "the edited message comes back")
            XCTAssertNotEqual(state == .stopped, send.hasFailed)
        }
    }

    func test_theMessageOfTheRequestBefore_isNotItsOwn() {
        let exchange = AIConversationExchange(
            id: 1,
            request: AIConversationRequest<ChatMessage>(kind: .message, text: "Porto?", messageID: "m2"),
            conversation: conversation,
            earlierMessageIDs: ["m1"]
        )

        XCTAssertFalse(exchange.hasMessageArrived(in: conversation + [.user("m1")]), "the message stopped before it arrived")
        XCTAssertTrue(exchange.hasMessageArrived(in: conversation + [.user("m1"), .user("u3")]))
        XCTAssertTrue(exchange.hasMessageArrived(in: conversation + [.user("m2"), .user("m1")]))
        XCTAssertNil(exchange.reply(in: conversation + [.user("m1"), .reply("a3", "Hello")]))
    }

    func test_theMessagesOfTheRequestsBeforeThatHaventArrived_areNotItsOwn() {
        let exchange = AIConversationExchange(
            id: 1,
            request: AIConversationRequest<ChatMessage>(kind: .message, text: "Faro?", messageID: "m3"),
            conversation: conversation + [.user("m0")],
            earlierMessageIDs: ["m0", "m1", "m2"]
        )

        XCTAssertEqual(exchange.earlierMessageIDs, ["m1", "m2"], "m0 arrived")
        XCTAssertEqual(exchange.messageIDsOnTheirWay, ["m1", "m2", "m3"])
        XCTAssertFalse(exchange.hasMessageArrived(in: conversation + [.user("m0"), .user("m2"), .user("m1")]))
        XCTAssertNil(exchange.reply(in: conversation + [.user("m0"), .user("m1"), .reply("a3", "Hello")]), "the reply to m1")
        XCTAssertTrue(exchange.hasMessageArrived(in: conversation + [.user("m0"), .user("m3")]))
        XCTAssertTrue(exchange.hasMessageArrived(in: conversation + [.user("m0"), .user("m1"), .user("u3")]))
    }

    func test_theMessagesOfTheRequestsBefore_areTheLatestFew() {
        let exchange = AIConversationExchange(
            id: 1,
            request: AIConversationRequest<ChatMessage>(kind: .message, text: "Faro?"),
            conversation: conversation,
            earlierMessageIDs: (0..<10).map { "m\($0)" }
        )

        XCTAssertEqual(exchange.earlierMessageIDs, (2..<10).map { "m\($0)" })
    }

    func test_aRegeneratedReply_bringsNoMessageOfItsOwn() {
        let exchange = AIConversationExchange(
            id: 1,
            request: AIConversationRequest<ChatMessage>(kind: .regenerate, text: "", message: .reply("a2"), messageID: "r1"),
            conversation: conversation,
            earlierMessageIDs: ["m1"]
        )

        XCTAssertEqual(exchange.messageIDsOnTheirWay, ["m1"])
    }

    func test_aRetry_keepsMatchingItsOwnMessage() {
        let exchange = AIConversationExchange(
            id: 1,
            request: AIConversationRequest<ChatMessage>(kind: .message, text: "Porto?", messageID: "m1"),
            conversation: conversation,
            earlierMessageIDs: ["m1"]
        )

        XCTAssertFalse(exchange.known.contains("m1"))
        XCTAssertTrue(
            exchange.hasMessageArrived(in: [.user("u1"), .reply("a1"), .user("m1"), .user("u2"), .reply("a2")]),
            "by its id, before the messages there were"
        )
        XCTAssertTrue(exchange.hasMessageArrived(in: conversation + [.user("u3")]))
    }

    func test_aReplyToTheLatestMessage_isOvertakenByANewerOne() {
        let waiting: [ChatMessage] = [.user("u1"), .reply("a1"), .user("u2")]
        let exchange = AIConversationExchange(
            id: 1,
            request: AIConversationRequest<ChatMessage>(kind: .regenerate, text: "Porto?"),
            conversation: waiting
        )

        XCTAssertNil(exchange.overtakingMessageIndex(in: waiting + [.reply("a2", generating: true)]))
        XCTAssertNil(exchange.overtakingMessageIndex(in: [.user("u0"), .reply("a0")] + waiting), "older messages loaded above")
        XCTAssertEqual(exchange.overtakingMessageIndex(in: waiting + [.user("u3")]), 3)
        XCTAssertNil(message().overtakingMessageIndex(in: conversation + [.user("u3")]), "a new message's own")
    }

    func test_aNewMessage_isOvertakenByANewerOneAfterIt() {
        let exchange = AIConversationExchange(
            id: 1,
            request: AIConversationRequest<ChatMessage>(kind: .message, text: "Hi", messageID: "m1"),
            conversation: conversation
        )

        XCTAssertNil(exchange.overtakingMessageIndex(in: conversation))
        XCTAssertNil(exchange.overtakingMessageIndex(in: conversation + [.user("m1"), .reply("a3", "Hello", generating: true)]))
        XCTAssertEqual(exchange.overtakingMessageIndex(in: conversation + [.user("m1"), .user("u4")]), 5)
        XCTAssertEqual(exchange.overtakingMessageIndex(in: conversation + [.user("m1"), .reply("a3", "Hello"), .user("u4")]), 6)
        XCTAssertNil(exchange.overtakingMessageIndex(in: conversation + [.user("u3"), .reply("a3", "Hello")]), "its message, under another id")
        XCTAssertEqual(exchange.overtakingMessageIndex(in: conversation + [.user("u3"), .user("u4")]), 5, "after its message, under another id")
        XCTAssertNil(exchange.overtakingMessageIndex(in: [.user("u0"), .reply("a0")] + conversation), "older messages loaded above")
    }

    func test_aReplyWrittenAgainOrAnEdit_isOvertakenByANewerMessage() {
        let regenerate = AIConversationExchange(
            id: 1,
            request: AIConversationRequest<ChatMessage>(kind: .regenerate, text: "", message: .reply("a2")),
            conversation: conversation
        )
        let edit = AIConversationExchange(
            id: 1,
            request: AIConversationRequest<ChatMessage>(kind: .edit, text: "Porto for two", message: .user("u2"), messageID: "e1"),
            conversation: conversation
        )
        let replaced: [ChatMessage] = [.user("u1"), .reply("a1"), .user("u2")]
        let editedAsNewMessage: [ChatMessage] = [.user("u1"), .reply("a1"), .user("e1", "Porto for two")]

        XCTAssertNil(regenerate.overtakingMessageIndex(in: replaced + [.reply("a3", generating: true)]))
        XCTAssertEqual(regenerate.overtakingMessageIndex(in: replaced + [.user("u3"), .reply("a3", generating: true)]), 3)
        XCTAssertEqual(regenerate.overtakingMessageIndex(in: conversation + [.user("u3")]), 4, "the reply wasn't removed")
        XCTAssertNil(regenerate.overtakingMessageIndex(in: [.user("u0"), .reply("a0")] + replaced), "older messages loaded above")
        XCTAssertNil(edit.overtakingMessageIndex(in: [.user("u1"), .reply("a1"), .user("u2", "Porto for two")]), "the edited message keeps its id")
        XCTAssertEqual(edit.overtakingMessageIndex(in: [.user("u1"), .reply("a1"), .user("u2", "Porto for two"), .user("u3")]), 3)
        XCTAssertNil(edit.overtakingMessageIndex(in: editedAsNewMessage + [.reply("a3", generating: true)]), "its own copy, under its id")
        XCTAssertEqual(edit.overtakingMessageIndex(in: editedAsNewMessage + [.user("u3")]), 3)
        XCTAssertTrue(edit.isBeingAnswered(in: editedAsNewMessage), "its own copy is the latest")
    }

    func test_aFailedRequest_isBeingAnsweredWhenTheAgentWorksOnIt() {
        let message = AIConversationExchange(
            id: 1,
            request: AIConversationRequest<ChatMessage>(kind: .message, text: "Hi", messageID: "m1"),
            conversation: conversation
        )
        let regenerate = AIConversationExchange(
            id: 1,
            request: AIConversationRequest<ChatMessage>(kind: .regenerate, text: "", message: .reply("a2")),
            conversation: conversation
        )

        XCTAssertFalse(message.isBeingAnswered(in: conversation), "its message isn't there")
        XCTAssertTrue(message.isBeingAnswered(in: conversation + [.user("m1")]))
        XCTAssertTrue(message.isBeingAnswered(in: conversation + [.user("m1"), .reply("a3", "", generating: true)]))
        XCTAssertFalse(message.isBeingAnswered(in: conversation + [.user("m1"), .user("u4")]), "a newer message is the latest")
        XCTAssertTrue(regenerate.isBeingAnswered(in: [.user("u1"), .reply("a1"), .user("u2")]), "the reply was removed")
        XCTAssertFalse(regenerate.isBeingAnswered(in: [.user("u1"), .reply("a1"), .user("u2"), .user("u3")]))
        XCTAssertFalse(regenerate.isBeingAnswered(in: conversation), "the reply as it was")
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
