//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamChatAI
import XCTest

@MainActor
final class AIChat_Tests: XCTestCase {
    private let photo = URL(fileURLWithPath: "/tmp/alfama.jpg")
    private let plan = URL(fileURLWithPath: "/tmp/itinerary.pdf")

    // MARK: - Following the conversation

    func test_init_connectsToTheTransportAndShowsItsMessages() {
        let transport = ChatTransport(messages: [.user("u1"), .reply("a1")])
        let chat = AIChat(transport: transport)

        XCTAssertNotNil(transport.feed)
        XCTAssertEqual(chat.messages.ids, ["u1", "a1"])
        XCTAssertEqual(chat.status, .ready)
        XCTAssertNil(chat.pendingMessage)
        XCTAssertNil(chat.error)
        XCTAssertFalse(chat.hasOlderMessages)
        XCTAssertFalse(chat.composer.isGenerating)
    }

    func test_init_keepsTheComposerAndApproverItIsGiven() {
        let composer = AIComposerViewModel()
        let approver = AIToolApprover(userID: "u_1", clientID: "ios-1") { _, _ in }
        let chat = AIChat(transport: ChatTransport(), composer: composer, approver: approver)

        XCTAssertTrue(chat.composer === composer)
        XCTAssertEqual(chat.approver?.userID, "u_1")
    }

    func test_feed_updatesTheMessagesAndWhetherOlderOnesCanLoad() {
        let transport = ChatTransport()
        let chat = AIChat(transport: transport)

        transport.update([.user("u1"), .reply("a1")])
        transport.feed?.update(hasOlderMessages: true)

        XCTAssertEqual(chat.messages.ids, ["u1", "a1"])
        XCTAssertTrue(chat.hasOlderMessages)

        transport.feed?.update(hasOlderMessages: false)

        XCTAssertFalse(chat.hasOlderMessages)
    }

    func test_feed_goesNowhereOnceTheChatIsReleased() {
        let transport = ChatTransport()
        var chat: AIChat<ChatMessage>? = AIChat(transport: transport)
        weak var released = chat

        XCTAssertEqual(transport.feed?.isConnected, true)
        chat = nil

        XCTAssertNil(released, "the transport doesn't keep its chat")
        XCTAssertEqual(transport.feed?.isConnected, false)
        transport.update([.user("u1")])
        transport.update(AIAgentActivity(state: .thinking))
        transport.feed?.update(hasOlderMessages: true)
    }

    func test_chat_isReleasedAfterItsRequestsFinish() async {
        let transport = ChatTransport(messages: [.user("u1"), .reply("a1")])
        var chat: AIChat<ChatMessage>? = AIChat(transport: transport)
        weak var released = chat

        chat?.send("Hello")
        chat?.rate(.reply("a1"), .positive)
        chat = nil
        await settle()

        XCTAssertNil(released)
    }

    // MARK: - Sending

    func test_send_showsTheMessageAtOnceAndAsksTheTransport() async {
        let transport = ChatTransport(messages: [.user("u1"), .reply("a1")])
        let chat = AIChat(transport: transport)
        let option = ChatOption(id: "think_harder", title: "Think harder", description: "", icon: "brain", shortTitle: "Think")

        chat.send("And the restaurants?", attachments: [photo, plan], chatOption: option)
        await settle()

        XCTAssertEqual(chat.status, .submitted)
        XCTAssertTrue(chat.composer.isGenerating)
        XCTAssertEqual(chat.pendingMessage?.text, "And the restaurants?")
        XCTAssertEqual(chat.pendingMessage?.attachments.map(\.kind), [.image, .file])
        XCTAssertEqual(chat.pendingMessage?.attachments.map(\.url), [photo, plan])
        let request = transport.lastRequest
        XCTAssertEqual(transport.requests.count, 1)
        XCTAssertEqual(request?.kind, .message)
        XCTAssertEqual(request?.text, "And the restaurants?")
        XCTAssertEqual(request?.attachments, [photo, plan])
        XCTAssertEqual(request?.chatOption, option)
        XCTAssertNil(request?.message)
        XCTAssertEqual(request?.messageID, chat.pendingMessage?.id, "the transport can give the message the id its copy is found by")
        XCTAssertEqual(chat.messages.ids, ["u1", "a1"])
    }

    func test_send_ofWhatTheComposerHolds() async {
        let transport = ChatTransport()
        let chat = AIChat(transport: transport)

        chat.send(MessageData(text: "Hi", attachments: [photo]))
        await settle()

        XCTAssertEqual(transport.lastRequest?.text, "Hi")
        XCTAssertEqual(transport.lastRequest?.attachments, [photo])
    }

    func test_send_ignoresAMessageWithNothingInIt() async {
        let transport = ChatTransport()
        let chat = AIChat(transport: transport)

        chat.send("  \n ")
        await settle()

        XCTAssertTrue(transport.requests.isEmpty)
        XCTAssertEqual(chat.status, .ready)
        XCTAssertNil(chat.pendingMessage)
    }

    func test_send_ofOnlyAttachments() async {
        let transport = ChatTransport()
        let chat = AIChat(transport: transport)

        chat.send("", attachments: [photo])
        await settle()

        XCTAssertEqual(transport.lastRequest?.attachments, [photo])
        XCTAssertEqual(chat.status, .submitted)
    }

    func test_send_waitsUntilTheReplyStarts() {
        let transport = ChatTransport(messages: [.user("u1"), .reply("a1")])
        let chat = AIChat(transport: transport)

        chat.send("And the restaurants?")
        transport.update([.user("u1"), .reply("a1"), .user("u2", "And the restaurants?")])

        XCTAssertNotNil(chat.pendingMessage, "kept until its reply starts, so the conversation can match its copy")
        XCTAssertEqual(chat.status, .submitted)

        transport.update([.user("u1"), .reply("a1"), .user("u2"), .reply("a2", "", generating: true)])

        XCTAssertNotNil(chat.pendingMessage, "a reply that shows nothing hasn't started")
        XCTAssertEqual(chat.status, .submitted)

        transport.update([.user("u1"), .reply("a1"), .user("u2"), .reply("a2", "Try", generating: true)])

        XCTAssertNil(chat.pendingMessage)
        XCTAssertEqual(chat.status, .streaming)
        XCTAssertTrue(chat.composer.isGenerating)

        transport.update([.user("u1"), .reply("a1"), .user("u2"), .reply("a2", "Try Taberna da Rua")])

        XCTAssertEqual(chat.status, .ready)
        XCTAssertFalse(chat.composer.isGenerating)
        XCTAssertEqual(chat.messages.ids, ["u1", "a1", "u2", "a2"])
    }

    func test_send_endsWhenTheReplyArrivesFinished() {
        let transport = ChatTransport()
        let chat = AIChat(transport: transport)

        chat.send("Hi")
        transport.update([.user("u1", "Hi"), .reply("a1", "Hello!")])

        XCTAssertNil(chat.pendingMessage)
        XCTAssertEqual(chat.status, .ready)
    }

    func test_send_endsWhenAReplyFinishesWithNothingInIt() {
        let transport = ChatTransport()
        let chat = AIChat(transport: transport)

        chat.send("Hi")
        transport.update([.user("u1", "Hi"), .reply("a1", "")])

        XCTAssertNil(chat.pendingMessage)
        XCTAssertEqual(chat.status, .ready)
    }

    func test_send_whileAReplyIsWritten_waitsForItsOwnReply() {
        let transport = ChatTransport(messages: [.user("u1"), .reply("a1", "Day one", generating: true)])
        let chat = AIChat(transport: transport)
        XCTAssertEqual(chat.status, .streaming)

        chat.send("Make it three days")
        transport.update([.user("u1"), .reply("a1", "Day one, day two", generating: true)])

        XCTAssertNotNil(chat.pendingMessage)
        XCTAssertEqual(chat.status, .submitted)

        transport.update([.user("u1"), .reply("a1", "Day one, day two"), .user("u2"), .reply("a2", "Three days", generating: true)])

        XCTAssertNil(chat.pendingMessage)
        XCTAssertEqual(chat.status, .streaming)
    }

    func test_send_whenTheTransportFails_showsTheErrorAndRetrySendsItAgain() async {
        let transport = ChatTransport(messages: [.user("u1"), .reply("a1")])
        transport.sendError = TransportError()
        let chat = AIChat(transport: transport)

        chat.send("And the restaurants?", attachments: [photo])
        await settle()

        XCTAssertEqual(chat.status, .error)
        XCTAssertTrue(chat.error is TransportError)
        XCTAssertNil(chat.pendingMessage)
        XCTAssertFalse(chat.composer.isGenerating)
        let failed = transport.lastRequest

        transport.sendError = nil
        chat.retry()
        await settle()

        XCTAssertEqual(transport.requests.count, 2)
        XCTAssertEqual(transport.lastRequest?.kind, .message)
        XCTAssertEqual(transport.lastRequest?.text, "And the restaurants?")
        XCTAssertEqual(transport.lastRequest?.attachments, [photo])
        XCTAssertNotEqual(transport.lastRequest?.messageID, failed?.messageID, "the message may have arrived the first time")
        XCTAssertNil(chat.error)
        XCTAssertEqual(chat.status, .submitted)
        XCTAssertEqual(chat.pendingMessage?.text, "And the restaurants?")
    }

    func test_send_whenCancelled_showsNoError() async {
        let transport = ChatTransport()
        transport.sendError = CancellationError()
        let chat = AIChat(transport: transport)

        chat.send("Hi")
        await settle()

        XCTAssertNil(chat.error)
        XCTAssertEqual(chat.status, .ready)
        XCTAssertNil(chat.pendingMessage)
    }

    func test_send_failureOfARequestThatWasOvertaken_isIgnored() async {
        let transport = ChatTransport()
        transport.holdsSends = true
        let chat = AIChat(transport: transport)

        chat.send("First")
        chat.send("Second")
        await settle()
        transport.finishSend(0, throwing: TransportError())
        await settle()

        XCTAssertNil(chat.error)
        XCTAssertEqual(chat.status, .submitted)
        XCTAssertEqual(chat.pendingMessage?.text, "Second")

        transport.finishSend(1)
        await settle()

        XCTAssertEqual(chat.status, .submitted, "a request that reaches the agent waits for its reply")
    }

    func test_send_whenTheReplyStartedBeforeTheTransportReturned() async {
        let transport = ChatTransport()
        transport.holdsSends = true
        let chat = AIChat(transport: transport)

        chat.send("Hi")
        await settle()
        transport.update([.user("u1", "Hi"), .reply("a1", "Hello", generating: true)])
        transport.finishSend(0)
        await settle()

        XCTAssertEqual(chat.status, .streaming)
        XCTAssertNil(chat.pendingMessage)
    }

    func test_send_forgetsThePreviousError() async {
        let transport = ChatTransport()
        transport.sendError = TransportError()
        let chat = AIChat(transport: transport)
        chat.send("Hi")
        await settle()
        XCTAssertNotNil(chat.error)

        transport.sendError = nil
        chat.send("Hi again")

        XCTAssertNil(chat.error)
        XCTAssertEqual(chat.status, .submitted)
    }

    // MARK: - Regenerating

    func test_regenerate_asksForANewReplyInPlaceOfTheOld() async {
        let transport = ChatTransport(messages: [.user("u1", "Lisbon?"), .reply("a1"), .user("u2", "Porto?"), .reply("a2")])
        let chat = AIChat(transport: transport)

        chat.regenerate(.reply("a2"))
        await settle()

        XCTAssertEqual(transport.lastRequest?.kind, .regenerate)
        XCTAssertEqual(transport.lastRequest?.text, "Porto?", "a transport that can only send messages asks again")
        XCTAssertEqual(transport.lastRequest?.message?.id, "a2")
        XCTAssertEqual(chat.messages.ids, ["u1", "a1", "u2"])
        XCTAssertNil(chat.pendingMessage)
        XCTAssertEqual(chat.status, .submitted)
    }

    func test_regenerate_sendsTheReplyAsTheConversationHasIt() async {
        let transport = ChatTransport(messages: [.user("u1"), .reply("a1", "The latest text")])
        let chat = AIChat(transport: transport)

        chat.regenerate(.reply("a1", "What a view once showed"))
        await settle()

        XCTAssertEqual(transport.lastRequest?.message?.text, "The latest text")
    }

    func test_regenerate_ofAnEarlierReply_leavesOutThoseAfterIt() {
        let transport = ChatTransport(messages: [.user("u1"), .reply("a1"), .user("u2"), .reply("a2")])
        let chat = AIChat(transport: transport)

        chat.regenerate(.reply("a1"))

        XCTAssertEqual(chat.messages.ids, ["u1"])
    }

    func test_regenerate_showsTheNewReplyOnceItStarts() {
        let transport = ChatTransport(messages: [.user("u1"), .reply("a1")])
        let chat = AIChat(transport: transport)

        chat.regenerate(.reply("a1"))
        transport.update([.user("u1")])

        XCTAssertEqual(chat.status, .submitted)

        transport.update([.user("u1"), .reply("a2", "Another plan", generating: true)])

        XCTAssertEqual(chat.messages.ids, ["u1", "a2"])
        XCTAssertEqual(chat.status, .streaming)
    }

    func test_regenerate_whenTheReplyIsRewrittenInPlace() {
        let transport = ChatTransport(messages: [.user("u1"), .reply("a1")])
        let chat = AIChat(transport: transport)

        chat.regenerate(.reply("a1"))
        transport.update([.user("u1"), .reply("a1", "", generating: true)])

        XCTAssertEqual(chat.messages.ids, ["u1"])
        XCTAssertEqual(chat.status, .submitted)

        transport.update([.user("u1"), .reply("a1", "Another", generating: true)])

        XCTAssertEqual(chat.messages.ids, ["u1", "a1"])
        XCTAssertEqual(chat.messages.last?.text, "Another")
        XCTAssertEqual(chat.status, .streaming)
    }

    func test_regenerate_whenTheTransportFails_bringsTheReplyBack() async {
        let transport = ChatTransport(messages: [.user("u1"), .reply("a1")])
        transport.sendError = TransportError()
        let chat = AIChat(transport: transport)

        chat.regenerate(.reply("a1"))
        await settle()

        XCTAssertEqual(chat.messages.ids, ["u1", "a1"])
        XCTAssertEqual(chat.status, .error)

        transport.sendError = nil
        chat.retry()
        await settle()

        XCTAssertEqual(transport.lastRequest?.kind, .regenerate)
        XCTAssertEqual(transport.lastRequest?.message?.id, "a1")
    }

    func test_regenerate_ignoresThePersonsMessagesAndOnesNotInTheConversation() async {
        let transport = ChatTransport(messages: [.user("u1"), .reply("a1")])
        let chat = AIChat(transport: transport)

        chat.regenerate(.user("u1"))
        chat.regenerate(.reply("gone"))
        await settle()

        XCTAssertTrue(transport.requests.isEmpty)
        XCTAssertEqual(chat.status, .ready)
    }

    func test_regenerate_ofAReplyWithNoMessageBeforeIt() async {
        let transport = ChatTransport(messages: [.reply("a0", "Hi! How can I help?")])
        let chat = AIChat(transport: transport)

        chat.regenerate(.reply("a0"))
        await settle()

        XCTAssertEqual(transport.lastRequest?.text, "")
        XCTAssertEqual(transport.lastRequest?.message?.id, "a0")
    }

    // MARK: - Editing

    func test_edit_putsTheMessageInTheComposer() {
        let chat = AIChat(transport: ChatTransport(messages: [.user("u1", "Plan Lisbon"), .reply("a1")]))

        chat.edit(.user("u1", "Plan Lisbon"))

        XCTAssertEqual(chat.editingMessage?.id, "u1")
        XCTAssertEqual(chat.composer.text, "Plan Lisbon")
        XCTAssertTrue(chat.composer.isTextFieldFocused)
    }

    func test_edit_ignoresReplies() {
        let chat = AIChat(transport: ChatTransport(messages: [.user("u1"), .reply("a1")]))

        chat.edit(.reply("a1"))

        XCTAssertNil(chat.editingMessage)
        XCTAssertEqual(chat.composer.text, "")
    }

    func test_send_whileEditing_replacesTheMessageAndWhatFollows() async {
        let original = ChatMessage(id: "u2", role: .user, text: "Plan Porto", attachments: [.image(URL(string: "https://example.com/porto.jpg")!)])
        let transport = ChatTransport(messages: [.user("u1"), .reply("a1"), original, .reply("a2")])
        let chat = AIChat(transport: transport)

        chat.edit(original)
        chat.send("Plan Porto for two", attachments: [photo])
        await settle()

        XCTAssertNil(chat.editingMessage)
        XCTAssertEqual(transport.lastRequest?.kind, .edit)
        XCTAssertEqual(transport.lastRequest?.message?.id, "u2")
        XCTAssertEqual(transport.lastRequest?.text, "Plan Porto for two")
        XCTAssertEqual(chat.messages.ids, ["u1", "a1"])
        XCTAssertEqual(chat.pendingMessage?.text, "Plan Porto for two")
        XCTAssertEqual(
            chat.pendingMessage?.attachments.map(\.url),
            [URL(string: "https://example.com/porto.jpg")!, photo],
            "the edit keeps what the message carried"
        )
        XCTAssertEqual(chat.status, .submitted)

        transport.update([.user("u1"), .reply("a1"), .user("u2", "Plan Porto for two"), .reply("a3", "For two", generating: true)])

        XCTAssertEqual(chat.messages.ids, ["u1", "a1", "u2", "a3"])
        XCTAssertNil(chat.pendingMessage)
        XCTAssertEqual(chat.status, .streaming)
    }

    func test_cancelEditing_emptiesTheComposer() async {
        let transport = ChatTransport(messages: [.user("u1"), .reply("a1")])
        let chat = AIChat(transport: transport)
        chat.edit(.user("u1"))

        chat.cancelEditing()
        chat.send("Something else")
        await settle()

        XCTAssertNil(chat.editingMessage)
        XCTAssertEqual(chat.composer.text, "")
        XCTAssertEqual(transport.lastRequest?.kind, .message)
    }

    func test_cancelEditing_whenNotEditing_keepsTheComposer() {
        let chat = AIChat(transport: ChatTransport())
        chat.composer.text = "Half a thought"

        chat.cancelEditing()

        XCTAssertEqual(chat.composer.text, "Half a thought")
    }

    // MARK: - Stopping

    func test_stop_endsTheReplyAndTellsTheTransport() async {
        let transport = ChatTransport(messages: [.user("u1"), .reply("a1", "Day one", generating: true)])
        let chat = AIChat(transport: transport)
        XCTAssertEqual(chat.status, .streaming)

        chat.stop()
        await settle()

        XCTAssertEqual(transport.stops, 1)
        XCTAssertEqual(chat.status, .ready)
        XCTAssertFalse(chat.composer.isGenerating)

        transport.update([.user("u1"), .reply("a1", "Day one", generating: true)])

        XCTAssertEqual(chat.status, .ready, "a stopped reply is finished, however long the conversation says otherwise")
        XCTAssertEqual(chat.messages.ids, ["u1", "a1"], "what it wrote so far stays")
    }

    func test_stop_whileWaiting_dropsTheMessageOnItsWay() async {
        let transport = ChatTransport()
        let chat = AIChat(transport: transport)
        chat.send("Hi")

        chat.stop()
        await settle()

        XCTAssertNil(chat.pendingMessage)
        XCTAssertEqual(chat.status, .ready)
        XCTAssertEqual(transport.stops, 1)
    }

    func test_stop_leavesOutAReplyThatShowsNothing() {
        let transport = ChatTransport(messages: [.user("u1"), .reply("a1", "", generating: true)])
        let chat = AIChat(transport: transport)
        XCTAssertEqual(chat.status, .submitted)

        chat.stop()

        XCTAssertEqual(chat.messages.ids, ["u1"], "the conversation would think it is still on its way")
        XCTAssertEqual(chat.status, .ready)
    }

    func test_stop_whenNotAnswering_doesNothing() async {
        let transport = ChatTransport(messages: [.user("u1"), .reply("a1")])
        let chat = AIChat(transport: transport)

        chat.stop()
        await settle()

        XCTAssertEqual(transport.stops, 0)
    }

    func test_stop_ignoresWhatTheAgentSaysUntilItStopsSaying() {
        let transport = ChatTransport(messages: [.user("u1")])
        let chat = AIChat(transport: transport)
        transport.update(AIAgentActivity(state: .thinking))
        XCTAssertEqual(chat.status, .submitted)

        chat.stop()
        transport.update(AIAgentActivity(state: .generating))

        XCTAssertNil(chat.activity)
        XCTAssertEqual(chat.status, .ready)

        transport.update(nil)
        transport.update(AIAgentActivity(state: .thinking))

        XCTAssertEqual(chat.activity, AIAgentActivity(state: .thinking))
        XCTAssertEqual(chat.status, .submitted)
    }

    func test_stop_whenTheTransportFails_showsTheReplyStillBeingWritten() async {
        let transport = ChatTransport(messages: [.user("u1"), .reply("a1", "Day one", generating: true)])
        transport.stopError = TransportError()
        let chat = AIChat(transport: transport)

        chat.stop()
        await settle()

        XCTAssertTrue(chat.error is TransportError)
        XCTAssertEqual(chat.status, .streaming)

        transport.update([.user("u1"), .reply("a1", "Day one, day two")])

        XCTAssertEqual(chat.status, .error)
    }

    func test_stop_failureAfterANewRequest_isIgnored() async {
        let transport = ChatTransport(messages: [.user("u1"), .reply("a1", "Day one", generating: true)])
        transport.stopError = TransportError()
        let chat = AIChat(transport: transport)

        chat.stop()
        chat.send("Something else")
        await settle()

        XCTAssertNil(chat.error)
        XCTAssertEqual(chat.status, .submitted)
    }

    // MARK: - What the agent says it is doing

    func test_activity_whileThePersonsMessageWaits_showsTheAgentWorking() {
        let transport = ChatTransport(messages: [.user("u1")])
        let chat = AIChat(transport: transport)
        XCTAssertEqual(chat.status, .ready)

        transport.update(AIAgentActivity(state: .checkingExternalSources, text: "Searching the web"))

        XCTAssertEqual(chat.activity?.text, "Searching the web")
        XCTAssertEqual(chat.status, .submitted)
        XCTAssertTrue(chat.composer.isGenerating)

        transport.update(nil)

        XCTAssertNil(chat.activity)
        XCTAssertEqual(chat.status, .ready)
    }

    func test_activity_inAnEmptyConversation_showsTheAgentWorking() {
        let transport = ChatTransport()
        let chat = AIChat(transport: transport)

        transport.update(AIAgentActivity(state: .thinking))

        XCTAssertEqual(chat.status, .submitted)
    }

    func test_activity_afterAFinishedReply_doesNotMeanTheAgentIsAnswering() {
        let transport = ChatTransport(messages: [.user("u1"), .reply("a1")])
        let chat = AIChat(transport: transport)

        transport.update(AIAgentActivity(state: .generating))

        XCTAssertEqual(chat.activity?.state, .generating)
        XCTAssertEqual(chat.status, .ready, "an indicator that wasn't cleared yet")
    }

    func test_activity_error_endsTheRequestWithTheAgentsError() async {
        let transport = ChatTransport(messages: [.user("u1", "Lisbon?"), .reply("a1")])
        let chat = AIChat(transport: transport)
        chat.send("Porto?")
        transport.update([.user("u1", "Lisbon?"), .reply("a1"), .user("u2", "Porto?")])

        transport.update(AIAgentActivity(state: .error, text: "Rate limited"))

        XCTAssertNil(chat.pendingMessage)
        XCTAssertEqual(chat.status, .error)
        XCTAssertEqual(chat.error as? AIAgentError, AIAgentError(message: "Rate limited"))
        XCTAssertEqual(chat.error?.localizedDescription, "Rate limited")

        transport.update(nil)

        XCTAssertEqual(chat.status, .error, "it stays until the next request")

        chat.retry()
        await settle()

        XCTAssertEqual(transport.lastRequest?.kind, .regenerate)
        XCTAssertEqual(transport.lastRequest?.text, "Porto?")
        XCTAssertNil(transport.lastRequest?.message, "the message has no reply to replace")
        XCTAssertEqual(chat.status, .submitted)
        XCTAssertNil(chat.error)
    }

    func test_activity_error_whileAReplyIsWritten_finishesIt() async {
        let transport = ChatTransport(messages: [.user("u1"), .reply("a1", "Day one", generating: true)])
        let chat = AIChat(transport: transport)

        transport.update(AIAgentActivity(state: .error))

        XCTAssertEqual(chat.status, .error)
        XCTAssertEqual(chat.messages.ids, ["u1", "a1"])

        chat.retry()
        await settle()

        XCTAssertEqual(transport.lastRequest?.kind, .regenerate)
        XCTAssertEqual(transport.lastRequest?.message?.id, "a1")
    }

    func test_activity_error_ignoresTheFailureOfTheRequestItEnded() async {
        let transport = ChatTransport()
        transport.holdsSends = true
        let chat = AIChat(transport: transport)
        chat.send("Hi")
        await settle()

        transport.update(AIAgentActivity(state: .error, text: "Rate limited"))
        transport.finishSend(0, throwing: TransportError())
        await settle()

        XCTAssertEqual(chat.error as? AIAgentError, AIAgentError(message: "Rate limited"))
    }

    func test_send_forgetsWhatTheAgentSaidItWasDoing() {
        let transport = ChatTransport(messages: [.user("u1"), .reply("a1")])
        let chat = AIChat(transport: transport)
        transport.update(AIAgentActivity(state: .checkingExternalSources))

        chat.send("Hi")

        XCTAssertNil(chat.activity)
    }

    // MARK: - Errors

    func test_retry_withoutAnError_doesNothing() async {
        let transport = ChatTransport(messages: [.user("u1"), .reply("a1")])
        let chat = AIChat(transport: transport)

        chat.retry()
        await settle()

        XCTAssertTrue(transport.requests.isEmpty)
    }

    func test_retry_afterAStopFailed_doesNothing() async {
        let transport = ChatTransport(messages: [.user("u1"), .reply("a1", "Day one", generating: true)])
        transport.stopError = TransportError()
        let chat = AIChat(transport: transport)
        chat.stop()
        await settle()

        chat.retry()
        await settle()

        XCTAssertTrue(transport.requests.isEmpty)
    }

    func test_retry_afterTheAgentFailedInAnEmptyConversation_doesNothing() async {
        let transport = ChatTransport()
        let chat = AIChat(transport: transport)
        transport.update(AIAgentActivity(state: .error))

        chat.retry()
        await settle()

        XCTAssertTrue(transport.requests.isEmpty)
    }

    func test_clearError_forgetsTheErrorAndTheRequestThatFailed() async {
        let transport = ChatTransport()
        transport.sendError = TransportError()
        let chat = AIChat(transport: transport)
        chat.send("Hi")
        await settle()

        chat.clearError()
        chat.retry()
        await settle()

        XCTAssertNil(chat.error)
        XCTAssertEqual(chat.status, .ready)
        XCTAssertEqual(transport.requests.count, 1)
    }

    // MARK: - Older messages

    func test_loadOlderMessages_asksTheTransportOnlyWhileThereAreAny() async {
        let transport = ChatTransport(messages: [.user("u1"), .reply("a1")])
        let chat = AIChat(transport: transport)

        await chat.loadOlderMessages()
        XCTAssertEqual(transport.loads, 0)

        transport.feed?.update(hasOlderMessages: true)
        await chat.loadOlderMessages()
        XCTAssertEqual(transport.loads, 1)
    }

    func test_loadOlderMessages_loadsOnceAtATime() async {
        let transport = ChatTransport()
        transport.holdsLoads = true
        let chat = AIChat(transport: transport)
        transport.feed?.update(hasOlderMessages: true)

        async let first: Void = chat.loadOlderMessages()
        async let second: Void = chat.loadOlderMessages()
        await settle()
        transport.finishLoads()
        _ = await (first, second)

        XCTAssertEqual(transport.loads, 1)

        transport.holdsLoads = false
        await chat.loadOlderMessages()

        XCTAssertEqual(transport.loads, 2)
    }

    func test_loadOlderMessages_whenTheTransportFails_canLoadAgain() async {
        let transport = ChatTransport()
        transport.loadError = TransportError()
        let chat = AIChat(transport: transport)
        transport.feed?.update(hasOlderMessages: true)

        await chat.loadOlderMessages()
        await chat.loadOlderMessages()

        XCTAssertEqual(transport.loads, 2)
        XCTAssertNil(chat.error, "not a request of the person's")
    }

    func test_transportDefaults_loadNothingAndKeepRatingsOnTheDevice() async {
        let chat = AIChat(transport: MinimalTransport())

        chat.receive(hasOlderMessages: true)
        await chat.loadOlderMessages()
        chat.rate(.reply("a1"), .negative)
        await settle()

        XCTAssertEqual(chat.ratings["a1"], .negative)
    }

    // MARK: - Ratings

    func test_rate_keepsTheRatingAndTellsTheTransport() async {
        let transport = ChatTransport(messages: [.user("u1"), .reply("a1")])
        let chat = AIChat(transport: transport)

        chat.rate(.reply("a1"), .positive)
        XCTAssertEqual(chat.ratings["a1"], .positive)
        await settle()
        chat.rate(.reply("a1"), nil)
        await settle()

        XCTAssertNil(chat.ratings["a1"])
        XCTAssertEqual(transport.ratings.map(\.id), ["a1", "a1"])
        XCTAssertEqual(transport.ratings.map(\.rating), [.positive, nil])
    }

    func test_rate_theSameAgain_doesNothing() async {
        let transport = ChatTransport(messages: [.user("u1"), .reply("a1")])
        let chat = AIChat(transport: transport)

        chat.rate(.reply("a1"), .positive)
        chat.rate(.reply("a1"), .positive)
        await settle()

        XCTAssertEqual(transport.ratings.count, 1)
    }

    func test_rate_whenTheTransportFails_putsTheRatingBack() async {
        let transport = ChatTransport(messages: [.user("u1"), .reply("a1")])
        let chat = AIChat(transport: transport)
        chat.rate(.reply("a1"), .positive)
        await settle()

        transport.failsRating = { _ in true }
        chat.rate(.reply("a1"), .negative)
        await settle()

        XCTAssertEqual(chat.ratings["a1"], .positive)
    }

    func test_rate_whenTheTransportFailsAfterTheRatingChangedAgain_keepsTheNewOne() async {
        let transport = ChatTransport(messages: [.user("u1"), .reply("a1")])
        transport.failsRating = { $0 == .positive }
        let chat = AIChat(transport: transport)

        chat.rate(.reply("a1"), .positive)
        chat.rate(.reply("a1"), .negative)
        await settle()

        XCTAssertEqual(chat.ratings["a1"], .negative)
        XCTAssertEqual(transport.ratings.count, 2)
    }

    // MARK: - What the conversation offers

    func test_replyActions_offerRegeneratingTheLatestReplyWhileTheAgentIsntAnswering() async {
        let transport = ChatTransport(messages: [.user("u1"), .reply("a1"), .user("u2"), .reply("a2")])
        let chat = AIChat(transport: transport)

        XCTAssertNil(chat.replyActions(for: .reply("a1"), isLatestReply: false).onRegenerate)
        let latest = chat.replyActions(for: .reply("a2"), isLatestReply: true)
        XCTAssertNotNil(latest.onRegenerate)

        latest.onRegenerate?()
        await settle()

        XCTAssertEqual(transport.lastRequest?.kind, .regenerate)
        XCTAssertEqual(transport.lastRequest?.message?.id, "a2")
        XCTAssertNil(chat.replyActions(for: .reply("a2"), isLatestReply: true).onRegenerate, "the agent is answering")
    }

    func test_replyActions_rateAndShowTheRating() async {
        let transport = ChatTransport(messages: [.user("u1"), .reply("a1")])
        let chat = AIChat(transport: transport)

        chat.replyActions(for: .reply("a1"), isLatestReply: true).onRate?(.negative)
        await settle()

        XCTAssertEqual(chat.replyActions(for: .reply("a1"), isLatestReply: true).rating, .negative)
        XCTAssertEqual(transport.ratings.first?.rating, .negative)
    }

    func test_editAction_isOfferedForThePersonsLatestMessageWhileTheAgentIsntAnswering() {
        let transport = ChatTransport(messages: [.user("u1", "Lisbon"), .reply("a1"), .user("u2", "Porto"), .reply("a2")])
        let chat = AIChat(transport: transport)

        XCTAssertNil(chat.editAction(for: .user("u1")))
        XCTAssertNil(chat.editAction(for: .reply("a2")))
        let edit = chat.editAction(for: .user("u2", "Porto"))
        XCTAssertNotNil(edit)

        edit?()

        XCTAssertEqual(chat.editingMessage?.id, "u2")
        XCTAssertEqual(chat.composer.text, "Porto")

        transport.update([.user("u1"), .reply("a1"), .user("u2"), .reply("a2", "Porto it is", generating: true)])

        XCTAssertNil(chat.editAction(for: .user("u2")), "the agent is answering")
    }

    // MARK: - Status

    func test_status_followsTheLatestReply() {
        let transport = ChatTransport(messages: [.user("u1"), .reply("a1", "", generating: true)])
        let chat = AIChat(transport: transport)

        XCTAssertEqual(chat.status, .submitted)

        transport.update([.user("u1"), .reply("a1", "Day", generating: true)])
        XCTAssertEqual(chat.status, .streaming)

        transport.update([.user("u1"), .reply("a1", "Day one")])
        XCTAssertEqual(chat.status, .ready)
    }

    func test_status_isAnsweringWhileSubmittedOrStreaming() {
        XCTAssertTrue(AIChatStatus.submitted.isAnswering)
        XCTAssertTrue(AIChatStatus.streaming.isAnswering)
        XCTAssertFalse(AIChatStatus.ready.isAnswering)
        XCTAssertFalse(AIChatStatus.error.isAnswering)
        XCTAssertFalse(AIChatStatus(rawValue: "paused").isAnswering)
        XCTAssertEqual(AIChatStatus.streaming.description, "streaming")
    }

    func test_status_publishesOnlyWhenItChanges() {
        let transport = ChatTransport(messages: [.user("u1"), .reply("a1", "Day", generating: true)])
        let chat = AIChat(transport: transport)
        var statuses: [AIChatStatus] = []
        let following = chat.$status.dropFirst().sink { statuses.append($0) }

        transport.update([.user("u1"), .reply("a1", "Day one", generating: true)])
        transport.update([.user("u1"), .reply("a1", "Day one, day two", generating: true)])
        transport.update([.user("u1"), .reply("a1", "Day one, day two")])

        XCTAssertEqual(statuses, [.ready])
        following.cancel()
    }
}
