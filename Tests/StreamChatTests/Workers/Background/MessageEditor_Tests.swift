//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class MessageEditor_Tests: XCTestCase {
    var webSocketClient: WebSocketClient_Mock!
    var apiClient: APIClient_Spy!
    var database: DatabaseContainer_Spy!
    var messageRepository: MessageRepository_Mock!
    var editor: MessageEditor!

    // MARK: - Setup

    override func setUp() {
        super.setUp()

        webSocketClient = WebSocketClient_Mock()
        apiClient = APIClient_Spy()
        database = DatabaseContainer_Spy()
        messageRepository = MessageRepository_Mock(database: database, apiClient: apiClient)
        editor = MessageEditor(messageRepository: messageRepository, database: database, apiClient: apiClient)
    }

    override func tearDown() {
        apiClient.cleanUp()
        messageRepository.clear()

        AssertAsync {
            Assert.canBeReleased(&messageRepository)
            Assert.canBeReleased(&editor)
            Assert.canBeReleased(&webSocketClient)
            Assert.canBeReleased(&apiClient)
            Assert.canBeReleased(&database)
        }

        messageRepository = nil
        editor = nil
        apiClient = nil
        database = nil

        super.tearDown()
    }

    // MARK: - Tests

    func test_editorSyncsMessage_withPendingSyncLocalState() throws {
        let currentUserId: UserId = .unique
        let message1Id: MessageId = .unique
        let message2Id: MessageId = .unique

        // Create current user in the database
        try database.createCurrentUser(id: currentUserId)

        // Create 2 messages in the DB, only message 1 has `.pendingSync` local state
        try database.createMessage(id: message1Id, authorId: currentUserId, localState: .pendingSync)
        try database.createMessage(id: message2Id, authorId: currentUserId, localState: nil)

        let message1Payload: MessageRequestBody = try XCTUnwrap(
            database.viewContext.message(id: message1Id)?
                .asRequestBody()
        )
        let message2Payload: MessageRequestBody = try XCTUnwrap(
            database.viewContext.message(id: message2Id)?
                .asRequestBody()
        )

        // Check only the message1 was synced
        AssertAsync {
            Assert.willBeTrue(self.apiClient.request_allRecordedCalls.contains(where: {
                $0.endpoint == AnyEndpoint(.editMessage(payload: message1Payload))
            }))
            Assert.staysFalse(self.apiClient.request_allRecordedCalls.contains(where: {
                $0.endpoint == AnyEndpoint(.editMessage(payload: message2Payload))
            }))
        }

        XCTAssertCall("updateMessage(withID:localState:isBounced:completion:)", on: messageRepository, times: 1)
    }

    func test_editorSyncsMessage_whenMessageChangesToPendingSyncAndHasAttachmentsUploadedFromServer() throws {
        let currentUserId: UserId = .unique
        let messageId: MessageId = .unique
        let cid: ChannelId = .unique

        // We create a message with an attachment from the server.
        try database.createCurrentUser(id: currentUserId)
        try database.createMessage(id: messageId, authorId: currentUserId, cid: cid, localState: nil)
        try database.writeSynchronously { session in
            let attachmentDTO = try session.saveAttachment(
                payload: .dummy(),
                id: .init(cid: cid, messageId: messageId, index: 0)
            )
            let messageDTO = session.message(id: messageId)
            messageDTO?.attachments.insert(attachmentDTO)
        }

        // When we update the message local state to pending sync
        try database.writeSynchronously { session in
            let messageDTO = session.message(id: messageId)
            messageDTO?.localMessageState = .pendingSync
        }

        // Then the message editor updates the message.
        let message1Payload: MessageRequestBody = try XCTUnwrap(
            database.viewContext.message(id: messageId)?
                .asRequestBody()
        )
        AssertAsync {
            Assert.willBeEqual(self.apiClient.request_allRecordedCalls.filter {
                $0.endpoint == AnyEndpoint(.editMessage(payload: message1Payload))
            }.count, 1)
        }
        XCTAssertCall("updateMessage(withID:localState:isBounced:completion:)", on: messageRepository, times: 1)
    }

    func test_editorSyncsMessage_withPendingSyncLocalState_withPendingAttachments() throws {
        let currentUserId: UserId = .unique
        let messageId: MessageId = .unique

        try database.createCurrentUser(id: currentUserId)
        try database.createMessage(
            id: messageId,
            authorId: currentUserId,
            attachments: [MessageAttachmentPayload.dummy()],
            localState: .pendingSync
        )

        let messageDTO = try XCTUnwrap(database.viewContext.message(id: messageId))
        XCTAssertEqual(messageDTO.attachments.count, 1)

        apiClient.request_allRecordedCalls = []

        apiClient.request_expectation = expectation(description: "should call apiClient.request")

        let attachmentId = try XCTUnwrap(messageDTO.attachments.first?.attachmentID)
        try database.writeSynchronously { session in
            let attachment = try XCTUnwrap(session.attachment(id: attachmentId))
            attachment.localState = .uploaded
        }

        wait(for: [apiClient.request_expectation], timeout: defaultTimeout)

        XCTAssertTrue(apiClient.request_allRecordedCalls.count == 1)
        XCTAssertTrue(apiClient.request_allRecordedCalls.contains(where: {
            $0.endpoint == AnyEndpoint(.editMessage(payload: messageDTO.asRequestBody()))
        }))
        XCTAssertCall("updateMessage(withID:localState:isBounced:completion:)", on: messageRepository, times: 1)
    }

    func test_editor_changesMessageStates_whenSyncingSucceeds() throws {
        let currentUserId: UserId = .unique
        let messageId: MessageId = .unique

        // Create current user in the database
        try database.createCurrentUser(id: currentUserId)

        // Create a messages in the DB in `.pendingSync` state
        try database.createMessage(id: messageId, authorId: currentUserId, localState: .pendingSync)

        // Check the state is eventually changed to `syncing`
        AssertAsync.willBeEqual(messageRepository.updatedMessageLocalState, .syncing)
        XCTAssertCall("updateMessage(withID:localState:isBounced:completion:)", on: messageRepository, times: 1)

        // Wait for the API call to be initiated
        AssertAsync.willBeTrue(apiClient.request_endpoint != nil)

        // Simulate successfull API response
        let callback = apiClient.request_completion as! (Result<EmptyResponse, Error>) -> Void
        callback(.success(.init()))

        // Check the state is eventually changed to `nil`
        AssertAsync.willBeEqual(messageRepository.updatedMessageLocalState, nil)
        XCTAssertCall("updateMessage(withID:localState:isBounced:completion:)", on: messageRepository, times: 2)
    }

    func test_editor_changesMessageStates_whenSyncingFails() throws {
        let currentUserId: UserId = .unique
        let messageId: MessageId = .unique

        // Create current user in the database
        try database.createCurrentUser(id: currentUserId)

        // Create a messages in the DB in `.pendingSync` state
        try database.createMessage(id: messageId, authorId: currentUserId, localState: .pendingSync)

        // Check the state is eventually changed to `syncing`
        AssertAsync.willBeEqual(messageRepository.updatedMessageLocalState, .syncing)
        XCTAssertCall("updateMessage(withID:localState:isBounced:completion:)", on: messageRepository, times: 1)

        // Wait for the API call to be initiated
        AssertAsync.willBeTrue(apiClient.request_endpoint != nil)

        // Simulate API response with the error
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.failure(TestError()))

        // Check the state is eventually changed to `syncingFailed`
        AssertAsync.willBeEqual(messageRepository.updatedMessageLocalState, .syncingFailed)
        XCTAssertCall("updateMessage(withID:localState:isBounced:completion:)", on: messageRepository, times: 2)
    }

    func test_editor_doesNotRetainItself() throws {
        let currentUserId: UserId = .unique
        let messageId: MessageId = .unique

        // Create current user in the database
        try database.createCurrentUser(id: currentUserId)

        // Create a messages in the DB in `.pendingSync` state
        try database.createMessage(id: messageId, authorId: currentUserId, localState: .pendingSync)

        AssertAsync {
            // Check the state is eventually changed to `syncing`
            Assert.willBeEqual(self.messageRepository.updatedMessageLocalState, .syncing)
            // API call is initiated
            Assert.willBeTrue(self.apiClient.request_endpoint != nil)
        }

        XCTAssertCall("updateMessage(withID:localState:isBounced:completion:)", on: messageRepository, times: 1)
        // Assert editor can be released even though response hasn't come yet
        AssertAsync.canBeReleased(&editor)
    }
}
