//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamChatAI
import SwiftUI
import XCTest

@MainActor
final class AIConversationViewAIChat_Tests: XCTestCase {
    private struct ErrorLine: View {
        let text: String

        var body: some View {
            Text(text)
        }
    }

    // MARK: - The conversation

    func test_conversation_readsTheChatAsItShows() {
        let transport = ChatTransport(messages: [.user("u1"), .reply("a1")])
        let chat = AIChat(transport: transport)
        let view = AIConversationView(chat: chat)
        let tracker = AIPendingMessageTracker()

        var shown = view.content(tracker)
        XCTAssertEqual(shown.messages.map(\.id), ["u1", "a1"])
        XCTAssertFalse(shown.isThinking)

        chat.send("Porto?")
        shown = view.content(tracker)

        XCTAssertEqual(shown.messages.count, 3, "the message on its way shows straight away")
        XCTAssertNil(shown.messages.last?.message)
        XCTAssertTrue(shown.isThinking)
    }

    func test_conversation_showsTheAgentThinkingWhileAReplyIsWrittenAgain() {
        let chat = AIChat(transport: ChatTransport(messages: [.user("u1"), .reply("a1")]))
        let view = AIConversationView(chat: chat)

        chat.regenerate(.reply("a1"))
        let shown = view.content(AIPendingMessageTracker())

        XCTAssertEqual(shown.messages.map(\.id), ["u1"])
        XCTAssertTrue(shown.isThinking, "no message is on its way, but a reply is")
    }

    func test_conversation_loadsOlderMessagesWhileThereAreAny() async {
        let transport = ChatTransport(messages: [.user("u1"), .reply("a1")])
        let chat = AIChat(transport: transport)
        let view = AIConversationView(chat: chat)

        XCTAssertNil(view.loadOlderMessages())

        transport.feed?.update(hasOlderMessages: true)
        await view.loadOlderMessages()?()

        XCTAssertEqual(transport.loads, 1)
    }

    func test_conversation_makesItsFooterAndEmptyContentAsTheChatChanges() async {
        let transport = ChatTransport()
        transport.sendError = TransportError()
        let chat = AIChat(transport: transport)
        let view = AIConversationView(
            chat: chat,
            footer: { ErrorLine(text: chat.error == nil ? "" : "Couldn't send") },
            emptyContent: { ErrorLine(text: chat.composer.text) }
        )

        XCTAssertEqual(view.footer().text, "")
        chat.send("Hi")
        await settle()
        chat.composer.text = "Hello"

        XCTAssertEqual(view.footer().text, "Couldn't send")
        XCTAssertEqual(view.emptyContent().text, "Hello")
    }

    func test_conversation_rowsOfferTheChatsActions() {
        let chat = AIChat(transport: ChatTransport(messages: [.user("u1"), .reply("a1")]))
        let view = AIConversationView(chat: chat)
        let entries = view.content(AIPendingMessageTracker()).messages

        XCTAssertTrue(view.messageContent(entries[0]).content.chat === chat)
        XCTAssertEqual(view.messageContent(entries[0]).content.approver?.userID, chat.approver?.userID)
    }

    func test_conversation_withAFactoryOfItsOwn() {
        let approver = AIToolApprover(userID: "u_1", clientID: "ios-1") { _, _ in }
        let chat = AIChat(transport: ChatTransport(messages: [.user("u1"), .reply("a1")]), approver: approver)
        let view = AIConversationView(chat: chat, viewFactory: DefaultAIConversationViewFactory.shared)
        let entries = view.content(AIPendingMessageTracker()).messages

        XCTAssertEqual(view.messageContent(entries[1]).content.approver?.userID, "u_1")
    }

    func test_chat_tellsTheConversationWhenItChanges() {
        let transport = ChatTransport()
        let chat = AIChat(transport: transport)
        var changes = 0
        let following = chat.changes.objectWillChange.sink { changes += 1 }

        transport.update([.user("u1")])
        chat.send("Hi")

        XCTAssertGreaterThan(changes, 0)
        following.cancel()
    }

    func test_conversationGivenItsMessages_followsNothing() {
        var changes = 0
        let following = AIObservedChanges.none.objectWillChange.sink { changes += 1 }
        let view = AIConversationView(messages: [ChatMessage.user("u1")], loadOlderMessages: {})
        let entries = view.content(AIPendingMessageTracker()).messages

        XCTAssertNotNil(view.loadOlderMessages())
        XCTAssertNil(view.messageContent(entries[0]).content.chat)
        XCTAssertEqual(changes, 0)
        following.cancel()
    }

    // MARK: - Rows

    func test_row_changesWhenTheReplyIsRated() {
        let chat = AIChat(transport: ChatTransport(messages: [.user("u1"), .reply("a1")]))
        let before = row(.reply("a1"), latest: true, chat: chat)

        chat.rate(.reply("a1"), .positive)

        XCTAssertNotEqual(before, row(.reply("a1"), latest: true, chat: chat))
        XCTAssertEqual(row(.reply("a1"), latest: true, chat: chat), row(.reply("a1"), latest: true, chat: chat))
    }

    func test_row_changesWhenRegeneratingStopsBeingOffered() {
        let chat = AIChat(transport: ChatTransport(messages: [.user("u1"), .reply("a1")]))
        let before = row(.reply("a1"), latest: true, chat: chat)

        chat.send("Hi")

        XCTAssertNotEqual(before, row(.reply("a1"), latest: true, chat: chat), "the agent is answering")
        XCTAssertTrue(before.shown.offersRegenerate)
        XCTAssertFalse(row(.reply("a1"), latest: false, chat: chat).shown.offersRegenerate)
    }

    func test_row_changesWhenEditingStopsBeingOffered() {
        let transport = ChatTransport(messages: [.user("u1"), .reply("a1")])
        let chat = AIChat(transport: transport)
        let before = row(.user("u1"), chat: chat)

        transport.update([.user("u1"), .reply("a1"), .user("u2")])

        XCTAssertTrue(before.shown.offersEdit)
        XCTAssertNotEqual(before, row(.user("u1"), chat: chat), "it isn't their latest message anymore")
        XCTAssertNil(row(.user("u1"), chat: chat).shown.rating)
    }

    func test_row_changesWithAChat() {
        let chat = AIChat(transport: ChatTransport(messages: [.user("u1"), .reply("a1")]))

        XCTAssertNotEqual(row(.reply("a1"), latest: true, chat: nil), row(.reply("a1"), latest: true, chat: chat))
        XCTAssertFalse(row(.reply("a1"), latest: true, chat: nil).shown.offersRegenerate)
    }

    // MARK: - Composer

    func test_composer_sendsToTheChatAndStopsIt() async {
        let transport = ChatTransport(messages: [.user("u1"), .reply("a1", "Day one", generating: true)])
        let chat = AIChat(transport: transport)
        let composer = AIComposerView(chat: chat)

        composer.onStopGenerating?()
        await settle()
        composer.onMessageSend(MessageData(text: "Make it three days"))
        await settle()

        XCTAssertEqual(transport.stops, 1)
        XCTAssertEqual(transport.lastRequest?.text, "Make it three days")
    }

    private func row(
        _ message: ChatMessage,
        latest: Bool = false,
        chat: AIChat<ChatMessage>?
    ) -> AIConversationEntryView<ChatMessage, DefaultAIConversationViewFactory> {
        let entry = AIConversationEntry(id: AnyHashable(message.id), message: message, sentAttachments: [])
        entry.isLatestReply = latest
        return AIConversationEntryView(entry: entry, factory: .shared, approver: nil, chat: chat)
    }
}
