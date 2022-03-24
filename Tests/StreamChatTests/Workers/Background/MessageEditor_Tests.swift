//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class MessageEditor_Tests: XCTestCase {
    var webSocketClient: WebSocketClientMock!
    var apiClient: APIClientMock!
    var database: DatabaseContainerMock!
    var messageRepository: MessageRepositoryMock!
    var editor: MessageEditor!
    
    // MARK: - Setup
    
    override func setUp() {
        super.setUp()
        
        webSocketClient = WebSocketClientMock()
        apiClient = APIClientMock()
        database = DatabaseContainerMock()
        messageRepository = MessageRepositoryMock(database: database, apiClient: apiClient)
        editor = MessageEditor(messageRepository: messageRepository, database: database, apiClient: apiClient)
    }
    
    override func tearDown() {
        apiClient.cleanUp()
                
        AssertAsync {
            Assert.canBeReleased(&messageRepository)
            Assert.canBeReleased(&editor)
            Assert.canBeReleased(&webSocketClient)
            Assert.canBeReleased(&apiClient)
            Assert.canBeReleased(&database)
        }

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
