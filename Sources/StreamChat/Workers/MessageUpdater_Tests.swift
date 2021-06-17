//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class MessageUpdater_Tests: StressTestCase {
    typealias ExtraData = NoExtraData
    
    var webSocketClient: WebSocketClientMock!
    var apiClient: APIClientMock!
    var database: DatabaseContainerMock!
    var messageUpdater: MessageUpdater<ExtraData>!
    
    // MARK: Setup
    
    override func setUp() {
        super.setUp()
        
        webSocketClient = WebSocketClientMock()
        apiClient = APIClientMock()
        database = DatabaseContainerMock()
        messageUpdater = MessageUpdater(database: database, apiClient: apiClient)
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
        let completionError = try waitFor {
            messageUpdater.editMessage(messageId: .unique, text: .unique, completion: $0)
        }
        
        // Assert `CurrentUserDoesNotExist` is received
        XCTAssertTrue(completionError is ClientError.CurrentUserDoesNotExist)
    }
    
    func test_editMessage_propogates_MessageDoesNotExist_Error() throws {
        // Create current user is the database
        try database.createCurrentUser()
        
        // Simulate `editMessage(messageId:, text:)` call
        let completionError = try waitFor {
            messageUpdater.editMessage(messageId: .unique, text: .unique, completion: $0)
        }
        
        // Assert `MessageDoesNotExist` is received
        XCTAssertTrue(completionError is ClientError.MessageDoesNotExist)
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
            try database.removeAllData()
            
            // Create current user is the database
            try database.createCurrentUser(id: currentUserId)
            
            // Create a new message in the database
            try database.createMessage(id: messageId, authorId: currentUserId, localState: initialState)
            
            // Edit created message with new text
            let completionError = try waitFor {
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
            .sending,
            .syncing
        ]
        
        for state in invalidStates {
            let currentUserId: UserId = .unique
            let messageId: MessageId = .unique
            let initialText: String = .unique
            let updatedText: String = .unique
            
            // Flush the database
            try database.removeAllData()
            
            // Create current user is the database
            try database.createCurrentUser(id: currentUserId)
            
            // Create a new message in the database
            try database.createMessage(id: messageId, authorId: currentUserId, text: initialText, localState: state)
            
            // Edit created message with new text
            let completionError = try waitFor {
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
        let completionError = try waitFor {
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

    func test_deleteMessage_softlyRemovesMessageThatExistOnlyLocally() throws {
        for state in [LocalMessageState.pendingSend, .sendingFailed] {
            let currentUserId: UserId = .unique
            let messageId: MessageId = .unique

            // Flush the database
            try database.removeAllData()
            
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
            
            let message = try XCTUnwrap(database.viewContext.message(id: messageId))
            
            AssertAsync {
                // Assert completion is called
                Assert.willBeTrue(completionCalled)
                // Assert `deletedAt` is set for the message
                Assert.willBeTrue(message.deletedAt != nil)
                // Assert `type` is set to `.deleted`
                Assert.willBeEqual(message.type, MessageType.deleted.rawValue)
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
            try database.removeAllData()
            
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
        let expectedEndpoint: Endpoint<MessagePayload<ExtraData>.Boxed> = .getMessage(messageId: messageId)
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
        apiClient.test_simulateResponse(Result<MessagePayload<ExtraData>.Boxed, Error>.failure(error))
                
        // Assert the completion is called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }
    
    func test_getMessage_propogatesDatabaseError() throws {
        let messagePayload: MessagePayload<ExtraData>.Boxed = .init(
            message: .dummy(messageId: .unique, authorUserId: .unique)
        )
        let channelId = ChannelId.unique

        // Create channel in the database
        try database.createChannel(cid: channelId)
        
        // Update database container to throw the error on write
        let testError = TestError()
        database.write_errorResponse = testError
        
        // Simulate `getMessage(cid:, messageId:)` call
        var completionCalledError: Error?
        messageUpdater.getMessage(cid: channelId, messageId: messagePayload.message.id) {
            completionCalledError = $0
        }
        
        // Simulate API response with success
        apiClient.test_simulateResponse(Result<MessagePayload<ExtraData>.Boxed, Error>.success(messagePayload))
                
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
        let messagePayload: MessagePayload<ExtraData>.Boxed = .init(
            message: .dummy(messageId: messageId, authorUserId: currentUserId)
        )
        apiClient.test_simulateResponse(Result<MessagePayload<ExtraData>.Boxed, Error>.success(messagePayload))
        
        // Assert completion is called
        AssertAsync.willBeTrue(completionCalled)
        
        // Assert fetched message is saved to the database
        XCTAssertNotNil(database.viewContext.message(id: messageId))
    }
    
    // MARK: - Create new reply
    
    func test_createNewReply_savesMessageToDatabase() throws {
        // Prepare the current user and channel first
        let cid: ChannelId = .unique
        let currentUserId: UserId = .unique
        
        try database.createCurrentUser(id: currentUserId)
        try database.createChannel(cid: cid)
        
        // New reply message values
        let text: String = .unique
        let parentMessageId: MessageId = .unique
        let showReplyInChannel = true
        let command: String = .unique
        let arguments: String = .unique
        let extraData: NoExtraData = .defaultValue

        let imageAttachmentEnvelope = AnyAttachmentPayload.mockImage
        let fileAttachmentEnvelope = AnyAttachmentPayload.mockFile
        let customAttachmentEnvelope = AnyAttachmentPayload(payload: TestAttachmentPayload.unique)
        let attachmentEnvelopes: [AnyAttachmentPayload] = [
            imageAttachmentEnvelope,
            fileAttachmentEnvelope,
            customAttachmentEnvelope
        ]
        let mentionedUserIds: [UserId] = [currentUserId]

        // Create new reply message
        let newMessageId: MessageId = try waitFor { completion in
            messageUpdater.createNewReply(
                in: cid,
                text: text,
                pinning: MessagePinning(expirationDate: .unique),
                command: command,
                arguments: arguments,
                parentMessageId: parentMessageId,
                attachments: attachmentEnvelopes,
                mentionedUserIds: mentionedUserIds,
                showReplyInChannel: showReplyInChannel,
                quotedMessageId: nil,
                extraData: extraData
            ) { result in
                if let newMessageId = try? result.get() {
                    completion(newMessageId)
                } else {
                    XCTFail("Saving the message failed.")
                }
            }
        }

        func id(for envelope: AnyAttachmentPayload) -> AttachmentId {
            .init(cid: cid, messageId: newMessageId, index: attachmentEnvelopes.firstIndex(of: envelope)!)
        }
        
        let message: ChatMessage = try XCTUnwrap(database.viewContext.message(id: newMessageId)?.asModel())
        
        XCTAssertEqual(message.text, text)
        XCTAssertEqual(message.command, command)
        XCTAssertEqual(message.arguments, arguments)
        XCTAssertEqual(message.parentMessageId, parentMessageId)
        XCTAssertEqual(message.showReplyInChannel, showReplyInChannel)
        XCTAssertEqual(message.attachmentCounts.count, 3)
        XCTAssertEqual(message.imageAttachments, [imageAttachmentEnvelope.attachment(id: id(for: imageAttachmentEnvelope))])
        XCTAssertEqual(message.fileAttachments, [fileAttachmentEnvelope.attachment(id: id(for: fileAttachmentEnvelope))])
        XCTAssertEqual(
            message.attachments(payloadType: TestAttachmentPayload.self),
            [customAttachmentEnvelope.attachment(id: id(for: customAttachmentEnvelope))]
        )
        XCTAssertEqual(message.extraData, extraData)
        XCTAssertEqual(message.localState, .pendingSend)
        XCTAssertTrue(message.isPinned)
        XCTAssertEqual(message.mentionedUsers.map(\.id), mentionedUserIds)
    }
    
    func test_createNewMessage_propagatesErrorWhenSavingFails() throws {
        // Prepare the current user and channel first
        let cid: ChannelId = .unique
        let currentUserId: UserId = .unique
        
        try database.createCurrentUser(id: currentUserId)
        try database.createChannel(cid: cid)

        // Simulate the DB failing with `TestError`
        let testError = TestError()
        database.write_errorResponse = testError
        
        let result: Result<MessageId, Error> = try waitFor { completion in
            messageUpdater.createNewReply(
                in: .unique,
                text: .unique,
                pinning: nil,
                command: .unique,
                arguments: .unique,
                parentMessageId: .unique,
                attachments: [],
                mentionedUserIds: [.unique],
                showReplyInChannel: false,
                quotedMessageId: nil,
                extraData: .defaultValue
            ) { completion($0) }
        }
        
        AssertResultFailure(result, testError)
    }
    
    // MARK: Load replies
    
    func test_loadReplies_makesCorrectAPICall() {
        let messageId: MessageId = .unique
        let pagination: MessagesPagination = .init(pageSize: 25)
        
        // Simulate `loadReplies` call
        messageUpdater.loadReplies(cid: .unique, messageId: messageId, pagination: pagination)
        
        // Assert correct endpoint is called
        let expectedEndpoint: Endpoint<MessageRepliesPayload<ExtraData>> = .loadReplies(
            messageId: messageId,
            pagination: pagination
        )
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }
    
    func test_loadReplies_propagatesRequestError() {
        // Simulate `loadReplies` call
        var completionCalledError: Error?
        messageUpdater.loadReplies(cid: .unique, messageId: .unique, pagination: .init(pageSize: 25)) {
            completionCalledError = $0
        }
        
        // Simulate API response with failure
        let error = TestError()
        apiClient.test_simulateResponse(Result<MessageRepliesPayload<ExtraData>, Error>.failure(error))
        
        // Assert the completion is called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }
    
    func test_loadReplies_propagatesDatabaseError() throws {
        let repliesPayload: MessageRepliesPayload<ExtraData> = .init(messages: [.dummy(messageId: .unique, authorUserId: .unique)])
        let cid = ChannelId.unique

        // Create channel in the database
        try database.createChannel(cid: cid)

        // Update database container to throw the error on write
        let testError = TestError()
        database.write_errorResponse = testError
        
        // Simulate `loadReplies` call
        var completionCalledError: Error?
        messageUpdater.loadReplies(cid: cid, messageId: .unique, pagination: .init(pageSize: 25)) {
            completionCalledError = $0
        }
        
        // Simulate API response with success
        apiClient.test_simulateResponse(Result<MessageRepliesPayload<ExtraData>, Error>.success(repliesPayload))
        
        // Assert database error is propagated
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
    }
    
    func test_loadReplies_savesMessagesToDatabase() throws {
        let currentUserId: UserId = .unique
        let messageId: MessageId = .unique
        let cid: ChannelId = .unique
        
        // Create current user in the database
        try database.createCurrentUser(id: currentUserId)
        
        // Create channel in the database
        try database.createChannel(cid: cid)
        
        // Simulate `loadReplies` call
        var completionCalled = false
        messageUpdater.loadReplies(cid: cid, messageId: .unique, pagination: .init(pageSize: 25)) { _ in
            completionCalled = true
        }
        
        // Simulate API response with success
        let repliesPayload: MessageRepliesPayload<ExtraData> = .init(
            messages: [.dummy(messageId: messageId, authorUserId: .unique)]
        )
        apiClient.test_simulateResponse(Result<MessageRepliesPayload<ExtraData>, Error>.success(repliesPayload))
        
        // Assert completion is called
        AssertAsync.willBeTrue(completionCalled)
        
        // Assert fetched message is saved to the database
        XCTAssertNotNil(database.viewContext.message(id: messageId))
    }
    
    // MARK: - Flag message
    
    func test_flagMessage_happyPath() throws {
        let currentUserId: UserId = .unique
        let messageId: MessageId = .unique
        let cid: ChannelId = .unique
        
        // Create current user in the database
        try database.createCurrentUser(id: currentUserId)
        
        // Load current user.
        let currentUserDTO = try XCTUnwrap(database.viewContext.currentUser)
        
        // Create channel in the database.
        try database.createChannel(cid: cid)
        
        // Simulate `flagMessage` call.
        var flagCompletionCalled = false
        messageUpdater.flagMessage(true, with: messageId, in: cid) { error in
            XCTAssertNil(error)
            flagCompletionCalled = true
        }
        
        // Assert message endpoint is called.
        let messageEndpoint: Endpoint<MessagePayload<ExtraData>.Boxed> = .getMessage(messageId: messageId)
        AssertAsync.willBeEqual(apiClient.request_endpoint, AnyEndpoint(messageEndpoint))
        
        // Simulate message response with success.
        let messagePayload: MessagePayload<ExtraData>.Boxed = .init(
            message: .dummy(messageId: messageId, authorUserId: currentUserId)
        )
        apiClient.test_simulateResponse(.success(messagePayload))
        
        // Assert flag endpoint is called.
        let flagEndpoint: Endpoint<FlagMessagePayload<ExtraData.User>> = .flagMessage(true, with: messageId)
        AssertAsync.willBeEqual(apiClient.request_endpoint, AnyEndpoint(flagEndpoint))
        
        // Simulate flag API response.
        let flagMessagePayload = FlagMessagePayload<ExtraData.User>(
            currentUser: .dummy(userId: currentUserId, role: .user),
            flaggedMessageId: messageId
        )
        apiClient.test_simulateResponse(.success(flagMessagePayload))

        // Load the message.
        var messageDTO: MessageDTO? {
            database.viewContext.message(id: messageId)
        }
        
        AssertAsync {
            // Assert flag completion is called.
            Assert.willBeTrue(flagCompletionCalled)
            // Assert current user has the message flagged.
            Assert.willBeTrue(messageDTO.flatMap { currentUserDTO.flaggedMessages.contains($0) } ?? false)
            // Assert message is flagged by current user.
            Assert.willBeEqual(messageDTO?.flaggedBy, currentUserDTO)
        }
        
        // Simulate `unflagMessage` call.
        var unflagCompletionCalled = false
        messageUpdater.flagMessage(false, with: messageId, in: cid) { error in
            XCTAssertNil(error)
            unflagCompletionCalled = true
        }
        
        // Assert unflag endpoint is called.
        let unflagEndpoint: Endpoint<FlagMessagePayload<ExtraData.User>> = .flagMessage(false, with: messageId)
        AssertAsync.willBeEqual(apiClient.request_endpoint, AnyEndpoint(unflagEndpoint))
        
        // Simulate unflag API response.
        apiClient.test_simulateResponse(.success(flagMessagePayload))
        
        AssertAsync {
            // Assert unflag completion is called.
            Assert.willBeTrue(unflagCompletionCalled)
            // Assert current user doesn't have the message as flagged.
            Assert.willBeFalse(messageDTO.flatMap { currentUserDTO.flaggedMessages.contains($0) } ?? true)
            // Assert message is not flagged by current user anymore.
            Assert.willBeEqual(messageDTO?.flaggedBy, nil)
        }
    }
    
    func test_flagMessage_propagatesMessageNetworkError() {
        let messageId: MessageId = .unique
        let cid: ChannelId = .unique
        
        // Simulate `flagMessage` call and catch the error.
        var completionCalledError: Error?
        messageUpdater.flagMessage(true, with: messageId, in: cid) {
            completionCalledError = $0
        }
        
        // Assert message endpoint is called.
        let messageEndpoint: Endpoint<MessagePayload<ExtraData>.Boxed> = .getMessage(messageId: messageId)
        AssertAsync.willBeEqual(apiClient.request_endpoint, AnyEndpoint(messageEndpoint))
        
        // Simulate message response with failure.
        let networkError = TestError()
        apiClient.test_simulateResponse(Result<MessagePayload<ExtraData>.Boxed, Error>.failure(networkError))
        
        // Assert the message network error is propogated.
        AssertAsync.willBeEqual(completionCalledError as? TestError, networkError)
    }
    
    func test_flagMessage_propagatesMessageDatabaseError() throws {
        let currentUserId: UserId = .unique
        let messageId: MessageId = .unique
        let cid: ChannelId = .unique

        // Create channel in the database
        try database.createChannel(cid: cid)
        
        // Update database to throw the error on write.
        let databaseError = TestError()
        database.write_errorResponse = databaseError
        
        // Simulate `flagMessage` call and catch the error.
        var completionCalledError: Error?
        messageUpdater.flagMessage(true, with: messageId, in: cid) {
            completionCalledError = $0
        }
        
        // Assert message endpoint is called.
        let messageEndpoint: Endpoint<MessagePayload<ExtraData>.Boxed> = .getMessage(messageId: messageId)
        AssertAsync.willBeEqual(apiClient.request_endpoint, AnyEndpoint(messageEndpoint))
        
        // Simulate message response with success.
        let messagePayload: MessagePayload<ExtraData>.Boxed = .init(
            message: .dummy(messageId: messageId, authorUserId: currentUserId)
        )
        apiClient.test_simulateResponse(.success(messagePayload))
        
        // Assert the message database error is propogated.
        AssertAsync.willBeEqual(completionCalledError as? TestError, databaseError)
    }
    
    func test_flagMessage_propagatesFlagNetworkError() throws {
        let messageId: MessageId = .unique
        let cid: ChannelId = .unique
        
        // Save message to the database.
        try database.createMessage(id: messageId)
        
        // Simulate `flagMessage` call and catch the error.
        var completionCalledError: Error?
        messageUpdater.flagMessage(true, with: messageId, in: cid) {
            completionCalledError = $0
        }
        
        // Assert flag endpoint is called.
        let flagEndpoint: Endpoint<FlagMessagePayload<ExtraData.User>> = .flagMessage(true, with: messageId)
        AssertAsync.willBeEqual(apiClient.request_endpoint, AnyEndpoint(flagEndpoint))
        
        // Simulate flag API response with failure.
        let networkError = TestError()
        apiClient.test_simulateResponse(Result<FlagMessagePayload<ExtraData.User>, Error>.failure(networkError))
        
        // Assert the flag database error is propogated.
        AssertAsync.willBeEqual(completionCalledError as? TestError, networkError)
    }
    
    func test_flagMessage_propagatesFlagDatabaseError() throws {
        let currentUserId: UserId = .unique
        let messageId: MessageId = .unique
        let cid: ChannelId = .unique
        
        // Save message to the database.
        try database.createMessage(id: messageId)
        
        // Update database to throw the error on write.
        let databaseError = TestError()
        database.write_errorResponse = databaseError
        
        // Simulate `flagMessage` call and catch the error.
        var completionCalledError: Error?
        messageUpdater.flagMessage(true, with: messageId, in: cid) {
            completionCalledError = $0
        }
        
        // Assert flag endpoint is called.
        let flagEndpoint: Endpoint<FlagMessagePayload<ExtraData.User>> = .flagMessage(true, with: messageId)
        AssertAsync.willBeEqual(apiClient.request_endpoint, AnyEndpoint(flagEndpoint))
        
        // Simulate flag API response with success.
        let payload = FlagMessagePayload<ExtraData.User>(
            currentUser: .dummy(userId: currentUserId, role: .user),
            flaggedMessageId: messageId
        )
        apiClient.test_simulateResponse(.success(payload))
        
        // Assert the flag database error is propogated.
        AssertAsync.willBeEqual(completionCalledError as? TestError, databaseError)
    }
    
    func test_flagMessage_propagatesMessageDoesNotExistError() throws {
        let currentUserId: UserId = .unique
        let messageId: MessageId = .unique
        let cid: ChannelId = .unique
        
        // Save message to the database.
        try database.createMessage(id: messageId)
        
        // Simulate `flagMessage` call and catch the error.
        var completionCalledError: Error?
        messageUpdater.flagMessage(true, with: messageId, in: cid) {
            completionCalledError = $0
        }
        
        // Assert flag endpoint is called.
        let flagEndpoint: Endpoint<FlagMessagePayload<ExtraData.User>> = .flagMessage(true, with: messageId)
        AssertAsync.willBeEqual(apiClient.request_endpoint, AnyEndpoint(flagEndpoint))
        
        // Delete the message from the database.
        try database.writeSynchronously {
            let session = $0 as! NSManagedObjectContext
            let messageDTO = try XCTUnwrap(session.message(id: messageId))
            session.delete(messageDTO)
        }
        
        // Simulate flag API response with success.
        let payload = FlagMessagePayload<ExtraData.User>(
            currentUser: .dummy(userId: currentUserId, role: .user),
            flaggedMessageId: messageId
        )
        apiClient.test_simulateResponse(.success(payload))
        
        // Assert `MessageDoesNotExist` error is propogated.
        AssertAsync.willBeTrue(completionCalledError is ClientError.MessageDoesNotExist)
    }
    
    // MARK: - Add reaction

    func test_addReaction_makesCorrectAPICall() {
        let reactionType: MessageReactionType = "like"
        let reactionScore = 1
        let reactionExtraData: ExtraData.MessageReaction = .defaultValue
        let messageId: MessageId = .unique

        // Simulate `addReaction` call.
        messageUpdater.addReaction(
            reactionType,
            score: reactionScore,
            enforceUnique: false,
            extraData: reactionExtraData,
            messageId: messageId
        )

        // Assert correct endpoint is called.
        XCTAssertEqual(
            apiClient.request_endpoint,
            AnyEndpoint(.addReaction(
                reactionType,
                score: reactionScore,
                enforceUnique: false,
                extraData: reactionExtraData,
                messageId: messageId
            ))
        )
    }

    func test_addReaction_propagatesSuccessfulResponse() {
        // Simulate `addReaction` call
        var completionCalled = false
        messageUpdater.addReaction(
            .init(rawValue: .unique),
            score: 1,
            enforceUnique: false,
            extraData: .defaultValue,
            messageId: .unique
        ) { error in
            XCTAssertNil(error)
            completionCalled = true
        }

        // Assert completion is not called yet
        XCTAssertFalse(completionCalled)

        // Simulate API response with success
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.success(.init()))

        // Assert completion is called
        AssertAsync.willBeTrue(completionCalled)
    }

    func test_addReaction_propagatesError() {
        // Simulate `addReaction` call
        var completionCalledError: Error?
        messageUpdater.addReaction(
            .init(rawValue: .unique),
            score: 1,
            enforceUnique: false,
            extraData: .defaultValue,
            messageId: .unique
        ) {
            completionCalledError = $0
        }

        // Simulate API response with failure
        let error = TestError()
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.failure(error))

        // Assert the completion is called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }
    
    // MARK: - Delete reaction

    func test_deleteReaction_makesCorrectAPICall() {
        let reactionType: MessageReactionType = "like"
        let messageId: MessageId = .unique

        // Simulate `deleteReaction` call.
        messageUpdater.deleteReaction(reactionType, messageId: messageId)

        // Assert correct endpoint is called.
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(.deleteReaction(reactionType, messageId: messageId)))
    }

    func test_deleteReaction_propagatesSuccessfulResponse() {
        // Simulate `deleteReaction` call.
        var completionCalled = false
        messageUpdater.deleteReaction(.init(rawValue: .unique), messageId: .unique) { error in
            XCTAssertNil(error)
            completionCalled = true
        }

        // Assert completion is not called yet.
        XCTAssertFalse(completionCalled)

        // Simulate API response with success.
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.success(.init()))

        // Assert completion is called.
        AssertAsync.willBeTrue(completionCalled)
    }

    func test_deleteReaction_propagatesError() {
        // Simulate `deleteReaction` call.
        var completionCalledError: Error?
        messageUpdater.deleteReaction(.init(rawValue: .unique), messageId: .unique) {
            completionCalledError = $0
        }

        // Simulate API response with failure.
        let error = TestError()
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.failure(error))

        // Assert the completion is called with the error.
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }

    // MARK: - Pinning message

    func test_pinMessage_propogates_MessageDoesNotExist_Error() throws {
        try database.createCurrentUser()

        let completionError = try waitFor {
            messageUpdater.pinMessage(messageId: .unique, pinning: .expirationDate(.unique), completion: $0)
        }

        XCTAssertTrue(completionError is ClientError.MessageDoesNotExist)
    }

    func test_pinMessage_updatesLocalMessageCorrectly() throws {
        let pairs: [(LocalMessageState?, LocalMessageState?)] = [
            (nil, .pendingSync),
            (.pendingSync, .pendingSync),
            (.pendingSend, .pendingSend)
        ]

        for (initialState, expectedState) in pairs {
            let currentUserId: UserId = .unique
            let messageId: MessageId = .unique
            let pin = MessagePinning(expirationDate: .unique)

            // Flush the database
            try database.removeAllData()

            // Create current user is the database
            try database.createCurrentUser(id: currentUserId)

            // Create a new message in the database
            try database.createMessage(id: messageId, authorId: currentUserId, localState: initialState)

            let completionError = try waitFor {
                messageUpdater.pinMessage(messageId: messageId, pinning: pin, completion: $0)
            }

            // Load the message
            let message = try XCTUnwrap(database.viewContext.message(id: messageId))

            XCTAssertNil(completionError)
            XCTAssertEqual(message.localMessageState, expectedState)
            XCTAssertEqual(message.pinned, true)
            XCTAssertEqual(message.pinExpires, pin.expirationDate)
            XCTAssertEqual(message.pinnedBy?.id, currentUserId)
            XCTAssertNotNil(message.pinnedAt)
        }
    }

    func test_pinMessage_propogatesMessageEditingError_ifLocalStateIsInvalidForPinning() throws {
        let invalidStates: [LocalMessageState] = [
            .deleting,
            .sending,
            .syncing
        ]

        for state in invalidStates {
            let currentUserId: UserId = .unique
            let messageId: MessageId = .unique
            let initialText: String = .unique

            // Flush the database
            try database.removeAllData()

            // Create current user is the database
            try database.createCurrentUser(id: currentUserId)

            // Create a new message in the database
            try database.createMessage(id: messageId, authorId: currentUserId, text: initialText, localState: state)

            let completionError = try waitFor {
                messageUpdater.pinMessage(messageId: messageId, pinning: MessagePinning(expirationDate: .unique), completion: $0)
            }

            // Load the message
            let message = try XCTUnwrap(database.viewContext.message(id: messageId))

            XCTAssertTrue(completionError is ClientError.MessageEditing)
            XCTAssertEqual(message.localMessageState, state)
            XCTAssertEqual(message.text, initialText)
            XCTAssertEqual(message.pinned, false)
            XCTAssertNil(message.pinExpires)
            XCTAssertNil(message.pinnedAt)
            XCTAssertNil(message.pinnedBy)
        }
    }

    func test_unpinMessage_propogates_MessageDoesNotExist_Error() throws {
        try database.createCurrentUser()

        let completionError = try waitFor {
            messageUpdater.unpinMessage(messageId: .unique, completion: $0)
        }

        XCTAssertTrue(completionError is ClientError.MessageDoesNotExist)
    }

    func test_unpinMessage_updatesLocalMessageCorrectly() throws {
        let pairs: [(LocalMessageState?, LocalMessageState?)] = [
            (nil, .pendingSync),
            (.pendingSync, .pendingSync),
            (.pendingSend, .pendingSend)
        ]

        for (initialState, expectedState) in pairs {
            let currentUserId: UserId = .unique
            let messageId: MessageId = .unique

            // Flush the database
            try database.removeAllData()

            // Create current user is the database
            try database.createCurrentUser(id: currentUserId)

            // Create a new message in the database
            try database.createMessage(
                id: messageId,
                authorId: currentUserId,
                pinned: true,
                pinnedByUserId: .unique,
                pinnedAt: .unique,
                pinExpires: .unique,
                localState: initialState
            )

            let completionError = try waitFor {
                messageUpdater.unpinMessage(messageId: messageId, completion: $0)
            }

            // Load the message
            let message = try XCTUnwrap(database.viewContext.message(id: messageId))

            XCTAssertNil(completionError)
            XCTAssertEqual(message.localMessageState, expectedState)
            XCTAssertEqual(message.pinned, false)
            XCTAssertNil(message.pinExpires)
            XCTAssertNil(message.pinnedAt)
            XCTAssertNil(message.pinnedBy)
        }
    }

    func test_unpinMessage_propogatesMessageEditingError_ifLocalStateIsInvalidForUnpinning() throws {
        let invalidStates: [LocalMessageState] = [
            .deleting,
            .sending,
            .syncing
        ]

        for state in invalidStates {
            let currentUserId: UserId = .unique
            let messageId: MessageId = .unique

            // Flush the database
            try database.removeAllData()

            // Create current user is the database
            try database.createCurrentUser(id: currentUserId)

            // Create a new message in the database
            try database.createMessage(
                id: messageId,
                authorId: currentUserId,
                pinned: true,
                pinnedByUserId: .unique,
                pinnedAt: .unique,
                pinExpires: .unique,
                localState: state
            )

            // Edit created message with new text
            let completionError = try waitFor {
                messageUpdater.unpinMessage(messageId: messageId, completion: $0)
            }

            // Load the message
            let message = try XCTUnwrap(database.viewContext.message(id: messageId))

            XCTAssertTrue(completionError is ClientError.MessageEditing)
            XCTAssertEqual(message.localMessageState, state)
            XCTAssertEqual(message.pinned, true)
            XCTAssertNotNil(message.pinExpires)
            XCTAssertNotNil(message.pinnedAt)
            XCTAssertNotNil(message.pinnedBy)
        }
    }

    // MARK: - Restart failed attachment uploading
    
    func test_restartFailedAttachmentUploading_propagatesAttachmentDoesNotExistError() throws {
        let error = try waitFor {
            messageUpdater.restartFailedAttachmentUploading(with: .unique, completion: $0)
        }

        // Assert `ClientError.AttachmentDoesNotExist` is propagated.
        XCTAssertTrue(error is ClientError.AttachmentDoesNotExist)
    }

    func test_restartFailedAttachmentUploading_propagatesAttachmentEditingError() throws {
        let cid: ChannelId = .unique
        let messageId: MessageId = .unique
        let attachmentId: AttachmentId = .init(cid: cid, messageId: messageId, index: 0)

        // Create channel in database.
        try database.createChannel(cid: cid, withMessages: false)
        // Create message in database.
        try database.createMessage(id: messageId, cid: cid)
        // Create attachment in database.
        try database.writeSynchronously {
            try $0.createNewAttachment(
                attachment: .mockFile,
                id: attachmentId
            )
        }

        let rejectedStates: [LocalAttachmentState?] = [
            .pendingUpload,
            .uploading(progress: .random(in: 0...1)),
            .uploaded,
            nil
        ]

        // Iterate through rejected for uploading restart states.
        for state in rejectedStates {
            // Apply rejected state.
            try database.writeSynchronously {
                $0.attachment(id: attachmentId)?.localState = state
            }

            // Try to restart uploading and catch the error.
            let error = try waitFor {
                messageUpdater.restartFailedAttachmentUploading(with: attachmentId, completion: $0)
            }

            // Assert `ClientError.AttachmentEditing` is propagated.
            XCTAssertTrue(error is ClientError.AttachmentEditing)
        }
    }

    func test_restartFailedAttachmentUploading_propagatesDatabaseError() throws {
        let cid: ChannelId = .unique
        let messageId: MessageId = .unique
        let attachmentId: AttachmentId = .init(cid: cid, messageId: messageId, index: 0)

        // Create channel in database.
        try database.createChannel(cid: cid, withMessages: false)
        // Create message in database.
        try database.createMessage(id: messageId, cid: cid)
        // Create attachment in database in `.uploadingFailed` state.
        try database.writeSynchronously {
            let attachmentDTO = try $0.createNewAttachment(
                attachment: .mockFile,
                id: attachmentId
            )
            attachmentDTO.localState = .uploadingFailed
        }

        // Make database throw error on write.
        let databaseError = TestError()
        database.write_errorResponse = databaseError

        // Try to restart uploading and catch the error.
        let error = try waitFor {
            messageUpdater.restartFailedAttachmentUploading(with: attachmentId, completion: $0)
        }

        // Assert database error is propagated.
        XCTAssertEqual(error as? TestError, databaseError)
    }

    func test_restartFailedAttachmentUploading_propagatesNilError() throws {
        let cid: ChannelId = .unique
        let messageId: MessageId = .unique
        let attachmentId: AttachmentId = .init(cid: cid, messageId: messageId, index: 0)

        // Create channel in database.
        try database.createChannel(cid: cid, withMessages: false)
        // Create message in database.
        try database.createMessage(id: messageId, cid: cid)
        // Create attachment in database in `.uploadingFailed` state.
        try database.writeSynchronously {
            let attachmentDTO = try $0.createNewAttachment(
                attachment: .mockFile,
                id: attachmentId
            )
            attachmentDTO.localState = .uploadingFailed
        }

        // Try to restart uploading and catch the error.
        let error = try waitFor {
            messageUpdater.restartFailedAttachmentUploading(with: attachmentId, completion: $0)
        }

        // Assert successful result is propagated.
        XCTAssertNil(error)
    }

    // MARK: - Resend message

    func test_resendMessage_propagatesCurrentUserDoesNotExist_Error() throws {
        // Simulate `resendMessage` call
        let completionError = try waitFor {
            messageUpdater.resendMessage(with: .unique, completion: $0)
        }

        // Assert `CurrentUserDoesNotExist` is received
        XCTAssertTrue(completionError is ClientError.CurrentUserDoesNotExist)
    }

    func test_resendMessage_propagatesMessageDoesNotExist_Error() throws {
        // Create current user is the database
        try database.createCurrentUser()

        // Simulate `resendMessage` call
        let completionError = try waitFor {
            messageUpdater.resendMessage(with: .unique, completion: $0)
        }

        // Assert `MessageDoesNotExist` is received
        XCTAssertTrue(completionError is ClientError.MessageDoesNotExist)
    }

    func test_resendMessage_propagatesMessageEditingError() throws {
        let currentUserId: UserId = .unique
        
        // Create current user is the database
        try database.createCurrentUser(id: currentUserId)
        
        let invalidStates: [LocalMessageState] = [
            .deleting,
            .deletingFailed,
            .pendingSend,
            .sending,
            .pendingSync,
            .syncing,
            .syncingFailed
        ]
        
        for state in invalidStates {
            let messageId: MessageId = .unique
            
            // Create a new message in the database in `sendingFailed` state
            try database.createMessage(id: messageId, authorId: currentUserId, localState: state)
            
            // Try to resend the message
            let completionError = try waitFor {
                messageUpdater.resendMessage(with: messageId, completion: $0)
            }
            
            // Assert `MessageEditing` error is received
            XCTAssertTrue(completionError is ClientError.MessageEditing)
        }
    }

    func test_resendMessage_propagatesDatabaseError() throws {
        let messageId: MessageId = .unique
        let currentUserId: UserId = .unique

        // Create current user is the database
        try database.createCurrentUser(id: currentUserId)
        // Create a new message in the database in `sendingFailed` state
        try database.createMessage(id: messageId, authorId: currentUserId, localState: .sendingFailed)

        // Update database container to throw the error on write
        let databaseError = TestError()
        database.write_errorResponse = databaseError

        // Try to resend the message
        let completionError = try waitFor {
            messageUpdater.resendMessage(with: messageId, completion: $0)
        }

        // Assert database error is propagated
        AssertAsync.willBeEqual(completionError as? TestError, databaseError)
    }

    func test_resendMessage_happyPath() throws {
        let currentUserId: UserId = .unique
        let messageId: MessageId = .unique

        // Create current user is the database
        try database.createCurrentUser(id: currentUserId)

        // Create a new message in the database
        try database.createMessage(id: messageId, authorId: currentUserId, localState: .sendingFailed)

        // Resend failed message
        let completionError = try waitFor {
            messageUpdater.resendMessage(with: messageId, completion: $0)
        }

        // Load the message
        let message = try XCTUnwrap(database.viewContext.message(id: messageId))

        // Assert completion is called without any error
        XCTAssertNil(completionError)
        // Assert message state is changed to `.pendingSend`
        XCTAssertEqual(message.localMessageState, .pendingSend)
    }

    // MARK: - Dispatch ephemeral message action
    
    func test_dispatchEphemeralMessageAction_cancel_happyPath() throws {
        let cid: ChannelId = .unique
        let messageId: MessageId = .unique
        let currentUserId: UserId = .unique

        // Create current user is the database
        try database.createCurrentUser(id: currentUserId)
        // Create channel is the database
        try database.createChannel(cid: cid, withMessages: false)
        // Create a new `ephemeral` message in the database
        try database.createMessage(id: messageId, authorId: currentUserId, type: .ephemeral)

        let cancelAction = AttachmentAction(
            name: .unique,
            value: "cancel",
            style: .default,
            type: .button,
            text: .unique
        )

        // Simulate `dispatchEphemeralMessageAction`
        let completionError = try waitFor {
            messageUpdater.dispatchEphemeralMessageAction(
                cid: cid,
                messageId: messageId,
                action: cancelAction,
                completion: $0
            )
        }

        // Assert error is `nil`
        XCTAssertNil(completionError)
        // Assert `apiClient` is not invoked, message is updated locally.
        XCTAssertNil(apiClient.request_endpoint)

        // Load message
        let message = try XCTUnwrap(database.viewContext.message(id: messageId))

        // Assert message has `deletedAt` field but stays in `ephemeral` state.
        XCTAssertEqual(message.type, MessageType.ephemeral.rawValue)
        XCTAssertNotNil(message.deletedAt)
    }

    func test_dispatchEphemeralMessageAction_happyPath() throws {
        let cid: ChannelId = .unique
        let messageId: MessageId = .unique
        let currentUserId: UserId = .unique

        // Create current user is the database
        try database.createCurrentUser(id: currentUserId)
        // Create channel is the database
        try database.createChannel(cid: cid, withMessages: false)
        // Create a new `ephemeral` message in the database
        try database.createMessage(id: messageId, authorId: currentUserId, type: .ephemeral)

        let action = AttachmentAction(
            name: .unique,
            value: .unique,
            style: .primary,
            type: .button,
            text: .unique
        )

        // Simulate `dispatchEphemeralMessageAction`
        var completionCalledError: Error?
        var completionCalled = false
        messageUpdater.dispatchEphemeralMessageAction(
            cid: cid,
            messageId: messageId,
            action: action
        ) { error in
            completionCalledError = error
            completionCalled = true
        }

        // Assert endpoint is called.
        let endpoint: Endpoint<MessagePayload<ExtraData>.Boxed> = .dispatchEphemeralMessageAction(
            cid: cid,
            messageId: messageId,
            action: action
        )
        AssertAsync.willBeEqual(apiClient.request_endpoint, AnyEndpoint(endpoint))

        // Simulate message response.
        let messagePayload: MessagePayload<ExtraData>.Boxed = .init(
            message: .dummy(
                messageId: messageId,
                authorUserId: currentUserId
            )
        )
        apiClient.test_simulateResponse(.success(messagePayload))

        // Load message
        let message = try XCTUnwrap(database.viewContext.message(id: messageId))

        AssertAsync {
            // Assert completion is called without any error.
            Assert.willBeTrue(completionCalled)
            Assert.staysTrue(completionCalledError == nil)
            // Assert message is updated.
            Assert.willBeEqual(message.type, messagePayload.message.type.rawValue)
            Assert.willBeEqual(message.text, messagePayload.message.text)
        }
    }

    func test_dispatchEphemeralMessageAction_propagatesRequestError() throws {
        let cid: ChannelId = .unique
        let messageId: MessageId = .unique
        let currentUserId: UserId = .unique

        // Create current user is the database
        try database.createCurrentUser(id: currentUserId)
        // Create channel is the database
        try database.createChannel(cid: cid, withMessages: false)
        // Create a new `ephemeral` message in the database
        try database.createMessage(id: messageId, authorId: currentUserId, type: .ephemeral)

        let action = AttachmentAction(
            name: .unique,
            value: .unique,
            style: .primary,
            type: .button,
            text: .unique
        )

        // Simulate `dispatchEphemeralMessageAction`
        var completionCalledError: Error?
        var completionCalled = false
        messageUpdater.dispatchEphemeralMessageAction(
            cid: cid,
            messageId: messageId,
            action: action
        ) { error in
            completionCalledError = error
            completionCalled = true
        }

        // Assert endpoint is called.
        let endpoint: Endpoint<MessagePayload<ExtraData>.Boxed> = .dispatchEphemeralMessageAction(
            cid: cid,
            messageId: messageId,
            action: action
        )
        AssertAsync.willBeEqual(apiClient.request_endpoint, AnyEndpoint(endpoint))

        // Simulate error response.
        let networkError = TestError()
        let result: Result<MessagePayload<ExtraData>.Boxed, Error> = .failure(networkError)
        apiClient.test_simulateResponse(result)

        AssertAsync {
            // Assert completion is called.
            Assert.willBeTrue(completionCalled)
            // Assert networking error is propagated.
            Assert.willBeEqual(completionCalledError as? TestError, networkError)
        }
    }

    func test_dispatchEphemeralMessageAction_propagatesCurrentUserDoesNotExist_Error() throws {
        // Simulate `dispatchEphemeralMessageAction` call
        let completionError = try waitFor {
            messageUpdater.dispatchEphemeralMessageAction(
                cid: .unique,
                messageId: .unique,
                action: .unique,
                completion: $0
            )
        }

        // Assert `CurrentUserDoesNotExist` is received
        XCTAssertTrue(completionError is ClientError.CurrentUserDoesNotExist)
    }

    func test_dispatchEphemeralMessageAction_propagatesMessageDoesNotExist_Error() throws {
        // Create current user is the database
        try database.createCurrentUser()

        // Simulate `dispatchEphemeralMessageAction` call
        let completionError = try waitFor {
            messageUpdater.dispatchEphemeralMessageAction(
                cid: .unique,
                messageId: .unique,
                action: .unique,
                completion: $0
            )
        }

        // Assert `MessageDoesNotExist` is received
        XCTAssertTrue(completionError is ClientError.MessageDoesNotExist)
    }

    func test_dispatchEphemeralMessageAction_propagatesMessageEditingError_forNonEphemeralMessage() throws {
        let cid: ChannelId = .unique
        let currentUserId: UserId = .unique

        // Create current user is the database
        try database.createCurrentUser(id: currentUserId)

        // Create channel is the database
        try database.createChannel(cid: cid, withMessages: false)

        let invalidTypes: [MessageType] = [
            .regular,
            .error,
            .reply,
            .system,
            .deleted
        ]

        for type in invalidTypes {
            let messageId: MessageId = .unique

            // Create a new message in the database with specific type
            try database.createMessage(id: messageId, authorId: currentUserId, type: type)

            // Simulate `dispatchEphemeralMessageAction` call
            let completionError = try waitFor {
                messageUpdater.dispatchEphemeralMessageAction(
                    cid: cid,
                    messageId: messageId,
                    action: .unique,
                    completion: $0
                )
            }

            // Assert `MessageEditing` error is received
            XCTAssertTrue(completionError is ClientError.MessageEditing)
        }
    }

    func test_dispatchEphemeralMessageAction_propagatesDatabaseError_beforeAPICall() throws {
        // Update database container to throw the error on write
        let databaseError = TestError()
        database.write_errorResponse = databaseError

        // Simulate `dispatchEphemeralMessageAction` call
        let completionError = try waitFor {
            messageUpdater.dispatchEphemeralMessageAction(
                cid: .unique,
                messageId: .unique,
                action: .unique,
                completion: $0
            )
        }

        // Assert database error is propagated
        XCTAssertEqual(completionError as? TestError, databaseError)
    }

    func test_dispatchEphemeralMessageAction_propagatesDatabaseError_afterAPICall() throws {
        let cid: ChannelId = .unique
        let messageId: MessageId = .unique
        let currentUserId: UserId = .unique

        // Create current user is the database
        try database.createCurrentUser(id: currentUserId)
        // Create channel is the database
        try database.createChannel(cid: cid, withMessages: false)
        // Create a new `ephemeral` message in the database
        try database.createMessage(id: messageId, authorId: currentUserId, type: .ephemeral)

        let action = AttachmentAction(
            name: .unique,
            value: .unique,
            style: .primary,
            type: .button,
            text: .unique
        )

        // Simulate `dispatchEphemeralMessageAction`
        var completionCalledError: Error?
        messageUpdater.dispatchEphemeralMessageAction(
            cid: cid,
            messageId: messageId,
            action: action
        ) { error in
            completionCalledError = error
        }

        // Assert endpoint is called.
        let endpoint: Endpoint<MessagePayload<ExtraData>.Boxed> = .dispatchEphemeralMessageAction(
            cid: cid,
            messageId: messageId,
            action: action
        )
        AssertAsync.willBeEqual(apiClient.request_endpoint, AnyEndpoint(endpoint))

        // Update database container to throw the error on write
        let databaseError = TestError()
        database.write_errorResponse = databaseError

        // Simulate message response.
        let messagePayload: MessagePayload<ExtraData>.Boxed = .init(
            message: .dummy(
                messageId: messageId,
                authorUserId: currentUserId
            )
        )
        apiClient.test_simulateResponse(.success(messagePayload))

        // Assert database error is propagated.
        AssertAsync.willBeEqual(completionCalledError as? TestError, databaseError)
    }
}
