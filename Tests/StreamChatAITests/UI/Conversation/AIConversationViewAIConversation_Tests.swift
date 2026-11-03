//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamChatAI
import SwiftUI
import XCTest

@MainActor
final class AIConversationViewAIConversation_Tests: XCTestCase {
    private struct ErrorLine: View {
        let text: String

        var body: some View {
            Text(text)
        }
    }

    // MARK: - The conversation

    func test_conversation_readsTheChatAsItShows() {
        let transport = ConversationTransport(messages: [.user("u1"), .reply("a1")])
        let conversation = AIConversation(transport: transport)
        let view = AIConversationView(conversation: conversation)
        let tracker = AIPendingMessageTracker()

        var shown = view.content(tracker)
        XCTAssertEqual(shown.messages.map(\.id), ["u1", "a1"])
        XCTAssertFalse(shown.isThinking)

        conversation.send("Porto?")
        shown = view.content(tracker)

        XCTAssertEqual(shown.messages.count, 3, "the message on its way shows straight away")
        XCTAssertNil(shown.messages.last?.message)
        XCTAssertTrue(shown.isThinking)
    }

    func test_conversation_showsTheAgentThinkingWhileAReplyIsWrittenAgain() {
        let conversation = AIConversation(transport: ConversationTransport(messages: [.user("u1"), .reply("a1")]))
        let view = AIConversationView(conversation: conversation)

        conversation.regenerate(.reply("a1"))
        let shown = view.content(AIPendingMessageTracker())

        XCTAssertEqual(shown.messages.map(\.id), ["u1"])
        XCTAssertTrue(shown.isThinking, "no message is on its way, but a reply is")
    }

    func test_conversation_loadsOlderMessagesWhileThereAreAny() async {
        let transport = ConversationTransport(messages: [.user("u1"), .reply("a1")])
        let conversation = AIConversation(transport: transport)
        let view = AIConversationView(conversation: conversation)

        XCTAssertNil(view.loadOlderMessages())

        transport.feed?.update(hasOlderMessages: true)
        await view.loadOlderMessages()?()

        XCTAssertEqual(transport.loads, 1)
    }

    func test_conversation_makesItsFooterAndEmptyContentAsTheChatChanges() async {
        let transport = ConversationTransport()
        transport.sendError = TransportError()
        let conversation = AIConversation(transport: transport)
        let view = AIConversationView(
            conversation: conversation,
            footer: { ErrorLine(text: conversation.error == nil ? "" : "Couldn't send") },
            emptyContent: { ErrorLine(text: conversation.composerViewModel.text) }
        )

        XCTAssertEqual(view.footer().text, "")
        conversation.send("Hi")
        await settle()
        conversation.composerViewModel.text = "Hello"

        XCTAssertEqual(view.footer().text, "Couldn't send")
        XCTAssertEqual(view.emptyContent().text, "Hello")
    }

    func test_conversation_rowsOfferTheChatsActions() {
        let conversation = AIConversation(transport: ConversationTransport(messages: [.user("u1"), .reply("a1")]))
        let view = AIConversationView(conversation: conversation)
        let entries = view.content(AIPendingMessageTracker()).messages

        XCTAssertTrue(view.messageContent(entries[0]).content.conversation === conversation)
        XCTAssertEqual(view.messageContent(entries[0]).content.approver?.userID, conversation.approver?.userID)
    }

    func test_conversation_withAFactoryOfItsOwn() {
        let approver = AIToolApprover(userID: "u_1", clientID: "ios-1") { _, _ in }
        let conversation = AIConversation(transport: ConversationTransport(messages: [.user("u1"), .reply("a1")]), approver: approver)
        let view = AIConversationView(conversation: conversation, viewFactory: DefaultAIConversationViewFactory.shared)
        let entries = view.content(AIPendingMessageTracker()).messages

        XCTAssertEqual(view.messageContent(entries[1]).content.approver?.userID, "u_1")
    }

    func test_chat_tellsTheConversationWhenItChanges() {
        let transport = ConversationTransport()
        let conversation = AIConversation(transport: transport)
        var changes = 0
        let following = conversation.changes.objectWillChange.sink { changes += 1 }

        transport.update([.user("u1")])
        conversation.send("Hi")

        XCTAssertGreaterThan(changes, 0)
        following.cancel()
    }

    func test_conversationGivenItsMessages_followsNothing() {
        var changes = 0
        let following = AIObservedChanges.none.objectWillChange.sink { changes += 1 }
        let view = AIConversationView(messages: [ChatMessage.user("u1")], loadOlderMessages: {})
        let entries = view.content(AIPendingMessageTracker()).messages

        XCTAssertNotNil(view.loadOlderMessages())
        XCTAssertNil(view.messageContent(entries[0]).content.conversation)
        XCTAssertEqual(changes, 0)
        following.cancel()
    }

    // MARK: - Rows

    func test_row_changesWhenTheReplyIsRated() {
        let conversation = AIConversation(transport: ConversationTransport(messages: [.user("u1"), .reply("a1")]))
        let before = row(.reply("a1"), latest: true, conversation: conversation)

        conversation.rate(.reply("a1"), .positive)

        XCTAssertNotEqual(before, row(.reply("a1"), latest: true, conversation: conversation))
        XCTAssertEqual(row(.reply("a1"), latest: true, conversation: conversation), row(.reply("a1"), latest: true, conversation: conversation))
    }

    func test_row_changesWhenRegeneratingStopsBeingOffered() {
        let conversation = AIConversation(transport: ConversationTransport(messages: [.user("u1"), .reply("a1")]))
        let before = row(.reply("a1"), latest: true, conversation: conversation)

        conversation.send("Hi")

        XCTAssertNotEqual(before, row(.reply("a1"), latest: true, conversation: conversation), "the agent is answering")
        XCTAssertTrue(before.shown.offersRegenerate)
        XCTAssertFalse(row(.reply("a1"), latest: false, conversation: conversation).shown.offersRegenerate)
    }

    func test_row_changesWhenEditingStopsBeingOffered() {
        let transport = ConversationTransport(messages: [.user("u1"), .reply("a1")])
        let conversation = AIConversation(transport: transport)
        let before = row(.user("u1"), conversation: conversation)

        transport.update([.user("u1"), .reply("a1"), .user("u2")])

        XCTAssertTrue(before.shown.offersEdit)
        XCTAssertNotEqual(before, row(.user("u1"), conversation: conversation), "it isn't their latest message anymore")
        XCTAssertNil(row(.user("u1"), conversation: conversation).shown.rating)
    }

    func test_row_changesWithAChat() {
        let conversation = AIConversation(transport: ConversationTransport(messages: [.user("u1"), .reply("a1")]))

        XCTAssertNotEqual(row(.reply("a1"), latest: true, conversation: nil), row(.reply("a1"), latest: true, conversation: conversation))
        XCTAssertFalse(row(.reply("a1"), latest: true, conversation: nil).shown.offersRegenerate)
    }

    // MARK: - Composer

    func test_composer_sendsToTheChatAndStopsIt() async {
        let transport = ConversationTransport(messages: [.user("u1"), .reply("a1", "Day one", generating: true)])
        let conversation = AIConversation(transport: transport)
        let composer = AIComposerView(conversation: conversation)

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
        conversation: AIConversation<ChatMessage>?
    ) -> AIConversationEntryView<ChatMessage, DefaultAIConversationViewFactory> {
        let entry = AIConversationEntry(id: AnyHashable(message.id), message: message, sentAttachments: [])
        entry.isLatestReply = latest
        return AIConversationEntryView(entry: entry, factory: .shared, approver: nil, conversation: conversation)
    }
}
