//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamChatAI
import XCTest

@MainActor
final class AIConversation_Tests: XCTestCase {
    private let photo = URL(fileURLWithPath: "/tmp/alfama.jpg")
    private let plan = URL(fileURLWithPath: "/tmp/itinerary.pdf")

    // MARK: - Following the conversation

    func test_init_connectsToTheTransportAndShowsItsMessages() {
        let transport = ConversationTransport(messages: [.user("u1"), .reply("a1")])
        let conversation = AIConversation(transport: transport)

        XCTAssertNotNil(transport.feed)
        XCTAssertEqual(conversation.messages.ids, ["u1", "a1"])
        XCTAssertEqual(conversation.status, .ready)
        XCTAssertNil(conversation.pendingMessage)
        XCTAssertNil(conversation.error)
        XCTAssertFalse(conversation.hasOlderMessages)
        XCTAssertFalse(conversation.composerViewModel.isGenerating)
    }

    func test_init_keepsTheComposerAndApproverItIsGiven() {
        let composer = AIComposerViewModel()
        let approver = AIToolApprover(userID: "u_1", clientID: "ios-1") { _, _ in }
        let conversation = AIConversation(transport: ConversationTransport(), composerViewModel: composer, approver: approver)

        XCTAssertTrue(conversation.composerViewModel === composer)
        XCTAssertEqual(conversation.approver?.userID, "u_1")
    }

    func test_feed_updatesTheMessagesAndWhetherOlderOnesCanLoad() {
        let transport = ConversationTransport()
        let conversation = AIConversation(transport: transport)

        transport.update([.user("u1"), .reply("a1")])
        transport.feed?.update(hasOlderMessages: true)

        XCTAssertEqual(conversation.messages.ids, ["u1", "a1"])
        XCTAssertTrue(conversation.hasOlderMessages)

        transport.feed?.update(hasOlderMessages: false)

        XCTAssertFalse(conversation.hasOlderMessages)
    }

    func test_feed_goesNowhereOnceTheChatIsReleased() {
        let transport = ConversationTransport()
        var conversation: AIConversation<ChatMessage>? = AIConversation(transport: transport)
        weak var released = conversation

        XCTAssertEqual(transport.feed?.isConnected, true)
        conversation = nil

        XCTAssertNil(released, "the transport doesn't keep its conversation")
        XCTAssertEqual(transport.feed?.isConnected, false)
        transport.update([.user("u1")])
        transport.update(AIAgentActivity(state: .thinking))
        transport.feed?.update(hasOlderMessages: true)
    }

    func test_chat_isReleasedAfterItsRequestsFinish() async {
        let transport = ConversationTransport(messages: [.user("u1"), .reply("a1")])
        var conversation: AIConversation<ChatMessage>? = AIConversation(transport: transport)
        weak var released = conversation

        conversation?.send("Hello")
        conversation?.rate(.reply("a1"), .positive)
        conversation = nil
        await settle()

        XCTAssertNil(released)
    }

    // MARK: - Sending

    func test_send_showsTheMessageAtOnceAndAsksTheTransport() async {
        let transport = ConversationTransport(messages: [.user("u1"), .reply("a1")])
        let conversation = AIConversation(transport: transport)
        let option = ChatOption(id: "think_harder", title: "Think harder", description: "", icon: "brain", shortTitle: "Think")

        conversation.send("And the restaurants?", attachments: [photo, plan], chatOption: option)
        await settle()

        XCTAssertEqual(conversation.status, .submitted)
        XCTAssertTrue(conversation.composerViewModel.isGenerating)
        XCTAssertEqual(conversation.pendingMessage?.text, "And the restaurants?")
        XCTAssertEqual(conversation.pendingMessage?.attachments.map(\.kind), [.image, .file])
        XCTAssertEqual(conversation.pendingMessage?.attachments.map(\.url), [photo, plan])
        let request = transport.lastRequest
        XCTAssertEqual(transport.requests.count, 1)
        XCTAssertEqual(request?.kind, .message)
        XCTAssertEqual(request?.text, "And the restaurants?")
        XCTAssertEqual(request?.attachments, [photo, plan])
        XCTAssertEqual(request?.chatOption, option)
        XCTAssertNil(request?.message)
        XCTAssertEqual(request?.messageID, conversation.pendingMessage?.id, "the transport can give the message the id its copy is found by")
        XCTAssertEqual(conversation.messages.ids, ["u1", "a1"])
    }

    func test_send_ofWhatTheComposerHolds() async {
        let transport = ConversationTransport()
        let conversation = AIConversation(transport: transport)

        conversation.send(MessageData(text: "Hi", attachments: [photo]))
        await settle()

        XCTAssertEqual(transport.lastRequest?.text, "Hi")
        XCTAssertEqual(transport.lastRequest?.attachments, [photo])
    }

    func test_send_ignoresAMessageWithNothingInIt() async {
        let transport = ConversationTransport()
        let conversation = AIConversation(transport: transport)

        conversation.send("  \n ")
        await settle()

        XCTAssertTrue(transport.requests.isEmpty)
        XCTAssertEqual(conversation.status, .ready)
        XCTAssertNil(conversation.pendingMessage)
    }

    func test_send_ofOnlyAttachments() async {
        let transport = ConversationTransport()
        let conversation = AIConversation(transport: transport)

        conversation.send("", attachments: [photo])
        await settle()

        XCTAssertEqual(transport.lastRequest?.attachments, [photo])
        XCTAssertEqual(conversation.status, .submitted)
    }

    func test_send_waitsUntilTheReplyStarts() {
        let transport = ConversationTransport(messages: [.user("u1"), .reply("a1")])
        let conversation = AIConversation(transport: transport)

        conversation.send("And the restaurants?")
        transport.update([.user("u1"), .reply("a1"), .user("u2", "And the restaurants?")])

        XCTAssertNotNil(conversation.pendingMessage, "kept until its reply starts, so the conversation can match its copy")
        XCTAssertEqual(conversation.status, .submitted)

        transport.update([.user("u1"), .reply("a1"), .user("u2"), .reply("a2", "", generating: true)])

        XCTAssertNotNil(conversation.pendingMessage, "a reply that shows nothing hasn't started")
        XCTAssertEqual(conversation.status, .submitted)

        transport.update([.user("u1"), .reply("a1"), .user("u2"), .reply("a2", "Try", generating: true)])

        XCTAssertNil(conversation.pendingMessage)
        XCTAssertEqual(conversation.status, .streaming)
        XCTAssertTrue(conversation.composerViewModel.isGenerating)

        transport.update([.user("u1"), .reply("a1"), .user("u2"), .reply("a2", "Try Taberna da Rua")])

        XCTAssertEqual(conversation.status, .ready)
        XCTAssertFalse(conversation.composerViewModel.isGenerating)
        XCTAssertEqual(conversation.messages.ids, ["u1", "a1", "u2", "a2"])
    }

    func test_send_endsWhenTheReplyArrivesFinished() {
        let transport = ConversationTransport()
        let conversation = AIConversation(transport: transport)

        conversation.send("Hi")
        transport.update([.user("u1", "Hi"), .reply("a1", "Hello!")])

        XCTAssertNil(conversation.pendingMessage)
        XCTAssertEqual(conversation.status, .ready)
    }

    func test_send_endsWhenAReplyFinishesWithNothingInIt() {
        let transport = ConversationTransport()
        let conversation = AIConversation(transport: transport)

        conversation.send("Hi")
        transport.update([.user("u1", "Hi"), .reply("a1", "")])

        XCTAssertNil(conversation.pendingMessage)
        XCTAssertEqual(conversation.status, .ready)
    }

    func test_send_whileAReplyIsWritten_waitsForItsOwnReply() {
        let transport = ConversationTransport(messages: [.user("u1"), .reply("a1", "Day one", generating: true)])
        let conversation = AIConversation(transport: transport)
        XCTAssertEqual(conversation.status, .streaming)

        conversation.send("Make it three days")
        transport.update([.user("u1"), .reply("a1", "Day one, day two", generating: true)])

        XCTAssertNotNil(conversation.pendingMessage)
        XCTAssertEqual(conversation.status, .submitted)

        transport.update([.user("u1"), .reply("a1", "Day one, day two"), .user("u2"), .reply("a2", "Three days", generating: true)])

        XCTAssertNil(conversation.pendingMessage)
        XCTAssertEqual(conversation.status, .streaming)
    }

    func test_send_whenTheTransportFails_showsTheErrorAndRetrySendsItAgain() async {
        let transport = ConversationTransport(messages: [.user("u1"), .reply("a1")])
        transport.sendError = TransportError()
        let conversation = AIConversation(transport: transport)

        conversation.send("And the restaurants?", attachments: [photo])
        await settle()

        XCTAssertEqual(conversation.status, .error)
        XCTAssertTrue(conversation.error is TransportError)
        XCTAssertEqual(conversation.pendingMessage?.text, "And the restaurants?", "the message stays, to try again")
        XCTAssertFalse(conversation.composerViewModel.isGenerating)
        let failed = transport.lastRequest

        transport.sendError = nil
        conversation.retry()
        await settle()

        XCTAssertEqual(transport.requests.count, 2)
        XCTAssertEqual(transport.lastRequest?.kind, .message)
        XCTAssertEqual(transport.lastRequest?.text, "And the restaurants?")
        XCTAssertEqual(transport.lastRequest?.attachments, [photo])
        XCTAssertEqual(transport.lastRequest?.messageID, failed?.messageID, "the transport can tell the message if it arrived the first time")
        XCTAssertNil(conversation.error)
        XCTAssertEqual(conversation.status, .submitted)
        XCTAssertEqual(conversation.pendingMessage?.text, "And the restaurants?")
    }

    func test_send_whenCancelled_showsNoError() async {
        let transport = ConversationTransport()
        transport.sendError = CancellationError()
        let conversation = AIConversation(transport: transport)

        conversation.send("Hi")
        await settle()

        XCTAssertNil(conversation.error)
        XCTAssertEqual(conversation.status, .ready)
        XCTAssertNil(conversation.pendingMessage)
    }

    func test_send_failureOfARequestThatWasOvertaken_isIgnored() async {
        let transport = ConversationTransport()
        transport.holdsSends = true
        let conversation = AIConversation(transport: transport)

        conversation.send("First")
        conversation.send("Second")
        await settle()
        transport.finishSend(0, throwing: TransportError())
        await settle()

        XCTAssertNil(conversation.error)
        XCTAssertEqual(conversation.status, .submitted)
        XCTAssertEqual(conversation.pendingMessage?.text, "Second")

        transport.finishSend(1)
        await settle()

        XCTAssertEqual(conversation.status, .submitted, "a request that reaches the agent waits for its reply")
    }

    func test_send_whenTheReplyStartedBeforeTheTransportReturned() async {
        let transport = ConversationTransport()
        transport.holdsSends = true
        let conversation = AIConversation(transport: transport)

        conversation.send("Hi")
        await settle()
        transport.update([.user("u1", "Hi"), .reply("a1", "Hello", generating: true)])
        transport.finishSend(0)
        await settle()

        XCTAssertEqual(conversation.status, .streaming)
        XCTAssertNil(conversation.pendingMessage)
    }

    func test_send_whenTheReplyArrivesBeforeTheTransportFails_ignoresTheFailure() async {
        let transport = ConversationTransport()
        transport.holdsSends = true
        let conversation = AIConversation(transport: transport)

        conversation.send("Hi")
        await settle()
        transport.update([.user("u1", "Hi"), .reply("a1", "Hello")])
        transport.finishSend(0, throwing: TransportError())
        await settle()

        XCTAssertNil(conversation.error, "the agent had it")
        XCTAssertEqual(conversation.status, .ready)
    }

    func test_send_whenTheTransportFailsWhileAReplyIsWritten_showsTheErrorOnceItIsFinished() async {
        let transport = ConversationTransport(messages: [.user("u1"), .reply("a1", "Day one", generating: true)])
        transport.sendError = TransportError()
        let conversation = AIConversation(transport: transport)

        conversation.send("Make it three days")
        await settle()

        XCTAssertTrue(conversation.error is TransportError)
        XCTAssertEqual(conversation.status, .streaming, "the agent is still answering")

        transport.update([.user("u1"), .reply("a1", "Day one, day two")])

        XCTAssertEqual(conversation.status, .error)
    }

    func test_send_whenTheFailedRequestIsAnsweredAfterAll_forgetsTheError() async {
        let transport = ConversationTransport()
        transport.sendError = TransportError()
        let conversation = AIConversation(transport: transport)
        conversation.send("Hi")
        await settle()

        transport.update([.user("u1", "Hi"), .reply("a1", "Hello", generating: true)])

        XCTAssertNil(conversation.error)
        XCTAssertEqual(conversation.status, .streaming)
    }

    func test_send_whenTheReplyDoesntStartInTime_showsTheAgentsError() async throws {
        let transport = ConversationTransport(messages: [.user("u1"), .reply("a1")])
        let conversation = AIConversation(transport: transport, replyTimeout: 0.05)

        conversation.send("Hi")
        try await waitUntil { conversation.status == .error }

        XCTAssertEqual(conversation.error as? AIAgentError, AIAgentError())
        XCTAssertEqual(conversation.pendingMessage?.text, "Hi")

        transport.update([.user("u1"), .reply("a1"), .user("u2", "Hi"), .reply("a2", "Hello", generating: true)])

        XCTAssertNil(conversation.error, "a late reply")
        XCTAssertEqual(conversation.status, .streaming)
    }

    func test_send_waitsForTheReplyWhileTheAgentSaysItIsWorking() async throws {
        let transport = ConversationTransport(messages: [.user("u1"), .reply("a1")])
        let conversation = AIConversation(transport: transport, replyTimeout: 0.1)
        conversation.send("Hi")
        await settle()

        transport.update(AIAgentActivity(state: .thinking))
        try await Task.sleep(nanoseconds: 400_000_000)

        XCTAssertEqual(conversation.status, .submitted, "however long it thinks")
        XCTAssertNil(conversation.error)

        transport.update(nil)
        try await waitUntil { conversation.status == .error }

        XCTAssertEqual(conversation.error as? AIAgentError, AIAgentError(), "it stopped saying it was working, without answering")
    }

    func test_send_whenTheAgentSaysItIsWorkingBeforeTheTransportReturns_waitsForTheReply() async throws {
        let transport = ConversationTransport(messages: [.user("u1"), .reply("a1")])
        transport.holdsSends = true
        let conversation = AIConversation(transport: transport, replyTimeout: 0.1)
        conversation.send("Hi")
        await settle()

        transport.update(AIAgentActivity(state: .thinking))
        transport.finishSend(0)
        await settle()
        try await Task.sleep(nanoseconds: 400_000_000)

        XCTAssertEqual(conversation.status, .submitted)
    }

    func test_send_withoutATimeout_waitsAsLongAsItTakes() async throws {
        for timeout in [nil, .infinity, 1e30] as [TimeInterval?] {
            let conversation = AIConversation(transport: ConversationTransport(), replyTimeout: timeout)

            conversation.send("Hi")
            try await Task.sleep(nanoseconds: 100_000_000)

            XCTAssertEqual(conversation.status, .submitted)
        }
    }

    func test_send_forgetsThePreviousError() async {
        let transport = ConversationTransport()
        transport.sendError = TransportError()
        let conversation = AIConversation(transport: transport)
        conversation.send("Hi")
        await settle()
        XCTAssertNotNil(conversation.error)

        transport.sendError = nil
        conversation.send("Hi again")

        XCTAssertNil(conversation.error)
        XCTAssertEqual(conversation.status, .submitted)
    }

    // MARK: - Regenerating

    func test_regenerate_asksForANewReplyInPlaceOfTheOld() async {
        let transport = ConversationTransport(messages: [.user("u1", "Lisbon?"), .reply("a1"), .user("u2", "Porto?"), .reply("a2")])
        let conversation = AIConversation(transport: transport)

        conversation.regenerate(.reply("a2"))
        await settle()

        XCTAssertEqual(transport.lastRequest?.kind, .regenerate)
        XCTAssertEqual(transport.lastRequest?.text, "Porto?", "a transport that can only send messages asks again")
        XCTAssertEqual(transport.lastRequest?.message?.id, "a2")
        XCTAssertEqual(conversation.messages.ids, ["u1", "a1", "u2"])
        XCTAssertNil(conversation.pendingMessage)
        XCTAssertEqual(conversation.status, .submitted)
    }

    func test_regenerate_sendsTheReplyAsTheConversationHasIt() async {
        let transport = ConversationTransport(messages: [.user("u1"), .reply("a1", "The latest text")])
        let conversation = AIConversation(transport: transport)

        conversation.regenerate(.reply("a1", "What a view once showed"))
        await settle()

        XCTAssertEqual(transport.lastRequest?.message?.text, "The latest text")
    }

    func test_regenerate_ofAnEarlierReply_leavesOutThoseAfterIt() {
        let transport = ConversationTransport(messages: [.user("u1"), .reply("a1"), .user("u2"), .reply("a2")])
        let conversation = AIConversation(transport: transport)

        conversation.regenerate(.reply("a1"))

        XCTAssertEqual(conversation.messages.ids, ["u1"])
    }

    func test_regenerate_showsTheNewReplyOnceItStarts() {
        let transport = ConversationTransport(messages: [.user("u1"), .reply("a1")])
        let conversation = AIConversation(transport: transport)

        conversation.regenerate(.reply("a1"))
        transport.update([.user("u1")])

        XCTAssertEqual(conversation.status, .submitted)

        transport.update([.user("u1"), .reply("a2", "Another plan", generating: true)])

        XCTAssertEqual(conversation.messages.ids, ["u1", "a2"])
        XCTAssertEqual(conversation.status, .streaming)
    }

    func test_regenerate_whenTheReplyIsRewrittenInPlace() {
        let transport = ConversationTransport(messages: [.user("u1"), .reply("a1")])
        let conversation = AIConversation(transport: transport)

        conversation.regenerate(.reply("a1"))
        transport.update([.user("u1"), .reply("a1", "", generating: true)])

        XCTAssertEqual(conversation.messages.ids, ["u1"])
        XCTAssertEqual(conversation.status, .submitted)

        transport.update([.user("u1"), .reply("a1", "Another", generating: true)])

        XCTAssertEqual(conversation.messages.ids, ["u1", "a1"])
        XCTAssertEqual(conversation.messages.last?.text, "Another")
        XCTAssertEqual(conversation.status, .streaming)
    }

    func test_regenerate_whenTheTransportFails_bringsTheReplyBack() async {
        let transport = ConversationTransport(messages: [.user("u1"), .reply("a1")])
        transport.sendError = TransportError()
        let conversation = AIConversation(transport: transport)

        conversation.regenerate(.reply("a1"))
        await settle()

        XCTAssertEqual(conversation.messages.ids, ["u1", "a1"])
        XCTAssertEqual(conversation.status, .error)

        transport.sendError = nil
        conversation.retry()
        await settle()

        XCTAssertEqual(transport.lastRequest?.kind, .regenerate)
        XCTAssertEqual(transport.lastRequest?.message?.id, "a1")
    }

    func test_regenerate_ignoresThePersonsMessagesAndOnesNotInTheConversation() async {
        let transport = ConversationTransport(messages: [.user("u1"), .reply("a1")])
        let conversation = AIConversation(transport: transport)

        conversation.regenerate(.user("u1"))
        conversation.regenerate(.reply("gone"))
        await settle()

        XCTAssertTrue(transport.requests.isEmpty)
        XCTAssertEqual(conversation.status, .ready)
    }

    func test_regenerate_ofAReplyWithNoMessageBeforeIt() async {
        let transport = ConversationTransport(messages: [.reply("a0", "Hi! How can I help?")])
        let conversation = AIConversation(transport: transport)

        conversation.regenerate(.reply("a0"))
        await settle()

        XCTAssertEqual(transport.lastRequest?.text, "")
        XCTAssertEqual(transport.lastRequest?.message?.id, "a0")
    }

    // MARK: - Editing

    func test_edit_putsTheMessageInTheComposer() {
        let conversation = AIConversation(transport: ConversationTransport(messages: [.user("u1", "Plan Lisbon"), .reply("a1")]))

        conversation.edit(.user("u1", "Plan Lisbon"))

        XCTAssertEqual(conversation.editingMessage?.id, "u1")
        XCTAssertEqual(conversation.composerViewModel.text, "Plan Lisbon")
        XCTAssertTrue(conversation.composerViewModel.isEditing, "the composer shows the person is editing")
        XCTAssertTrue(conversation.composerViewModel.isTextFieldFocused)
    }

    func test_edit_cancelledInTheComposer_sendsANewMessage() async {
        let transport = ConversationTransport(messages: [.user("u1"), .reply("a1"), .user("u2", "Plan Porto"), .reply("a2")])
        let conversation = AIConversation(transport: transport)
        conversation.edit(.user("u2", "Plan Porto"))

        conversation.composerViewModel.cancelEditing()
        conversation.send("What's the weather in Tokyo?")
        await settle()

        XCTAssertNil(conversation.editingMessage)
        XCTAssertEqual(conversation.composerViewModel.text, "")
        XCTAssertEqual(transport.lastRequest?.kind, .message)
        XCTAssertEqual(conversation.messages.ids, ["u1", "a1", "u2", "a2"])
    }

    func test_edit_whenTheTransportFails_bringsTheMessagesBack() async {
        let transport = ConversationTransport(messages: [.user("u1"), .reply("a1")])
        transport.sendError = TransportError()
        let conversation = AIConversation(transport: transport)
        conversation.edit(.user("u1"))

        conversation.send("Plan Porto")
        await settle()

        XCTAssertEqual(conversation.messages.ids, ["u1", "a1"])
        XCTAssertNil(conversation.pendingMessage)
        XCTAssertEqual(conversation.status, .error)

        transport.sendError = nil
        conversation.retry()
        await settle()

        XCTAssertEqual(transport.lastRequest?.kind, .edit)
        XCTAssertEqual(transport.lastRequest?.text, "Plan Porto")
    }

    func test_edit_ignoresReplies() {
        let conversation = AIConversation(transport: ConversationTransport(messages: [.user("u1"), .reply("a1")]))

        conversation.edit(.reply("a1"))

        XCTAssertNil(conversation.editingMessage)
        XCTAssertEqual(conversation.composerViewModel.text, "")
    }

    func test_send_whileEditing_replacesTheMessageAndWhatFollows() async {
        let original = ChatMessage(id: "u2", role: .user, text: "Plan Porto", attachments: [.image(URL(string: "https://example.com/porto.jpg")!)])
        let transport = ConversationTransport(messages: [.user("u1"), .reply("a1"), original, .reply("a2")])
        let conversation = AIConversation(transport: transport)

        conversation.edit(original)
        conversation.send("Plan Porto for two", attachments: [photo])
        await settle()

        XCTAssertNil(conversation.editingMessage)
        XCTAssertFalse(conversation.composerViewModel.isEditing)
        XCTAssertEqual(transport.lastRequest?.kind, .edit)
        XCTAssertEqual(transport.lastRequest?.message?.id, "u2")
        XCTAssertEqual(transport.lastRequest?.text, "Plan Porto for two")
        XCTAssertEqual(conversation.messages.ids, ["u1", "a1"])
        XCTAssertEqual(conversation.pendingMessage?.text, "Plan Porto for two")
        XCTAssertEqual(
            conversation.pendingMessage?.attachments.map(\.url),
            [URL(string: "https://example.com/porto.jpg")!, photo],
            "the edit keeps what the message carried"
        )
        XCTAssertEqual(conversation.status, .submitted)

        transport.update([.user("u1"), .reply("a1"), .user("u2", "Plan Porto for two"), .reply("a3", "For two", generating: true)])

        XCTAssertEqual(conversation.messages.ids, ["u1", "a1", "u2", "a3"])
        XCTAssertNil(conversation.pendingMessage)
        XCTAssertEqual(conversation.status, .streaming)
    }

    func test_cancelEditing_emptiesTheComposer() async {
        let transport = ConversationTransport(messages: [.user("u1"), .reply("a1")])
        let conversation = AIConversation(transport: transport)
        conversation.edit(.user("u1"))

        conversation.cancelEditing()
        conversation.send("Something else")
        await settle()

        XCTAssertNil(conversation.editingMessage)
        XCTAssertEqual(conversation.composerViewModel.text, "")
        XCTAssertEqual(transport.lastRequest?.kind, .message)
    }

    func test_cancelEditing_whenNotEditing_keepsTheComposer() {
        let conversation = AIConversation(transport: ConversationTransport())
        conversation.composerViewModel.text = "Half a thought"

        conversation.cancelEditing()

        XCTAssertEqual(conversation.composerViewModel.text, "Half a thought")
    }

    // MARK: - Stopping

    func test_stop_endsTheReplyAndTellsTheTransport() async {
        let transport = ConversationTransport(messages: [.user("u1"), .reply("a1", "Day one", generating: true)])
        let conversation = AIConversation(transport: transport)
        XCTAssertEqual(conversation.status, .streaming)

        conversation.stop()
        await settle()

        XCTAssertEqual(transport.stops, 1)
        XCTAssertEqual(conversation.status, .ready)
        XCTAssertFalse(conversation.composerViewModel.isGenerating)

        transport.update([.user("u1"), .reply("a1", "Day one", generating: true)])

        XCTAssertEqual(conversation.status, .ready, "a stopped reply is finished, however long the conversation says otherwise")
        XCTAssertEqual(conversation.messages.ids, ["u1", "a1"], "what it wrote so far stays")
    }

    func test_stop_whileWaiting_keepsThePersonsMessage() async {
        let transport = ConversationTransport(messages: [.user("u1"), .reply("a1")])
        let conversation = AIConversation(transport: transport)
        conversation.send("Hi")

        conversation.stop()
        await settle()

        XCTAssertEqual(conversation.pendingMessage?.text, "Hi", "it is on its way until its copy arrives")
        XCTAssertEqual(conversation.status, .ready)
        XCTAssertFalse(conversation.composerViewModel.isGenerating)
        XCTAssertEqual(transport.stops, 1)
    }

    func test_stop_whileWaiting_finishesAReplyThatArrivesLater() async {
        let transport = ConversationTransport(messages: [.user("u1"), .reply("a1")])
        let conversation = AIConversation(transport: transport)
        conversation.send("Hi")
        conversation.stop()
        await settle()

        transport.update([.user("u1"), .reply("a1"), .user("u2", "Hi"), .reply("a2", "", generating: true)])

        XCTAssertEqual(conversation.status, .ready)
        XCTAssertEqual(conversation.messages.ids, ["u1", "a1", "u2"], "it has nothing to show")

        transport.update([.user("u1"), .reply("a1"), .user("u2", "Hi"), .reply("a2", "Hello", generating: true)])

        XCTAssertEqual(conversation.status, .ready, "the person stopped it")
        XCTAssertFalse(conversation.composerViewModel.isGenerating)
        XCTAssertEqual(conversation.messages.ids, ["u1", "a1", "u2", "a2"])
        XCTAssertNil(conversation.pendingMessage)
    }

    func test_stop_whileWaiting_letsTheNextRequestsReplyStream() async {
        let transport = ConversationTransport(messages: [.user("u1"), .reply("a1")])
        let conversation = AIConversation(transport: transport)
        conversation.send("Hi")
        conversation.stop()
        await settle()

        conversation.send("Porto?")
        transport.update([.user("u1"), .reply("a1"), .user("u2", "Hi"), .user("u3", "Porto?"), .reply("a3", "Sure", generating: true)])

        XCTAssertEqual(conversation.status, .streaming)
    }

    func test_stop_whileWaitingForARegeneratedReply_bringsTheReplyBack() {
        let transport = ConversationTransport(messages: [.user("u1"), .reply("a1")])
        let conversation = AIConversation(transport: transport)
        conversation.regenerate(.reply("a1"))
        XCTAssertEqual(conversation.messages.ids, ["u1"])

        conversation.stop()

        XCTAssertEqual(conversation.messages.ids, ["u1", "a1"])
        XCTAssertEqual(conversation.status, .ready)
    }

    func test_send_afterAStop_waitsForTheStopToReachTheTransport() async {
        let transport = ConversationTransport(messages: [.user("u1"), .reply("a1", "Day one", generating: true)])
        transport.holdsStops = true
        let conversation = AIConversation(transport: transport)

        conversation.stop()
        conversation.send("Something else")
        await settle()

        XCTAssertEqual(transport.stops, 1)
        XCTAssertTrue(transport.requests.isEmpty, "the stop would stop it too")
        XCTAssertEqual(conversation.status, .submitted)

        transport.finishStop(0)
        await settle()

        XCTAssertEqual(transport.lastRequest?.text, "Something else")
    }

    func test_stop_leavesOutAReplyThatShowsNothing() {
        let transport = ConversationTransport(messages: [.user("u1"), .reply("a1", "", generating: true)])
        let conversation = AIConversation(transport: transport)
        XCTAssertEqual(conversation.status, .submitted)

        conversation.stop()

        XCTAssertEqual(conversation.messages.ids, ["u1"], "the conversation would think it is still on its way")
        XCTAssertEqual(conversation.status, .ready)
    }

    func test_stop_whenNotAnswering_doesNothing() async {
        let transport = ConversationTransport(messages: [.user("u1"), .reply("a1")])
        let conversation = AIConversation(transport: transport)

        conversation.stop()
        await settle()

        XCTAssertEqual(transport.stops, 0)
    }

    func test_stop_ignoresWhatTheAgentSaysUntilItStopsSaying() {
        let transport = ConversationTransport(messages: [.user("u1")])
        let conversation = AIConversation(transport: transport)
        transport.update(AIAgentActivity(state: .thinking))
        XCTAssertEqual(conversation.status, .submitted)

        conversation.stop()
        transport.update(AIAgentActivity(state: .generating))

        XCTAssertNil(conversation.activity)
        XCTAssertEqual(conversation.status, .ready)

        transport.update(nil)
        transport.update(AIAgentActivity(state: .thinking))

        XCTAssertEqual(conversation.activity, AIAgentActivity(state: .thinking))
        XCTAssertEqual(conversation.status, .submitted)
    }

    func test_stop_whenTheTransportFails_showsTheReplyStillBeingWritten() async {
        let transport = ConversationTransport(messages: [.user("u1"), .reply("a1", "Day one", generating: true)])
        transport.stopError = TransportError()
        let conversation = AIConversation(transport: transport)

        conversation.stop()
        await settle()

        XCTAssertNil(conversation.error, "nothing to try again")
        XCTAssertEqual(conversation.status, .streaming)
        XCTAssertTrue(conversation.composerViewModel.isGenerating, "the composer offers to stop it again")

        transport.update([.user("u1"), .reply("a1", "Day one, day two")])

        XCTAssertEqual(conversation.status, .ready)
    }

    func test_stop_whileWaiting_whenTheTransportFails_waitsForTheReplyAgain() async {
        let transport = ConversationTransport(messages: [.user("u1"), .reply("a1")])
        transport.stopError = TransportError()
        let conversation = AIConversation(transport: transport)
        conversation.send("Hi")

        conversation.stop()
        await settle()

        XCTAssertEqual(conversation.status, .submitted)

        transport.update([.user("u1"), .reply("a1"), .user("u2", "Hi"), .reply("a2", "Hello", generating: true)])

        XCTAssertEqual(conversation.status, .streaming)
    }

    func test_stop_failureAfterANewRequest_isIgnored() async {
        let transport = ConversationTransport(messages: [.user("u1"), .reply("a1", "Day one", generating: true)])
        transport.stopError = TransportError()
        let conversation = AIConversation(transport: transport)

        conversation.stop()
        conversation.send("Something else")
        await settle()

        XCTAssertNil(conversation.error)
        XCTAssertEqual(conversation.status, .submitted)
    }

    // MARK: - What the agent says it is doing

    func test_activity_whileThePersonsMessageWaits_showsTheAgentWorking() {
        let transport = ConversationTransport(messages: [.user("u1")])
        let conversation = AIConversation(transport: transport)
        XCTAssertEqual(conversation.status, .ready)

        transport.update(AIAgentActivity(state: .checkingExternalSources, text: "Searching the web"))

        XCTAssertEqual(conversation.activity?.text, "Searching the web")
        XCTAssertEqual(conversation.status, .submitted)
        XCTAssertTrue(conversation.composerViewModel.isGenerating)

        transport.update(nil)

        XCTAssertNil(conversation.activity)
        XCTAssertEqual(conversation.status, .ready)
    }

    func test_activity_inAnEmptyConversation_showsTheAgentWorking() {
        let transport = ConversationTransport()
        let conversation = AIConversation(transport: transport)

        transport.update(AIAgentActivity(state: .thinking))

        XCTAssertEqual(conversation.status, .submitted)
    }

    func test_activity_afterAFinishedReply_doesNotMeanTheAgentIsAnswering() {
        let transport = ConversationTransport(messages: [.user("u1"), .reply("a1")])
        let conversation = AIConversation(transport: transport)

        transport.update(AIAgentActivity(state: .generating))

        XCTAssertEqual(conversation.activity?.state, .generating)
        XCTAssertEqual(conversation.status, .ready, "an indicator that wasn't cleared yet")
    }

    func test_activity_error_endsTheRequestWithTheAgentsError() async {
        let transport = ConversationTransport(messages: [.user("u1", "Lisbon?"), .reply("a1")])
        let conversation = AIConversation(transport: transport)
        conversation.send("Porto?")
        transport.update([.user("u1", "Lisbon?"), .reply("a1"), .user("u2", "Porto?")])

        transport.update(AIAgentActivity(state: .error, text: "Rate limited"))

        XCTAssertEqual(conversation.pendingMessage?.text, "Porto?", "its copy takes its place")
        XCTAssertEqual(conversation.status, .error)
        XCTAssertEqual(conversation.error as? AIAgentError, AIAgentError(message: "Rate limited"))
        XCTAssertEqual(conversation.error?.localizedDescription, "Rate limited")

        transport.update(nil)

        XCTAssertEqual(conversation.status, .error, "it stays until the next request")

        conversation.retry()
        await settle()

        XCTAssertEqual(transport.lastRequest?.kind, .regenerate)
        XCTAssertEqual(transport.lastRequest?.text, "Porto?")
        XCTAssertNil(transport.lastRequest?.message, "the message has no reply to replace")
        XCTAssertEqual(conversation.status, .submitted)
        XCTAssertNil(conversation.error)
    }

    func test_activity_error_whileAReplyIsWritten_finishesIt() async {
        let transport = ConversationTransport(messages: [.user("u1"), .reply("a1", "Day one", generating: true)])
        let conversation = AIConversation(transport: transport)

        transport.update(AIAgentActivity(state: .error))

        XCTAssertEqual(conversation.status, .error)
        XCTAssertEqual(conversation.messages.ids, ["u1", "a1"])

        conversation.retry()
        await settle()

        XCTAssertEqual(transport.lastRequest?.kind, .regenerate)
        XCTAssertEqual(transport.lastRequest?.message?.id, "a1")
    }

    func test_activity_error_ignoresTheFailureOfTheRequestItEnded() async {
        let transport = ConversationTransport()
        transport.holdsSends = true
        let conversation = AIConversation(transport: transport)
        conversation.send("Hi")
        await settle()

        transport.update(AIAgentActivity(state: .error, text: "Rate limited"))
        transport.finishSend(0, throwing: TransportError())
        await settle()

        XCTAssertEqual(conversation.error as? AIAgentError, AIAgentError(message: "Rate limited"))
    }

    func test_activity_error_beforeThePersonsMessageArrives_retrySendsItAgain() async {
        let transport = ConversationTransport(messages: [.user("u1", "Lisbon?"), .reply("a1")])
        let conversation = AIConversation(transport: transport)
        conversation.send("Porto?")
        await settle()
        let sent = transport.lastRequest

        transport.update(AIAgentActivity(state: .error, text: "Couldn't read it"))
        transport.update(nil)

        XCTAssertEqual(conversation.pendingMessage?.text, "Porto?")
        XCTAssertEqual(conversation.messages.ids, ["u1", "a1"])

        conversation.retry()
        await settle()

        XCTAssertEqual(transport.lastRequest?.kind, .message, "not a1 written again")
        XCTAssertEqual(transport.lastRequest?.messageID, sent?.messageID)
        XCTAssertEqual(transport.lastRequest?.text, "Porto?")
    }

    func test_activity_error_whenThePersonsMessageArrivesAfterIt_retryAsksForItsReply() async {
        let transport = ConversationTransport(messages: [.user("u1", "Lisbon?"), .reply("a1")])
        let conversation = AIConversation(transport: transport)
        conversation.send("Porto?")
        await settle()

        transport.update(AIAgentActivity(state: .error))
        transport.update([.user("u1", "Lisbon?"), .reply("a1"), .user("u2", "Porto?")])
        conversation.retry()
        await settle()

        XCTAssertEqual(transport.lastRequest?.kind, .regenerate)
        XCTAssertEqual(transport.lastRequest?.text, "Porto?")
        XCTAssertNil(transport.lastRequest?.message)
    }

    func test_activity_error_isForgottenOnceANewReplyStarts() {
        let transport = ConversationTransport(messages: [.user("u1"), .reply("a1")])
        let conversation = AIConversation(transport: transport)
        conversation.send("Porto?")
        transport.update([.user("u1"), .reply("a1"), .user("u2", "Porto?")])
        transport.update(AIAgentActivity(state: .error))
        transport.update(nil)
        XCTAssertEqual(conversation.status, .error)

        transport.update([.user("u1"), .reply("a1"), .user("u2", "Porto?"), .reply("a2", "Porto it is", generating: true)])

        XCTAssertNil(conversation.error, "the agent answered after all")
        XCTAssertEqual(conversation.status, .streaming)

        transport.update([.user("u1"), .reply("a1"), .user("u2", "Porto?"), .reply("a2", "Porto it is")])

        XCTAssertEqual(conversation.status, .ready)
        XCTAssertNil(conversation.pendingMessage)
    }

    func test_activity_error_whileAReplyIsWritten_isForgottenOnceTheAgentWritesOn() {
        let transport = ConversationTransport(messages: [.user("u1"), .reply("a1", "Day one", generating: true)])
        let conversation = AIConversation(transport: transport)
        transport.update(AIAgentActivity(state: .error))
        transport.update(nil)

        transport.update([.user("u1"), .reply("a1", "Day one")])

        XCTAssertEqual(conversation.status, .error, "the same reply, finished")

        transport.update([.user("u1"), .reply("a1"), .user("u2"), .reply("a2", "Day two", generating: true)])

        XCTAssertNil(conversation.error)
        XCTAssertEqual(conversation.status, .streaming)
    }

    func test_send_forgetsWhatTheAgentSaidItWasDoing() {
        let transport = ConversationTransport(messages: [.user("u1"), .reply("a1")])
        let conversation = AIConversation(transport: transport)
        transport.update(AIAgentActivity(state: .checkingExternalSources))

        conversation.send("Hi")

        XCTAssertNil(conversation.activity)
    }

    // MARK: - Errors

    func test_retry_withoutAnError_doesNothing() async {
        let transport = ConversationTransport(messages: [.user("u1"), .reply("a1")])
        let conversation = AIConversation(transport: transport)

        conversation.retry()
        await settle()

        XCTAssertTrue(transport.requests.isEmpty)
    }

    func test_retry_afterAStopFailed_hasNothingToTry() async {
        let transport = ConversationTransport(messages: [.user("u1"), .reply("a1", "Day one", generating: true)])
        transport.stopError = TransportError()
        let conversation = AIConversation(transport: transport)
        conversation.stop()
        await settle()

        conversation.retry()
        await settle()

        XCTAssertTrue(transport.requests.isEmpty)
    }

    func test_retry_afterTheAgentFailedInAnEmptyConversation_doesNothing() async {
        let transport = ConversationTransport()
        let conversation = AIConversation(transport: transport)
        transport.update(AIAgentActivity(state: .error))

        conversation.retry()
        await settle()

        XCTAssertTrue(transport.requests.isEmpty)
    }

    func test_clearError_forgetsTheErrorAndTheRequestThatFailed() async {
        let transport = ConversationTransport()
        transport.sendError = TransportError()
        let conversation = AIConversation(transport: transport)
        conversation.send("Hi")
        await settle()

        conversation.clearError()
        conversation.retry()
        await settle()

        XCTAssertNil(conversation.error)
        XCTAssertEqual(conversation.status, .ready)
        XCTAssertEqual(transport.requests.count, 1)
    }

    // MARK: - Older messages

    func test_loadOlderMessages_asksTheTransportOnlyWhileThereAreAny() async {
        let transport = ConversationTransport(messages: [.user("u1"), .reply("a1")])
        let conversation = AIConversation(transport: transport)

        await conversation.loadOlderMessages()
        XCTAssertEqual(transport.loads, 0)

        transport.feed?.update(hasOlderMessages: true)
        await conversation.loadOlderMessages()
        XCTAssertEqual(transport.loads, 1)
    }

    func test_loadOlderMessages_loadsOnceAtATime() async {
        let transport = ConversationTransport()
        transport.holdsLoads = true
        let conversation = AIConversation(transport: transport)
        transport.feed?.update(hasOlderMessages: true)

        async let first: Void = conversation.loadOlderMessages()
        async let second: Void = conversation.loadOlderMessages()
        await settle()
        transport.finishLoads()
        _ = await (first, second)

        XCTAssertEqual(transport.loads, 1)

        transport.holdsLoads = false
        await conversation.loadOlderMessages()

        XCTAssertEqual(transport.loads, 2)
    }

    func test_loadOlderMessages_whenTheTransportFails_canLoadAgain() async {
        let transport = ConversationTransport()
        transport.loadError = TransportError()
        let conversation = AIConversation(transport: transport)
        transport.feed?.update(hasOlderMessages: true)

        await conversation.loadOlderMessages()
        await conversation.loadOlderMessages()

        XCTAssertEqual(transport.loads, 2)
        XCTAssertNil(conversation.error, "not a request of the person's")
    }

    func test_transportDefaults_loadNothingAndKeepRatingsOnTheDevice() async {
        let conversation = AIConversation(transport: MinimalTransport())

        conversation.receive(hasOlderMessages: true)
        await conversation.loadOlderMessages()
        conversation.rate(.reply("a1"), .negative)
        await settle()

        XCTAssertEqual(conversation.ratings["a1"], .negative)
    }

    // MARK: - Ratings

    func test_rate_keepsTheRatingAndTellsTheTransport() async {
        let transport = ConversationTransport(messages: [.user("u1"), .reply("a1")])
        let conversation = AIConversation(transport: transport)

        conversation.rate(.reply("a1"), .positive)
        XCTAssertEqual(conversation.ratings["a1"], .positive)
        await settle()
        conversation.rate(.reply("a1"), nil)
        await settle()

        XCTAssertNil(conversation.ratings["a1"])
        XCTAssertEqual(transport.ratings.map(\.id), ["a1", "a1"])
        XCTAssertEqual(transport.ratings.map(\.rating), [.positive, nil])
    }

    func test_rate_theSameAgain_doesNothing() async {
        let transport = ConversationTransport(messages: [.user("u1"), .reply("a1")])
        let conversation = AIConversation(transport: transport)

        conversation.rate(.reply("a1"), .positive)
        conversation.rate(.reply("a1"), .positive)
        await settle()

        XCTAssertEqual(transport.ratings.count, 1)
    }

    func test_rate_whenTheTransportFails_putsTheRatingBack() async {
        let transport = ConversationTransport(messages: [.user("u1"), .reply("a1")])
        let conversation = AIConversation(transport: transport)
        conversation.rate(.reply("a1"), .positive)
        await settle()

        transport.failsRating = { _ in true }
        conversation.rate(.reply("a1"), .negative)
        await settle()

        XCTAssertEqual(conversation.ratings["a1"], .positive)
    }

    func test_rate_whenTheTransportFailsAfterTheRatingChangedAgain_keepsTheNewOne() async {
        let transport = ConversationTransport(messages: [.user("u1"), .reply("a1")])
        transport.failsRating = { $0 == .positive }
        let conversation = AIConversation(transport: transport)

        conversation.rate(.reply("a1"), .positive)
        conversation.rate(.reply("a1"), .negative)
        await settle()

        XCTAssertEqual(conversation.ratings["a1"], .negative)
        XCTAssertEqual(transport.ratings.map(\.rating), [.negative], "the rating it replaced before it was sent isn't")
    }

    func test_rate_sendsEachReplysRatingsInOrder() async {
        let transport = ConversationTransport(messages: [.user("u1"), .reply("a1")])
        transport.holdsRatings = true
        let conversation = AIConversation(transport: transport)

        conversation.rate(.reply("a1"), .positive)
        await settle()
        conversation.rate(.reply("a1"), .negative)
        await settle()

        XCTAssertEqual(transport.ratings.map(\.rating), [.positive], "the next one waits")

        transport.finishRating(0)
        await settle()
        transport.finishRating(1)
        await settle()

        XCTAssertEqual(transport.ratings.map(\.rating), [.positive, .negative])
        XCTAssertEqual(conversation.ratings["a1"], .negative)
    }

    func test_rate_whenAnEarlierRatingFails_keepsTheLatest() async {
        let transport = ConversationTransport(messages: [.user("u1"), .reply("a1")])
        transport.holdsRatings = true
        let conversation = AIConversation(transport: transport)

        conversation.rate(.reply("a1"), .positive)
        await settle()
        conversation.rate(.reply("a1"), .negative)
        transport.finishRating(0, throwing: TransportError())
        await settle()

        XCTAssertEqual(conversation.ratings["a1"], .negative)

        transport.finishRating(1, throwing: TransportError())
        await settle()

        XCTAssertNil(conversation.ratings["a1"], "what the transport has")
    }

    func test_ratings_showTheRepliesOwn_untilThePersonRatesThem() async {
        var rated = ChatMessage.reply("a1")
        rated.rating = .positive
        let transport = ConversationTransport(messages: [.user("u1"), rated, .reply("a2")])
        let conversation = AIConversation(transport: transport)

        XCTAssertEqual(conversation.ratings, ["a1": .positive])

        conversation.rate(rated, nil)
        await settle()

        XCTAssertEqual(conversation.ratings, [:])
        XCTAssertEqual(transport.ratings.map(\.rating), [nil])

        transport.update([.user("u1"), rated, .reply("a2")])

        XCTAssertEqual(conversation.ratings, [:], "the person's rating stays over the one the reply still has")
    }

    // MARK: - What the conversation offers

    func test_replyActions_offerRegeneratingTheLatestReplyWhileTheAgentIsntAnswering() async {
        let transport = ConversationTransport(messages: [.user("u1"), .reply("a1"), .user("u2"), .reply("a2")])
        let conversation = AIConversation(transport: transport)

        XCTAssertNil(conversation.replyActions(for: .reply("a1"), isLatestReply: false).onRegenerate)
        let latest = conversation.replyActions(for: .reply("a2"), isLatestReply: true)
        XCTAssertNotNil(latest.onRegenerate)

        latest.onRegenerate?()
        await settle()

        XCTAssertEqual(transport.lastRequest?.kind, .regenerate)
        XCTAssertEqual(transport.lastRequest?.message?.id, "a2")
        XCTAssertNil(conversation.replyActions(for: .reply("a2"), isLatestReply: true).onRegenerate, "the agent is answering")
    }

    func test_replyActions_rateAndShowTheRating() async {
        let transport = ConversationTransport(messages: [.user("u1"), .reply("a1")])
        let conversation = AIConversation(transport: transport)

        conversation.replyActions(for: .reply("a1"), isLatestReply: true).onRate?(.negative)
        await settle()

        XCTAssertEqual(conversation.replyActions(for: .reply("a1"), isLatestReply: true).rating, .negative)
        XCTAssertEqual(transport.ratings.first?.rating, .negative)
    }

    func test_editAction_isOfferedForThePersonsLatestMessageWhileTheAgentIsntAnswering() {
        let transport = ConversationTransport(messages: [.user("u1", "Lisbon"), .reply("a1"), .user("u2", "Porto"), .reply("a2")])
        let conversation = AIConversation(transport: transport)

        XCTAssertNil(conversation.editAction(for: .user("u1")))
        XCTAssertNil(conversation.editAction(for: .reply("a2")))
        let edit = conversation.editAction(for: .user("u2", "Porto"))
        XCTAssertNotNil(edit)

        edit?()

        XCTAssertEqual(conversation.editingMessage?.id, "u2")
        XCTAssertEqual(conversation.composerViewModel.text, "Porto")

        transport.update([.user("u1"), .reply("a1"), .user("u2"), .reply("a2", "Porto it is", generating: true)])

        XCTAssertNil(conversation.editAction(for: .user("u2")), "the agent is answering")
    }

    func test_actions_leaveOutWhatTheAppDoesntOffer() {
        let transport = ConversationTransport(messages: [.user("u1"), .reply("a1")])
        let conversation = AIConversation(transport: transport, actions: [.rate])

        XCTAssertNil(conversation.replyActions(for: .reply("a1"), isLatestReply: true).onRegenerate)
        XCTAssertNotNil(conversation.replyActions(for: .reply("a1"), isLatestReply: true).onRate)
        XCTAssertNil(conversation.editAction(for: .user("u1")))
        XCTAssertFalse(conversation.offersRegenerate(isLatestReply: true))

        let nothing = AIConversation(transport: transport, actions: [])

        XCTAssertNil(nothing.replyActions(for: .reply("a1"), isLatestReply: true).onRate)
        XCTAssertEqual(AIConversation(transport: transport).actions, .all)
    }

    // MARK: - Status

    func test_status_followsTheLatestReply() {
        let transport = ConversationTransport(messages: [.user("u1"), .reply("a1", "", generating: true)])
        let conversation = AIConversation(transport: transport)

        XCTAssertEqual(conversation.status, .submitted)

        transport.update([.user("u1"), .reply("a1", "Day", generating: true)])
        XCTAssertEqual(conversation.status, .streaming)

        transport.update([.user("u1"), .reply("a1", "Day one")])
        XCTAssertEqual(conversation.status, .ready)
    }

    func test_status_isAnsweringWhileSubmittedOrStreaming() {
        XCTAssertTrue(AIConversationStatus.submitted.isAnswering)
        XCTAssertTrue(AIConversationStatus.streaming.isAnswering)
        XCTAssertFalse(AIConversationStatus.ready.isAnswering)
        XCTAssertFalse(AIConversationStatus.error.isAnswering)
        XCTAssertFalse(AIConversationStatus(rawValue: "paused").isAnswering)
        XCTAssertEqual(AIConversationStatus.streaming.description, "streaming")
    }

    func test_status_publishesOnlyWhenItChanges() {
        let transport = ConversationTransport(messages: [.user("u1"), .reply("a1", "Day", generating: true)])
        let conversation = AIConversation(transport: transport)
        var statuses: [AIConversationStatus] = []
        let following = conversation.$status.dropFirst().sink { statuses.append($0) }

        transport.update([.user("u1"), .reply("a1", "Day one", generating: true)])
        transport.update([.user("u1"), .reply("a1", "Day one, day two", generating: true)])
        transport.update([.user("u1"), .reply("a1", "Day one, day two")])

        XCTAssertEqual(statuses, [.ready])
        following.cancel()
    }
}
