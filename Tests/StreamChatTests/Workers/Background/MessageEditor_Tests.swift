//
// Copyright © 2024 Stream.io Inc. All rights reserved.
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
                $0.endpoint == AnyEndpoint(.editMessage(payload: message1Payload, skipEnrichUrl: false))
            }))
            Assert.staysFalse(self.apiClient.request_allRecordedCalls.contains(where: {
                $0.endpoint == AnyEndpoint(.editMessage(payload: message2Payload, skipEnrichUrl: false))
            }))
        }

        XCTAssertCall("updateMessage(withID:localState:completion:)", on: messageRepository, times: 1)
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
            attachmentDTO.localState = .uploaded
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
                $0.endpoint == AnyEndpoint(.editMessage(payload: message1Payload, skipEnrichUrl: false))
            }.count, 1)
        }
        XCTAssertCall("updateMessage(withID:localState:completion:)", on: messageRepository, times: 1)
    }

    func test_editorSyncsMessage_whenAttachmentFinishesUploading() throws {
        let currentUserId: UserId = .unique
        let cid: ChannelId = .unique
        let messageId: MessageId = .unique

        // We create a message with an attachment in progress.
        try database.createCurrentUser(id: currentUserId)
        try database.createMessage(id: messageId, authorId: currentUserId, cid: cid, localState: .syncingFailed)
        try database.writeSynchronously { session in
            let attachmentDTO = try session.saveAttachment(
                payload: .dummy(),
                id: .init(cid: cid, messageId: messageId, index: 0)
            )
            attachmentDTO.localState = .uploading(progress: 0.3)
            let messageDTO = session.message(id: messageId)
            messageDTO?.attachments.insert(attachmentDTO)
        }

        // When changing state to pendingSync, should not trigger any update because there are pending attachments
        apiClient.request_expectation = expectation(description: "should not update message if attachments are in progress")
        apiClient.request_expectation.isInverted = true
        try database.writeSynchronously { session in
            let messageDTO = session.message(id: messageId)
            messageDTO?.localMessageState = .pendingSync
        }
        wait(for: [apiClient.request_expectation], timeout: defaultTimeout)

        // When the attachments finish uploading, it should finally sync the message.
        apiClient.request_expectation = expectation(description: "should update message when attachment is finished uploaded")
        try database.writeSynchronously { session in
            let messageDTO = try XCTUnwrap(session.message(id: messageId))
            messageDTO.attachments.first!.localState = .uploaded
        }
        wait(for: [apiClient.request_expectation], timeout: defaultTimeout)

        // Then
        XCTAssertTrue(apiClient.request_allRecordedCalls.count == 1)
        XCTAssertCall("updateMessage(withID:localState:completion:)", on: messageRepository, times: 1)
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
        XCTAssertCall("updateMessage(withID:localState:completion:)", on: messageRepository, times: 1)

        // Wait for the API call to be initiated
        AssertAsync.willBeTrue(apiClient.request_endpoint != nil)

        // Simulate successfull API response
        let callback = apiClient.request_completion as! (Result<EmptyResponse, Error>) -> Void
        callback(.success(.init()))

        // Check the state is eventually changed to `nil`
        AssertAsync.willBeEqual(messageRepository.updatedMessageLocalState, nil)
        XCTAssertCall("updateMessage(withID:localState:completion:)", on: messageRepository, times: 2)
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
        XCTAssertCall("updateMessage(withID:localState:completion:)", on: messageRepository, times: 1)

        // Wait for the API call to be initiated
        AssertAsync.willBeTrue(apiClient.request_endpoint != nil)

        // Simulate API response with the error
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.failure(TestError()))

        // Check the state is eventually changed to `syncingFailed`
        AssertAsync.willBeEqual(messageRepository.updatedMessageLocalState, .syncingFailed)
        XCTAssertCall("updateMessage(withID:localState:completion:)", on: messageRepository, times: 2)
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

        XCTAssertCall("updateMessage(withID:localState:completion:)", on: messageRepository, times: 1)
        // Assert editor can be released even though response hasn't come yet
        AssertAsync.canBeReleased(&editor)
    }
}
