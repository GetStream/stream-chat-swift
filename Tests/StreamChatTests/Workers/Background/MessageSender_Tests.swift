//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class MessageSender_Tests: XCTestCase {
    var messageRepository: MessageRepository_Mock!
    var webSocketClient: WebSocketClient_Mock!
    var apiClient: APIClient_Spy!
    var database: DatabaseContainer_Spy!
    var eventsNotificationCenter: EventNotificationCenter_Mock!

    var sender: MessageSender!

    var cid: ChannelId!

    override func setUp() {
        super.setUp()

        webSocketClient = WebSocketClient_Mock()
        apiClient = APIClient_Spy()
        database = DatabaseContainer_Spy()
        messageRepository = MessageRepository_Mock(database: database, apiClient: apiClient)
        eventsNotificationCenter = EventNotificationCenter_Mock(database: database)
        sender = MessageSender(
            messageRepository: messageRepository,
            eventsNotificationCenter: eventsNotificationCenter,
            database: database,
            apiClient: apiClient
        )

        cid = .unique

        try! database.createCurrentUser()
        try! database.createChannel(cid: cid)
    }

    override func tearDown() {
        apiClient.cleanUp()
        messageRepository.clear()

        AssertAsync {
            Assert.canBeReleased(&sender)
            Assert.canBeReleased(&webSocketClient)
            Assert.canBeReleased(&messageRepository)
            Assert.canBeReleased(&apiClient)
            Assert.canBeReleased(&eventsNotificationCenter)
            Assert.canBeReleased(&database)
        }

        sender = nil
        webSocketClient = nil
        messageRepository = nil
        apiClient = nil
        eventsNotificationCenter = nil
        database = nil

        super.tearDown()
    }

    func test_senderSendsMessage_withPendingSendLocalState_and_uploadedOrEmptyAttachments() throws {
        let message1Id: MessageId = .unique
        var message2Id: MessageId!

        let message = ChatMessage.mock(id: message1Id, cid: cid, text: "Message sent", author: .unique)
        messageRepository.sendMessageResult = .success(message)

        // Create 3 messages in the DB:
        //  - message in .pendingSend without attachments
        //  - message in .pendingSend with attachments
        //  - message without local state
        try database.writeSynchronously { session in
            let message1 = try session.createNewMessage(
                in: self.cid,
                messageId: .unique,
                text: "Message pending send without attachments",
                pinning: nil,
                quotedMessageId: nil,
                isSilent: false,
                skipPush: false,
                skipEnrichUrl: false,
                extraData: [:]
            )
            message1.localMessageState = .pendingSend
            message1.id = message1Id

            let message2 = try session.createNewMessage(
                in: self.cid,
                messageId: .unique,
                text: "Message pending send with attachments",
                pinning: nil,
                quotedMessageId: nil,
                isSilent: false,
                skipPush: false,
                skipEnrichUrl: false,
                attachments: [
                    .mockFile,
                    .mockImage,
                    .mockFile
                ],
                extraData: [:]
            )
            message2.localMessageState = .pendingSend
            message2Id = message2.id

            // Create 3rd message
            try session.createNewMessage(
                in: self.cid,
                messageId: .unique,
                text: "Message without local state",
                pinning: nil,
                quotedMessageId: nil,
                isSilent: false,
                skipPush: false,
                skipEnrichUrl: false,
                attachments: [],
                extraData: [:]
            )
        }

        // Check only the message1 was sent
        AssertAsync {
            Assert.willBeTrue(self.messageRepository.sendMessageIds.contains(where: { $0 == message1Id }))
            Assert.willBeTrue(self.messageRepository.sendMessageIds.count == 1)
        }

        XCTAssertCall("sendMessage(with:completion:)", on: messageRepository, times: 1)

        let message2 = ChatMessage.mock(id: message2Id, cid: cid, text: "Message sent 2", author: .unique)
        messageRepository.sendMessageResult = .success(message2)

        // Simulate all message2 attachments are uploaded.
        try database.writeSynchronously { session in
            let message2 = try XCTUnwrap(session.message(id: message2Id))
            message2.attachments.forEach { $0.localState = .uploaded }
        }

        // Check message2 was sent.
        AssertAsync {
            Assert.willBeTrue(self.messageRepository.sendMessageIds.contains(where: { $0 == message2Id }))
            Assert.willBeTrue(self.messageRepository.sendMessageIds.count == 2)
        }
        XCTAssertCall("sendMessage(with:completion:)", on: messageRepository, times: 2)
    }

    func test_sender_sendsMessage_withUploadedAttachments() throws {
        var messageId: MessageId!

        try database.writeSynchronously { session in
            let message = try session.createNewMessage(
                in: self.cid,
                messageId: .unique,
                text: "Message pending send",
                pinning: nil,
                quotedMessageId: nil,
                isSilent: false,
                skipPush: false,
                skipEnrichUrl: false,
                attachments: [
                    .init(payload: TestAttachmentPayload.unique),
                    .init(payload: TestAttachmentPayload.unique)
                ],
                extraData: [:]
            )
            message.localMessageState = .pendingSend
            messageId = message.id
        }

        AssertAsync.willBeTrue(messageRepository.sendMessageIds.contains(where: { $0 == messageId }))
        XCTAssertCall("sendMessage(with:completion:)", on: messageRepository, times: 1)
    }

    func test_sender_sendsMessage_withBothNotUploadableAttachmentAndUploadedAttachments() throws {
        var messageId: MessageId!

        try database.writeSynchronously { session in
            let message = try session.createNewMessage(
                in: self.cid,
                messageId: .unique,
                text: "Message pending send",
                pinning: nil,
                quotedMessageId: nil,
                isSilent: false,
                skipPush: false,
                skipEnrichUrl: false,
                attachments: [
                    .mockImage,
                    .init(payload: TestAttachmentPayload.unique)
                ],
                extraData: [:]
            )
            message.localMessageState = .pendingSend
            messageId = message.id
        }

        AssertAsync.staysTrue(messageRepository.sendMessageIds.isEmpty)

        // Simulate attachment seed uploaded
        try database.writeSynchronously { session in
            let message = try XCTUnwrap(session.message(id: messageId))
            message.attachments.forEach {
                guard $0.localURL != nil else { return }
                $0.localState = .uploaded
            }
        }

        AssertAsync.willBeTrue(messageRepository.sendMessageIds.contains(where: { $0 == messageId }))
    }

    func test_senderSendsMessage_inTheOrderTheyWereCreatedLocally() throws {
        var message1Id: MessageId!
        var message2Id: MessageId!
        var message3Id: MessageId!

        // Create 3 messages in the DB, all with `.pendingSend` local state
        try database.writeSynchronously { session in
            let message1 = try session.createNewMessage(
                in: self.cid,
                messageId: .unique,
                text: "Message pending send 1",
                pinning: nil,
                quotedMessageId: nil,
                isSilent: false,
                skipPush: false,
                skipEnrichUrl: false,
                extraData: [:]
            )
            message1.localMessageState = .pendingSend
            message1Id = message1.id

            let message2 = try session.createNewMessage(
                in: self.cid,
                messageId: .unique,
                text: "Message pending send 2",
                pinning: nil,
                quotedMessageId: nil,
                isSilent: false,
                skipPush: false,
                skipEnrichUrl: false,
                extraData: [:]
            )
            message2.localMessageState = .pendingSend
            message2Id = message2.id

            let message3 = try session.createNewMessage(
                in: self.cid,
                messageId: .unique,
                text: "Message pending send 3",
                pinning: nil,
                quotedMessageId: nil,
                isSilent: false,
                skipPush: false,
                skipEnrichUrl: false,
                extraData: [:]
            )
            message3.localMessageState = .pendingSend
            message3Id = message3.id
        }

        // Check the 1st call
        AssertAsync.willBeEqual(messageRepository.sendMessageCalls.first?.key, message1Id)

        let m1 = ChatMessage.mock(id: message1Id, cid: cid, text: "Message sent", author: .unique)
        let callback1 = messageRepository.sendMessageCalls.first?.value
        messageRepository.sendMessageCalls = [:]
        callback1?(.success(m1))

        // Check the 2nd call
        AssertAsync.willBeEqual(messageRepository.sendMessageCalls.first?.key, message2Id)

        // Simulate the second call response
        let m2 = ChatMessage.mock(id: message2Id, cid: cid, text: "Message sent", author: .unique)
        let callback2 = messageRepository.sendMessageCalls.first?.value
        messageRepository.sendMessageCalls = [:]
        callback2?(.success(m2))

        // Check the 3rd API call
        AssertAsync.willBeEqual(messageRepository.sendMessageCalls.first?.key, message3Id)
    }

    func test_senderSendsMessages_forMultipleChannelsInParalel_butStillInTheCorrectOrder() throws {
        let cidA = cid!
        let cidB = ChannelId.unique
        try database.createChannel(cid: cidB)

        var channelA_message1: MessageId!
        var channelA_message2: MessageId!

        var channelB_message1: MessageId!
        var channelB_message2: MessageId!

        // Create 2 new messages in two channel the DB
        try database.writeSynchronously { session in
            let messageA1 = try session.createNewMessage(
                in: cidA,
                messageId: .unique,
                text: "Channel A message 1",
                pinning: nil,
                quotedMessageId: nil,
                isSilent: false,
                skipPush: false,
                skipEnrichUrl: false,
                extraData: [:]
            )
            messageA1.localMessageState = .pendingSend
            channelA_message1 = messageA1.id

            let messageA2 = try session.createNewMessage(
                in: cidA,
                messageId: .unique,
                text: "Channel A message 2",
                pinning: nil,
                quotedMessageId: nil,
                isSilent: false,
                skipPush: false,
                skipEnrichUrl: false,
                extraData: [:]
            )
            messageA2.localMessageState = .pendingSend
            channelA_message2 = messageA2.id

            let messageB1 = try session.createNewMessage(
                in: cidB,
                messageId: .unique,
                text: "Channel B message 1",
                pinning: nil,
                quotedMessageId: nil,
                isSilent: false,
                skipPush: false,
                skipEnrichUrl: false,
                extraData: [:]
            )
            messageB1.localMessageState = .pendingSend
            channelB_message1 = messageB1.id

            let messageB2 = try session.createNewMessage(
                in: cidB,
                messageId: .unique,
                text: "Channel B message 2",
                pinning: nil,
                quotedMessageId: nil,
                isSilent: false,
                skipPush: false,
                skipEnrichUrl: false,
                extraData: [:]
            )
            messageB2.localMessageState = .pendingSend
            channelB_message2 = messageB2.id
        }

        // Wait for 2 repository calls to be made
        AssertAsync.willBeEqual(messageRepository.sendMessageCalls.count, 2)
        XCTAssertTrue(messageRepository.sendMessageCalls.keys.contains(channelA_message1))
        XCTAssertTrue(messageRepository.sendMessageCalls.keys.contains(channelB_message1))

        // Simulate successful responses for both calls
        messageRepository.sendMessageCalls.forEach {
            let message = ChatMessage.mock(id: $0.key, cid: cid, text: "Message sent", author: .unique)
            $0.value(.success(message))
        }

        // Wait for 2 more repository calls to be made
        AssertAsync.willBeEqual(messageRepository.sendMessageCalls.count, 4)
        XCTAssertTrue(messageRepository.sendMessageCalls.keys.contains(channelA_message2))
        XCTAssertTrue(messageRepository.sendMessageCalls.keys.contains(channelB_message2))

        // Check the repository calls are for the second messages from both channels
        messageRepository.sendMessageCalls.forEach {
            let message = ChatMessage.mock(id: $0.key, cid: cid, text: "Message sent", author: .unique)
            $0.value(.success(message))
        }
    }

    func test_sender_sendsMessage_whenError_sendsEvent() throws {
        var messageId: MessageId!

        struct MockError: Error {}
        messageRepository.sendMessageResult = .failure(.failedToSendMessage(MockError()))

        try database.writeSynchronously { session in
            let message = try session.createNewMessage(
                in: self.cid,
                messageId: .unique,
                text: "Message pending send",
                pinning: nil,
                quotedMessageId: nil,
                isSilent: false,
                skipPush: false,
                skipEnrichUrl: false,
                attachments: [
                    .init(payload: TestAttachmentPayload.unique),
                    .init(payload: TestAttachmentPayload.unique)
                ],
                extraData: [:]
            )
            message.localMessageState = .pendingSend
            messageId = message.id
        }

        AssertAsync.willBeTrue(messageRepository.sendMessageIds.contains(where: { $0 == messageId }))
        AssertAsync.willBeTrue(eventsNotificationCenter.mock_processCalledWithEvents.first is NewMessageErrorEvent)
        XCTAssertCall("sendMessage(with:completion:)", on: messageRepository, times: 1)
    }

    // MARK: - Life cycle tests

    func test_sender_doesNotRetainItself() throws {
        let messageId: MessageId = .unique

        // Create a message with pending state
        try database.createMessage(id: messageId, cid: cid, text: "Message pending send", localState: .pendingSend)

        // Wait for the repository call
        AssertAsync.willBeTrue(messageRepository.sendMessageCalls.count == 1)

        // Assert sender can be released even though network response hasn't come yet
        AssertAsync.canBeReleased(&sender)
    }

    // MARK: Rescue messages

    func test_sender_startsMessagesRescueOnInit() throws {
        // Given
        let channelId = ChannelId.unique
        let messageId = MessageId.unique

        try database.writeSynchronously { session in
            try session.saveChannel(payload: .dummy(channel: .dummy(cid: channelId)))
            let message = try session.saveMessage(
                payload: .dummy(messageId: messageId),
                for: channelId,
                syncOwnReactions: false,
                cache: nil
            )
            message.localMessageState = .sending
        }

        let initialMessages = MessageDTO.loadSendingMessages(context: database.viewContext)
        XCTAssertEqual(initialMessages.count, 1)
        XCTAssertEqual(initialMessages.first?.id, messageId)
        XCTAssertEqual(initialMessages.first?.localMessageState, .sending)

        // When
        let sessionMock = DatabaseSessionRescueListener(underlyingSession: database.writableContext)
        let mockDatabase = DatabaseContainer_Spy(sessionMock: sessionMock)
        sender = .init(
            messageRepository: messageRepository,
            eventsNotificationCenter: EventNotificationCenter_Mock(database: mockDatabase),
            database: mockDatabase,
            apiClient: apiClient
        )

        // Then
        wait(for: [sessionMock.rescueMessagesExpectation], timeout: defaultTimeout)
    }
}

private class DatabaseSessionRescueListener: DatabaseSession_Mock {
    let rescueMessagesExpectation = XCTestExpectation(description: "rescue messages")

    override func rescueMessagesStuckInSending() {
        rescueMessagesExpectation.fulfill()
    }
}
