//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamChatAI
import StreamCore
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

    // Notes each time the list makes it.
    private struct Made: View {
        init(_ name: String, in made: Recorder) {
            made.names.append(name)
        }

        var body: some View {
            EmptyView()
        }
    }

    private final class Recorder {
        var names: [String] = []
    }

    private final class RecordingFactory: AIConversationViewFactory {
        var edits: [String: Bool] = [:]
        var actions: [String: AIReplyActions] = [:]

        func makeUserMessageView(options: AIUserMessageViewOptions) -> some View {
            edits[options.message.map { String(describing: $0.id) } ?? "pending"] = options.onEdit != nil
            return EmptyView()
        }

        func makeReplyActionsView(options: AIReplyActionsViewOptions) -> some View {
            actions[String(describing: options.message.id)] = options.actions
            return EmptyView()
        }
    }

    // MARK: - The conversation

    func test_conversation_readsTheConversationAsItShows() {
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

    func test_conversation_doesntShowTheAgentThinkingOnceItIsStopped() {
        let conversation = AIConversation(transport: ConversationTransport(messages: [.user("u1"), .reply("a1")]))
        let view = AIConversationView(conversation: conversation)
        let tracker = AIPendingMessageTracker()
        conversation.send("Porto?")
        XCTAssertTrue(view.content(tracker).isThinking)

        conversation.stop()
        let shown = view.content(tracker)

        XCTAssertFalse(shown.isThinking)
        XCTAssertEqual(shown.messages.count, 3, "the person's message stays")
    }

    func test_emptyConversation_showsItsFooterUnderTheEmptyContent() throws {
        guard #available(iOS 16, *) else { throw XCTSkip("The list renders with ImageRenderer") }
        let made = Recorder()
        let view = AIConversationView(
            conversation: AIConversation(transport: ConversationTransport()),
            footer: { Made("footer", in: made) },
            emptyContent: { Made("empty", in: made) }
        )

        render(view)

        XCTAssertTrue(made.names.contains("empty"))
        XCTAssertTrue(made.names.contains("footer"), "such as the error of a first message that failed")
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

    func test_conversation_makesItsFooterAndEmptyContentAsTheConversationChanges() async {
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

    func test_conversation_rowsOfferTheConversationsActions() {
        let conversation = AIConversation(transport: ConversationTransport(messages: [.user("u1"), .reply("a1")]))
        let view = AIConversationView(conversation: conversation)
        let entries = view.content(AIPendingMessageTracker()).messages

        XCTAssertTrue(view.messageContent(entries[0]).content.conversation === conversation)
        XCTAssertEqual(view.messageContent(entries[0]).content.approver?.userID, conversation.approver?.userID)
    }

    func test_rows_handTheConversationsActionsToTheFactory() throws {
        guard #available(iOS 16, *) else { throw XCTSkip("Rows render with ImageRenderer") }
        let conversation = AIConversation(transport: ConversationTransport(messages: [.user("u1"), .reply("a1"), .user("u2"), .reply("a2")]))
        let factory = RecordingFactory()
        let view = AIConversationView(conversation: conversation, viewFactory: factory)
        let entries = view.content(AIPendingMessageTracker()).messages

        for entry in entries {
            render(AIConversationEntryView(entry: entry, factory: factory, approver: nil, conversation: conversation))
        }

        XCTAssertEqual(factory.edits, ["u1": false, "u2": true], "the person edits their latest message")
        XCTAssertNil(factory.actions["a1"]?.onRegenerate, "only the latest reply is written again")
        XCTAssertNotNil(factory.actions["a2"]?.onRegenerate)
        factory.actions["a1"]?.onRate?(.positive)

        XCTAssertEqual(conversation.ratings["a1"], .positive)
    }

    func test_conversation_withAFactoryOfItsOwn() {
        let approver = AIToolApprover(userID: "u_1", clientID: "ios-1") { _, _ in }
        let conversation = AIConversation(transport: ConversationTransport(messages: [.user("u1"), .reply("a1")]), approver: approver)
        let view = AIConversationView(conversation: conversation, viewFactory: DefaultAIConversationViewFactory.shared)
        let entries = view.content(AIPendingMessageTracker()).messages

        XCTAssertEqual(view.messageContent(entries[1]).content.approver?.userID, "u_1")
    }

    func test_conversation_tellsItsViewWhenItChanges() {
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

    // MARK: - The conversation's generated UI

    func test_conversationWithUI_showsAReplyThatShowsOnlyItsUIRatherThanTheAgentThinking() {
        let question = ChatMessage.user("u1")
        var reply = ChatMessage.reply("a1", "", generating: true)
        reply.uiDocument = AIUIDocument(format: .openUI, content: .string("root = Card([])"))
        let conversation = AIConversation(transport: ConversationTransport(messages: [question, reply]))
        let host = AIUIHost { AIUIHost_Tests.TestRenderer() } send: { _ in }

        let withoutUI = AIConversationView(conversation: conversation).content(AIPendingMessageTracker())
        let withUI = AIConversationView(conversation: conversation, ui: host).content(AIPendingMessageTracker())

        XCTAssertEqual(conversation.status, .submitted, "the conversation can't tell the reply shows anything")
        XCTAssertEqual(withoutUI.messages.map(\.id), ["u1"])
        XCTAssertTrue(withoutUI.isThinking)
        XCTAssertEqual(withUI.messages.map(\.id), ["u1", "a1"])
        XCTAssertFalse(withUI.isThinking, "the reply's UI shows")
    }

    func test_conversationWithUI_showsTheAgentThinkingWhileNothingReadsTheReplysUI() {
        var reply = ChatMessage.reply("a1", "", generating: true)
        reply.uiDocument = AIUIDocument(format: "cards", content: .string("{}"))
        let conversation = AIConversation(transport: ConversationTransport(messages: [.user("u1"), reply]))
        let host = AIUIHost { AIUIHost_Tests.TestRenderer() } send: { _ in }

        let shown = AIConversationView(conversation: conversation, ui: host).content(AIPendingMessageTracker())

        XCTAssertEqual(shown.messages.map(\.id), ["u1"])
        XCTAssertTrue(shown.isThinking)
    }

    func test_conversationWithUI_showsTheAgentThinkingWhileAMessageIsOnItsWay() {
        let conversation = AIConversation(transport: ConversationTransport(messages: [.user("u1"), .reply("a1")]))
        let view = AIConversationView(conversation: conversation, ui: AIUIHost { AIUIHost_Tests.TestRenderer() } send: { _ in })

        conversation.send("Porto?")
        let shown = view.content(AIPendingMessageTracker())

        XCTAssertEqual(shown.messages.count, 3)
        XCTAssertTrue(shown.isThinking, "the latest reply is the previous message's")
    }

    func test_conversationWithUI_givesEveryReplysUIToTheEnginesBeforeItsRowsShow() throws {
        let replies = (0..<3).map { index in
            var reply = ChatMessage.reply("a\(index)")
            reply.uiDocument = AIUIDocument(format: .openUI, content: .string("root = Card([t\(index)])"))
            return reply
        }
        let conversation = AIConversation(transport: ConversationTransport(messages: [.user("u1")] + replies))
        let renderer = AIUIHost_Tests.TestRenderer()
        let host = AIUIHost { renderer } send: { _ in }

        _ = AIConversationView(conversation: conversation, ui: host).content(AIPendingMessageTracker())

        let engine = try XCTUnwrap(renderer.engines.first)
        XCTAssertEqual(engine.received.map(\.messageID), ["a0", "a1", "a2"])
    }

    func test_conversationWithUI_rowsOfferTheConversationsActions() throws {
        guard #available(iOS 16, *) else { throw XCTSkip("Rows render with ImageRenderer") }
        let conversation = AIConversation(transport: ConversationTransport(messages: [.user("u1"), .reply("a1")]))
        let host = AIUIHost { AIUIHost_Tests.TestRenderer() } send: { _ in }
        let factory = RecordingFactory()
        let view = AIConversationView(conversation: conversation, ui: host, viewFactory: factory)
        let entries = view.content(AIPendingMessageTracker()).messages
        let rated = view.messageContent(entries[1]).content

        for entry in entries {
            render(view.messageContent(entry))
        }

        XCTAssertEqual(factory.edits, ["u1": true])
        XCTAssertNotNil(factory.actions["a1"]?.onRegenerate)
        factory.actions["a1"]?.onRate?(.positive)
        XCTAssertEqual(conversation.ratings["a1"], .positive)
        XCTAssertNotEqual(rated, view.messageContent(entries[1]).content, "the row shows the new rating")
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

    func test_row_changesWithItsConversation() {
        let conversation = AIConversation(transport: ConversationTransport(messages: [.user("u1"), .reply("a1")]))

        XCTAssertNotEqual(row(.reply("a1"), latest: true, conversation: nil), row(.reply("a1"), latest: true, conversation: conversation))
        let another = AIConversation(transport: ConversationTransport(messages: [.user("u1"), .reply("a1")]))
        XCTAssertNotEqual(
            row(.reply("a1"), latest: true, conversation: conversation),
            row(.reply("a1"), latest: true, conversation: another),
            "its actions would act on the conversation it was made with"
        )
        XCTAssertFalse(row(.reply("a1"), latest: true, conversation: nil).shown.offersRegenerate)
    }

    // MARK: - Composer

    func test_composer_sendsToTheConversationAndStopsIt() async {
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

    func test_composer_followsTheConversationItIsGiven() {
        let first = AIConversation(transport: ConversationTransport())
        let second = AIConversation(transport: ConversationTransport())

        XCTAssertTrue(AIComposerView(conversation: first).followedViewModel === first.composerViewModel)
        XCTAssertTrue(AIComposerView(conversation: second).followedViewModel === second.composerViewModel, "not the first one's draft")
        XCTAssertNil(AIComposerView(viewModel: first.composerViewModel) { _ in }.followedViewModel, "a view model given on its own is kept")
    }

    func test_composer_cancelsEditing() {
        let viewModel = AIComposerViewModel()
        viewModel.text = "Plan Porto"
        viewModel.isEditing = true

        viewModel.cancelEditing()

        XCTAssertFalse(viewModel.isEditing)
        XCTAssertEqual(viewModel.text, "")

        viewModel.text = "Half a thought"
        viewModel.cancelEditing()

        XCTAssertEqual(viewModel.text, "Half a thought", "it wasn't editing")
    }

    @available(iOS 16, *)
    private func render(_ view: some View) {
        _ = ImageRenderer(content: view.frame(width: 320, height: 480)).uiImage
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
