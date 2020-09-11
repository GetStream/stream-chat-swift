//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient
import XCTest

final class MessageEditor_Tests: StressTestCase {
    typealias ExtraData = DefaultDataTypes
    
    var webSocketClient: WebSocketClientMock!
    var apiClient: APIClientMock!
    var database: DatabaseContainerMock!
    var editor: MessageEditor<ExtraData>!
    
    // MARK: - Setup
    
    override func setUp() {
        super.setUp()
        
        webSocketClient = WebSocketClientMock()
        apiClient = APIClientMock()
        database = try! DatabaseContainerMock(kind: .inMemory)
        editor = MessageEditor(database: database, webSocketClient: webSocketClient, apiClient: apiClient)
    }
    
    override func tearDown() {
        apiClient.cleanUp()
                
        AssertAsync {
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
        
        let message1Payload: MessageRequestBody<ExtraData> = try XCTUnwrap(
            database.viewContext.message(id: message1Id)?
                .asRequestBody()
        )
        let message2Payload: MessageRequestBody<ExtraData> = try XCTUnwrap(
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
    }
    
    func test_editor_changesMessageStates_whenSyncingSucceeds() throws {
        let currentUserId: UserId = .unique
        let messageId: MessageId = .unique
       
        // Create current user in the database
        try database.createCurrentUser(id: currentUserId)
        
        // Create a messages in the DB in `.pendingSync` state
        try database.createMessage(id: messageId, authorId: currentUserId, localState: .pendingSync)
        
        // Load the message
        var message: MessageDTO? {
            database.viewContext.message(id: messageId)
        }
        
        // Check the state is eventually changed to `syncing`
        AssertAsync.willBeEqual(message?.localMessageState, .syncing)
                
        // Wait for the API call to be initiated
        AssertAsync.willBeTrue(apiClient.request_endpoint != nil)
        
        // Simulate successfull API response
        let callback = apiClient.request_completion as! (Result<EmptyResponse, Error>) -> Void
        callback(.success(.init()))
        
        // Check the state is eventually changed to `nil`
        AssertAsync.willBeEqual(message?.localMessageState, nil)
    }
    
    func test_editor_changesMessageStates_whenSyncingFails() throws {
        let currentUserId: UserId = .unique
        let messageId: MessageId = .unique
        
        // Create current user in the database
        try database.createCurrentUser(id: currentUserId)
        
        // Create a messages in the DB in `.pendingSync` state
        try database.createMessage(id: messageId, authorId: currentUserId, localState: .pendingSync)
        
        // Load the message
        var message: MessageDTO? {
            database.viewContext.message(id: messageId)
        }
        
        // Check the state is eventually changed to `syncing`
        AssertAsync.willBeEqual(message?.localMessageState, .syncing)
                
        // Wait for the API call to be initiated
        AssertAsync.willBeTrue(apiClient.request_endpoint != nil)
        
        // Simulate API response with the error
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.failure(TestError()))
        
        // Check the state is eventually changed to `syncingFailed`
        AssertAsync.willBeEqual(message?.localMessageState, .syncingFailed)
    }
    
    func test_editor_doesNotRetainItself() throws {
        let currentUserId: UserId = .unique
        let messageId: MessageId = .unique
        
        // Create current user in the database
        try database.createCurrentUser(id: currentUserId)
        
        // Create a messages in the DB in `.pendingSync` state
        try database.createMessage(id: messageId, authorId: currentUserId, localState: .pendingSync)
        
        // Load the message
        var message: MessageDTO? {
            database.viewContext.message(id: messageId)
        }
        
        AssertAsync {
            // Check the state is eventually changed to `syncing`
            Assert.willBeEqual(message?.localMessageState, .syncing)
            // API call is initiated
            Assert.willBeTrue(self.apiClient.request_endpoint != nil)
        }
        
        // Assert editor can be released even though response hasn't come yet
        AssertAsync.canBeReleased(&editor)
    }
}
