//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient
import XCTest

final class MessageUpdater_Tests: StressTestCase {
    typealias ExtraData = DefaultExtraData
    
    var webSocketClient: WebSocketClientMock!
    var apiClient: APIClientMock!
    var database: DatabaseContainerMock!
    var messageUpdater: MessageUpdater<ExtraData>!
    
    // MARK: Setup
    
    override func setUp() {
        super.setUp()
        
        webSocketClient = WebSocketClientMock()
        apiClient = APIClientMock()
        database = try! DatabaseContainerMock(kind: .inMemory)
        messageUpdater = MessageUpdater(database: database, webSocketClient: webSocketClient, apiClient: apiClient)
    }
    
    override func tearDown() {
        apiClient.cleanUp()
        
        AssertAsync {
            Assert.canBeReleased(&messageUpdater)
            Assert.canBeReleased(&webSocketClient)
            Assert.canBeReleased(&apiClient)
            Assert.canBeReleased(&database)
        }
        
        super.tearDown()
    }
    
    // MARK: Edit message
    
    func test_editMessage_propogates_CurrentUserDoesNotExist_Error() throws {
        // Simulate `editMessage(messageId:, text:)` call
        let completionError = try await {
            messageUpdater.editMessage(messageId: .unique, text: .unique, completion: $0)
        }
        
        // Assert `CurrentUserDoesNotExist` is received
        XCTAssertTrue(completionError is ClientError.CurrentUserDoesNotExist)
    }
    
    func test_editMessage_propogates_MessageDoesNotExist_Error() throws {
        // Create current user is the database
        try database.createCurrentUser()
        
        // Simulate `editMessage(messageId:, text:)` call
        let completionError = try await {
            messageUpdater.editMessage(messageId: .unique, text: .unique, completion: $0)
        }
        
        // Assert `MessageDoesNotExist` is received
        XCTAssertTrue(completionError is ClientError.MessageDoesNotExist)
    }
    
    func test_editMessage_propogates_MessageCanNotBeUpdatedByCurrentUser_Error() throws {
        let anotherUserId: UserId = .unique
        let anotherUserMessageId: MessageId = .unique

        // Create current user is the database
        try database.createCurrentUser()
    
        // Create message authored by another user in the database
        try database.createMessage(id: anotherUserMessageId, authorId: anotherUserId)

        // Try to edit another user's message
        let completionError = try await {
            messageUpdater.editMessage(messageId: anotherUserMessageId, text: .unique, completion: $0)
        }
        
        // Assert `MessageCannotBeUpdatedByCurrentUser` is received
        XCTAssertTrue(completionError is ClientError.MessageCannotBeUpdatedByCurrentUser)
    }

    func test_editMessage_updatesLocalMessageCorrectly() throws {
        let pairs: [(LocalMessageState?, LocalMessageState?)] = [
            (nil, .pendingSync),
            (.pendingSync, .pendingSync),
            (.pendingSend, .pendingSend)
        ]
        
        for (initialState, expectedState) in pairs {
            let currentUserId: UserId = .unique
            let messageId: MessageId = .unique
            let updatedText: String = .unique
            
            // Flush the database
            try database.flush()
            
            // Create current user is the database
            try database.createCurrentUser(id: currentUserId)
            
            // Create a new message in the database
            try database.createMessage(id: messageId, authorId: currentUserId, localState: initialState)
            
            // Edit created message with new text
            let completionError = try await {
                messageUpdater.editMessage(messageId: messageId, text: updatedText, completion: $0)
            }
            
            // Load the message
            let message = try XCTUnwrap(database.viewContext.message(id: messageId))
            
            // Assert completion is called without any error
            XCTAssertNil(completionError)
            // Assert message still has expected local state
            XCTAssertEqual(message.localMessageState, expectedState)
            // Assert message text is updated correctly
            XCTAssertEqual(message.text, updatedText)
        }
    }
    
    func test_editMessage_propogatesMessageEditingError_ifLocalStateIsInvalidForEditing() throws {
        let invalidStates: [LocalMessageState] = [
            .deleting,
            .deletingFailed,
            .sending,
            .sendingFailed,
            .syncing,
            .syncingFailed
        ]
        
        for state in invalidStates {
            let currentUserId: UserId = .unique
            let messageId: MessageId = .unique
            let initialText: String = .unique
            let updatedText: String = .unique
            
            // Flush the database
            try database.flush()
            
            // Create current user is the database
            try database.createCurrentUser(id: currentUserId)
            
            // Create a new message in the database
            try database.createMessage(id: messageId, authorId: currentUserId, text: initialText, localState: state)
            
            // Edit created message with new text
            let completionError = try await {
                messageUpdater.editMessage(messageId: messageId, text: updatedText, completion: $0)
            }
            
            // Load the message
            let message = try XCTUnwrap(database.viewContext.message(id: messageId))
            
            // Assert `MessageEditing` error is received
            XCTAssertTrue(completionError is ClientError.MessageEditing)
            // Assert message stays in the same state
            XCTAssertEqual(message.localMessageState, state)
            // Assert message's text stays the same
            XCTAssertEqual(message.text, initialText)
        }
    }
    
    // MARK: Delete message
    
    func test_deleteMessage_propogates_CurrentUserDoesNotExist_Error() throws {
        // Simulate `deleteMessage(messageId:)` call
        let completionError = try await {
            messageUpdater.deleteMessage(messageId: .unique, completion: $0)
        }
        
        // Assert `CurrentUserDoesNotExist` is received
        XCTAssertTrue(completionError is ClientError.CurrentUserDoesNotExist)
    }
    
    func test_deleteMessage_propogates_MessageCanNotBeUpdatedByCurrentUser_Error() throws {
        let anotherUserId: UserId = .unique
        let anotherUserMessageId: MessageId = .unique
        
        // Create current user is the database
        try database.createCurrentUser()
        
        // Create message authored by another user in the database
        try database.createMessage(id: anotherUserMessageId, authorId: anotherUserId)
        
        // Simulate `deleteMessage(messageId:)` call
        let completionError = try await {
            messageUpdater.deleteMessage(messageId: anotherUserMessageId, completion: $0)
        }
        
        // Assert `MessageCannotBeUpdatedByCurrentUser` is received
        XCTAssertTrue(completionError is ClientError.MessageCannotBeUpdatedByCurrentUser)
    }
    
    func test_deleteMessage_sendsCorrectAPICall_ifMessageDoesNotExistLocally() throws {
        let messageId: MessageId = .unique
        
        // Create current user in the database
        try database.createCurrentUser()
        
        // Simulate `deleteMessage(messageId:)` call
        messageUpdater.deleteMessage(messageId: messageId)
        
        // Assert correct endpoint is called
        let expectedEndpoint: Endpoint<EmptyResponse> = .deleteMessage(messageId: messageId)
        AssertAsync.willBeEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }
    
    func test_deleteMessage_propogatesRequestError() throws {
        let messageId: MessageId = .unique
        
        // Create current user in the database
        try database.createCurrentUser()
        
        // Simulate `deleteMessage(messageId:)` call
        var completionCalledError: Error?
        messageUpdater.deleteMessage(messageId: messageId) {
            completionCalledError = $0
        }
        
        // Assert correct endpoint is called
        let expectedEndpoint: Endpoint<EmptyResponse> = .deleteMessage(messageId: messageId)
        AssertAsync.willBeEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
        
        // Simulate API response with success
        let testError = TestError()
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.failure(testError))
                
        // Assert completion is called without any error
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
    }
    
    func test_deleteMessage_propogatesDatabaseError_beforeAPICall() throws {
        // Update database container to throw the error on write
        let databaseError = TestError()
        database.write_errorResponse = databaseError
        
        // Simulate `deleteMessage(messageId:)` call
        let completionError = try await {
            messageUpdater.deleteMessage(messageId: .unique, completion: $0)
        }
        
        // Assert database error is propogated
        XCTAssertEqual(completionError as? TestError, databaseError)
    }
    
    func test_deleteMessage_propogatesDatabaseError_afterAPICall() throws {
        let messageId: MessageId = .unique

        // Create current user in the database
        try database.createCurrentUser()

        // Simulate `deleteMessage(messageId:)` call
        var completionCalledError: Error?
        messageUpdater.deleteMessage(messageId: messageId) {
            completionCalledError = $0
        }
        
        // Assert correct endpoint is called
        let expectedEndpoint: Endpoint<EmptyResponse> = .deleteMessage(messageId: messageId)
        AssertAsync.willBeEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
        
        // Update database container to throw the error on write
        let databaseError = TestError()
        database.write_errorResponse = databaseError
        
        // Simulate API response with success
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.success(.init()))
                
        // Assert database error is propogated
        AssertAsync.willBeEqual(completionCalledError as? TestError, databaseError)
    }

    func test_deleteMessage_removesMessageThatExistOnlyLocally() throws {
        for state in [LocalMessageState.pendingSend, .sendingFailed] {
            let currentUserId: UserId = .unique
            let messageId: MessageId = .unique

            // Flush the database
            try database.flush()
            
            // Create current user in the database
            try database.createCurrentUser(id: currentUserId)
                   
            // Create a new message in the database
            try database.createMessage(id: messageId, authorId: currentUserId, localState: state)

            // Simulate `deleteMessage(messageId:)` call
            var completionCalled = false
            messageUpdater.deleteMessage(messageId: messageId) { error in
                XCTAssertNil(error)
                completionCalled = true
            }
            
            var message: MessageDTO? {
                database.viewContext.message(id: messageId)
            }
            
            AssertAsync {
                // Assert completion is called
                Assert.willBeTrue(completionCalled)
                // Assert message is deleted locally
                Assert.willBeTrue(message == nil)
                // Assert API is not called
                Assert.staysTrue(self.apiClient.request_endpoint == nil)
            }
        }
    }
    
    func test_deleteMessage_updatesMessageStateCorrectly() throws {
        let pairs: [(Result<EmptyResponse, Error>, LocalMessageState?)] = [
            (.success(.init()), nil),
            (.failure(TestError()), .deletingFailed)
        ]
        
        for (networkResult, expectedState) in pairs {
            let currentUserId: UserId = .unique
            let messageId: MessageId = .unique
            
            // Flush the database
            try database.flush()
            
            // Create current user in the database
            try database.createCurrentUser(id: currentUserId)
            
            // Create message authored by current user in the database
            try database.createMessage(id: messageId, authorId: currentUserId)
            
            // Simulate `deleteMessage(messageId:)` call
            messageUpdater.deleteMessage(messageId: messageId)
            
            // Load the message
            let message = try XCTUnwrap(database.viewContext.message(id: messageId))
            
            // Assert message's local state becomes `deleting`
            AssertAsync.willBeEqual(message.localMessageState, .deleting)
            
            // Simulate API response
            apiClient.test_simulateResponse(networkResult)
            
            // Assert message's local state becomes expected
            AssertAsync.willBeEqual(message.localMessageState, expectedState)
        }
    }
    
    // MARK: Get message
    
    func test_getMessage_makesCorrectAPICall() {
        let cid: ChannelId = .unique
        let messageId: MessageId = .unique
        
        // Simulate `getMessage(cid:, messageId:)` call
        messageUpdater.getMessage(cid: cid, messageId: messageId)
                
        // Assert correct endpoint is called
        let expectedEndpoint: Endpoint<MessagePayload<ExtraData>> = .getMessage(messageId: messageId)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }
    
    func test_getMessage_propogatesRequestError() {
        // Simulate `getMessage(cid:, messageId:)` call
        var completionCalledError: Error?
        messageUpdater.getMessage(cid: .unique, messageId: .unique) {
            completionCalledError = $0
        }
        
        // Simulate API response with failure
        let error = TestError()
        apiClient.test_simulateResponse(Result<MessagePayload<ExtraData>, Error>.failure(error))
                
        // Assert the completion is called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }
    
    func test_getMessage_propogatesDatabaseError() {
        let messagePayload: MessagePayload<ExtraData> = .dummy(messageId: .unique, authorUserId: .unique)
        
        // Update database container to throw the error on write
        let testError = TestError()
        database.write_errorResponse = testError
        
        // Simulate `getMessage(cid:, messageId:)` call
        var completionCalledError: Error?
        messageUpdater.getMessage(cid: .unique, messageId: messagePayload.id) {
            completionCalledError = $0
        }
        
        // Simulate API response with success
        apiClient.test_simulateResponse(Result<MessagePayload<ExtraData>, Error>.success(messagePayload))
                
        // Assert database error is propogated
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
    }
    
    func test_getMessage_savesMessageToDatabase() throws {
        let currentUserId: UserId = .unique
        let messageId: MessageId = .unique
        let cid: ChannelId = .unique

        // Create current user in the database
        try database.createCurrentUser(id: currentUserId)
        
        // Create channel in the database
        try database.createChannel(cid: cid)
        
        // Simulate `getMessage(cid:, messageId:)` call
        var completionCalled = false
        messageUpdater.getMessage(cid: cid, messageId: messageId) { _ in
            completionCalled = true
        }
        
        // Simulate API response with success
        let messagePayload: MessagePayload<ExtraData> = .dummy(messageId: messageId, authorUserId: currentUserId)
        apiClient.test_simulateResponse(Result<MessagePayload<ExtraData>, Error>.success(messagePayload))
        
        // Assert completion is called
        AssertAsync.willBeTrue(completionCalled)
        
        // Assert fetched message is saved to the database
        XCTAssertNotNil(database.viewContext.message(id: messageId))
    }
}
