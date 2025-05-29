//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class MessageRepositoryTests: XCTestCase {
    var database: DatabaseContainer_Spy!
    var apiClient: APIClient_Spy!
    var repository: MessageRepository!
    var cid: ChannelId!

    override func setUp() {
        let client = ChatClient.mock
        database = client.mockDatabaseContainer
        apiClient = client.mockAPIClient
        repository = MessageRepository(database: database, apiClient: apiClient)
        cid = .unique
    }

    override func tearDown() {
        super.tearDown()

        database = nil
        apiClient.cleanUp()
        apiClient = nil
        repository = nil
        cid = nil
    }

    // MARK: sendMessage

    func test_sendMessage_notExistent() {
        let result = runSendMessageAndWait(id: .unique)
        XCTAssertEqual(result?.error, MessageRepositoryError.messageDoesNotExist)
    }

    func test_sendMessage_notPendingSent() throws {
        let id = MessageId.unique
        try createMessage(id: id, localState: .deleting)

        let result = runSendMessageAndWait(id: id)
        XCTAssertEqual(result?.error, MessageRepositoryError.messageNotPendingSend)
    }

    func test_sendMessage_noChannel() throws {
        let id = MessageId.unique
        nonisolated(unsafe) let message = try createMessage(id: id, localState: .pendingSend)
        try database.writeSynchronously { _ in
            message.channel = nil
        }

        let result = runSendMessageAndWait(id: id)
        XCTAssertEqual(result?.error, MessageRepositoryError.messageDoesNotHaveValidChannel)
    }

    func test_sendMessage_preAPIRequest() throws {
        let id = MessageId.unique
        try createMessage(id: id, localState: .pendingSend)
        repository.sendMessage(with: id) { _ in }

        wait(for: [apiClient.request_expectation], timeout: defaultTimeout)

        nonisolated(unsafe) var currentMessageState: LocalMessageState?
        try database.writeSynchronously { session in
            currentMessageState = session.message(id: id)?.localMessageState
        }

        XCTAssertEqual(currentMessageState, .sending)
    }

    func test_sendMessage_APIFailure() throws {
        let id = MessageId.unique
        try createMessage(id: id, localState: .pendingSend)
        let expectation = self.expectation(description: "Send Message completes")
        nonisolated(unsafe) var result: Result<ChatMessage, MessageRepositoryError>?
        repository.sendMessage(with: id) {
            result = $0
            expectation.fulfill()
        }

        wait(for: [apiClient.request_expectation], timeout: defaultTimeout)

        let error = NSError(domain: "", code: 1, userInfo: nil)
        (apiClient.request_completion as? (Result<MessagePayload.Boxed, Error>) -> Void)?(.failure(error))

        wait(for: [expectation], timeout: defaultTimeout)

        nonisolated(unsafe) var currentMessageState: LocalMessageState?
        try database.writeSynchronously { session in
            currentMessageState = session.message(id: id)?.localMessageState
        }

        XCTAssertEqual(currentMessageState, .sendingFailed)
        switch result?.error {
        case .failedToSendMessage:
            break
        default:
            XCTFail()
        }
    }

    func test_sendMessage_APIFailure_whenDuplicatedMessage_shouldNotMarkMessageAsFailed() throws {
        let id = MessageId.unique
        try createMessage(id: id, localState: .pendingSend)
        let expectation = self.expectation(description: "Send Message completes")
        nonisolated(unsafe) var result: Result<ChatMessage, MessageRepositoryError>?
        repository.sendMessage(with: id) {
            result = $0
            expectation.fulfill()
        }

        wait(for: [apiClient.request_expectation], timeout: defaultTimeout)

        let error = ClientError(with: ErrorPayload(code: 4, message: "Message X already exists.", statusCode: 400))
        (apiClient.request_completion as? (Result<MessagePayload.Boxed, Error>) -> Void)?(.failure(error))

        wait(for: [expectation], timeout: defaultTimeout)

        nonisolated(unsafe) var currentMessageState: LocalMessageState?
        try database.writeSynchronously { session in
            currentMessageState = session.message(id: id)?.localMessageState
        }

        XCTAssertNil(currentMessageState)
        switch result?.error {
        case .failedToSendMessage:
            break
        default:
            XCTFail()
        }
    }

    func test_sendMessage_APISuccess() throws {
        let id = MessageId.unique
        try createMessage(id: id, localState: .pendingSend)
        let expectation = self.expectation(description: "Send Message completes")
        nonisolated(unsafe) var result: Result<ChatMessage, MessageRepositoryError>?
        repository.sendMessage(with: id) {
            result = $0
            expectation.fulfill()
        }

        wait(for: [apiClient.request_expectation], timeout: defaultTimeout)

        let payload = MessagePayload.Boxed(message: .dummy(messageId: id, authorUserId: .anonymous))
        (apiClient.request_completion as? (Result<MessagePayload.Boxed, Error>) -> Void)?(.success(payload))

        wait(for: [expectation], timeout: defaultTimeout)

        nonisolated(unsafe) var currentMessageState: LocalMessageState?
        try database.writeSynchronously { session in
            currentMessageState = session.message(id: id)?.localMessageState
        }

        XCTAssertNil(currentMessageState)
        XCTAssertNotNil(result?.value)
    }

    func test_sendMessage_skipPush() throws {
        let id = MessageId.unique
        try createMessage(id: id, localState: .pendingSend, skipPush: true)
        let expectation = self.expectation(description: "Send Message completes")
        repository.sendMessage(with: id) { _ in
            expectation.fulfill()
        }

        wait(for: [apiClient.request_expectation], timeout: defaultTimeout)

        let payload = MessagePayload.Boxed(message: .dummy(messageId: id, authorUserId: .anonymous))
        (apiClient.request_completion as? (Result<MessagePayload.Boxed, Error>) -> Void)?(.success(payload))

        wait(for: [expectation], timeout: defaultTimeout)

        let expectedEndpoint = try XCTUnwrap(apiClient.request_endpoint)
        let requestBody = try expectedEndpoint.bodyAsDictionary()
        let skipPush = try XCTUnwrap(requestBody["skip_push"] as? Bool)
        XCTAssertTrue(skipPush)
    }

    func test_sendMessage_skipEnrichUrl() throws {
        let id = MessageId.unique
        try createMessage(id: id, localState: .pendingSend, skipEnrichUrl: true)
        let expectation = self.expectation(description: "Send Message completes")
        repository.sendMessage(with: id) { _ in
            expectation.fulfill()
        }

        wait(for: [apiClient.request_expectation], timeout: defaultTimeout)

        let payload = MessagePayload.Boxed(message: .dummy(messageId: id, authorUserId: .anonymous))
        (apiClient.request_completion as? (Result<MessagePayload.Boxed, Error>) -> Void)?(.success(payload))

        wait(for: [expectation], timeout: defaultTimeout)

        let expectedEndpoint = try XCTUnwrap(apiClient.request_endpoint)
        let requestBody = try expectedEndpoint.bodyAsDictionary()
        let skipPush = try XCTUnwrap(requestBody["skip_enrich_url"] as? Bool)
        XCTAssertTrue(skipPush)
    }

    // MARK: saveSuccessfullySentMessage

    func test_saveSuccessfullySentMessage_noChannel() {
        let Logger_Spy = Logger_Spy()
        Logger_Spy.injectMock()
        let id = MessageId.unique
        let payload = MessagePayload.dummy(messageId: id, authorUserId: .anonymous, channel: nil)
        let message = runSaveSuccessfullySentMessageAndWait(payload: payload)
        XCTAssertNil(message)
        XCTAssertEqual(Logger_Spy.assertionFailureCalls, 1)
        Logger_Spy.restoreLogger()
    }

    func test_saveSuccessfullySentMessage_channelPayload_sending() throws {
        let id = MessageId.unique
        try createMessage(id: id, localState: .sending)
        let payload = MessagePayload.dummy(messageId: id, authorUserId: .anonymous, channel: nil)

        let message = runSaveSuccessfullySentMessageAndWait(payload: payload)
        XCTAssertNotNil(message)
        XCTAssertNil(message?.localState)
    }

    func test_saveSuccessfullySentMessage_channelPayload_sendingFailed() throws {
        let id = MessageId.unique
        try createMessage(id: id, localState: .sendingFailed)
        let payload = MessagePayload.dummy(messageId: id, authorUserId: .anonymous, channel: nil)

        let message = runSaveSuccessfullySentMessageAndWait(payload: payload)
        XCTAssertNotNil(message)
        XCTAssertNil(message?.localState)
    }

    func test_saveSuccessfullySentMessage_channelPayload_deleting() throws {
        let id = MessageId.unique
        try createMessage(id: id, localState: .deleting)
        let payload = MessagePayload.dummy(messageId: id, authorUserId: .anonymous, channel: nil)

        let message = runSaveSuccessfullySentMessageAndWait(payload: payload)
        XCTAssertNotNil(message)
        // Should not update the local state because it is not a successfully sent message
        XCTAssertEqual(message?.localState, .deleting)
    }

    func test_saveSuccessfullySentMessage_channelPayload_newMessageWithoutChannel() throws {
        let Logger_Spy = Logger_Spy()
        Logger_Spy.injectMock()
        let id = MessageId.unique
        let payload = MessagePayload.dummy(messageId: id, authorUserId: .anonymous, channel: nil)

        let message = runSaveSuccessfullySentMessageAndWait(payload: payload)

        // Should not be saved without a channel
        let dbMessage = self.message(for: id)
        XCTAssertNil(message)
        XCTAssertNil(dbMessage)
        XCTAssertEqual(Logger_Spy.assertionFailureCalls, 1)
        Logger_Spy.restoreLogger()
    }

    func test_saveSuccessfullySentMessage_channelPayload_newMessageWithChannel() throws {
        let id = MessageId.unique
        let payload = MessagePayload.dummy(messageId: id, authorUserId: .anonymous, channel: .dummy(cid: cid))
        let message = runSaveSuccessfullySentMessageAndWait(payload: payload)
        let dbMessage = self.message(for: id)
        nonisolated(unsafe) var dbChannel: ChatChannel?
        try database.writeSynchronously { session in
            dbChannel = try session.channel(cid: self.cid)?.asModel()
        }
        XCTAssertNotNil(message)
        XCTAssertNil(message?.localState)
        XCTAssertNotNil(dbMessage)
        XCTAssertNotNil(dbChannel)
    }

    private func runSaveSuccessfullySentMessageAndWait(payload: MessagePayload) -> ChatMessage? {
        let expectation = self.expectation(description: "Save Message completes")
        nonisolated(unsafe) var result: ChatMessage?
        repository.saveSuccessfullySentMessage(cid: cid, message: payload) {
            result = $0.value
            expectation.fulfill()
        }
        waitForExpectations(timeout: defaultTimeout, handler: nil)
        return result
    }

    // MARK: saveSuccessfullyEditedMessage

    func test_saveSuccessfullyEditedMessage() throws {
        let id = MessageId.unique
        try createMessage(id: id, localState: .sending)

        let expectation = self.expectation(description: "saveSuccessfullyEditedMessage completes")
        repository.saveSuccessfullyEditedMessage(for: id) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: defaultTimeout, handler: nil)

        let dbMessage = message(for: id)
        XCTAssertNotNil(dbMessage)
        XCTAssertNil(dbMessage?.localState)
    }

    // MARK: Get message

    func test_getMessage_makesCorrectAPICall() {
        let cid: ChannelId = .unique
        let messageId: MessageId = .unique

        // Simulate `getMessage(cid:, messageId:)` call
        repository.getMessage(cid: cid, messageId: messageId, store: true)

        // Assert correct endpoint is called
        let expectedEndpoint: Endpoint<MessagePayload.Boxed> = .getMessage(messageId: messageId)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }

    func test_getMessage_propogatesRequestError() {
        // Simulate `getMessage(cid:, messageId:)` call
        nonisolated(unsafe) var completionCalledError: Error?
        repository.getMessage(cid: .unique, messageId: .unique, store: true) {
            completionCalledError = $0.error
        }

        // Simulate API response with failure
        let error = TestError()
        apiClient.test_simulateResponse(Result<MessagePayload.Boxed, Error>.failure(error))

        // Assert the completion is called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }

    func test_getMessage_propagatesDatabaseError() throws {
        let messagePayload: MessagePayload.Boxed = .init(
            message: .dummy(messageId: .unique, authorUserId: .unique)
        )
        let channelId = ChannelId.unique

        // Create channel in the database
        try database.createChannel(cid: channelId)

        // Update database container to throw the error on write
        let testError = TestError()
        database.write_errorResponse = testError

        // Simulate `getMessage(cid:, messageId:)` call
        nonisolated(unsafe) var completionCalledError: Error?
        repository.getMessage(cid: channelId, messageId: messagePayload.message.id, store: true) {
            completionCalledError = $0.error
        }

        // Simulate API response with success
        apiClient.test_simulateResponse(Result<MessagePayload.Boxed, Error>.success(messagePayload))

        // Assert database error is propogated
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
    }

    func test_getMessage_savesMessageToDatabase_whenStoreIsTrue() throws {
        let currentUserId: UserId = .unique
        let messageId: MessageId = .unique
        let cid: ChannelId = .unique

        // Create current user in the database
        try database.createCurrentUser(id: currentUserId)

        // Create channel in the database
        try database.createChannel(cid: cid)

        // Simulate `getMessage(cid:, messageId:)` call
        nonisolated(unsafe) var completionCalled = false
        repository.getMessage(cid: cid, messageId: messageId, store: true) { _ in
            completionCalled = true
        }

        // Simulate API response with success
        let messagePayload: MessagePayload.Boxed = .init(
            message: .dummy(messageId: messageId, authorUserId: currentUserId)
        )
        apiClient.test_simulateResponse(Result<MessagePayload.Boxed, Error>.success(messagePayload))

        // Assert completion is called
        AssertAsync.willBeTrue(completionCalled)

        // Assert fetched message is saved to the database
        XCTAssertNotNil(database.viewContext.message(id: messageId))
    }

    func test_getMessage_doesNotSaveMessageToDatabase_whenStoreIsFalse() throws {
        let currentUserId: UserId = .unique
        let messageId: MessageId = .unique
        let cid: ChannelId = .unique

        // Create current user in the database
        try database.createCurrentUser(id: currentUserId)

        // Create channel in the database
        try database.createChannel(cid: cid)

        // Simulate `getMessage(cid:, messageId:)` call
        nonisolated(unsafe) var completionCalled = false
        repository.getMessage(cid: cid, messageId: messageId, store: false) { _ in
            completionCalled = true
        }

        // Simulate API response with success
        let messagePayload: MessagePayload.Boxed = .init(
            message: .dummy(messageId: messageId, authorUserId: currentUserId)
        )
        apiClient.test_simulateResponse(Result<MessagePayload.Boxed, Error>.success(messagePayload))

        // Assert completion is called
        AssertAsync.willBeTrue(completionCalled)

        // Assert fetched message is NOT saved to the database
        XCTAssertNil(database.viewContext.message(id: messageId))
    }
    
    func test_getMessageBefore_returnsCorrectResult() throws {
        let cid = ChannelId.unique
        try database.createCurrentUser()
        try database.writeSynchronously { session in
            let messages = (0..<5).map { index in
                MessagePayload.dummy(
                    messageId: "\(index)",
                    createdAt: Date(timeIntervalSinceReferenceDate: TimeInterval(index))
                )
            }
            try session.saveChannel(
                payload: ChannelPayload.dummy(
                    channel: .dummy(cid: cid),
                    messages: messages
                )
            )
        }
        let result = try waitFor { done in
            repository.getMessage(before: "3", in: cid, completion: done)
        }
        switch result {
        case .success(let messageId):
            XCTAssertEqual("2", messageId)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    // MARK: markMessage

    func test_markMessage_nil() throws {
        let id = MessageId.unique
        try createMessage(id: id, localState: .sending)

        runUpdateMessageLocalStateAndWait(id: id, to: nil)

        let dbMessage = message(for: id)
        XCTAssertNotNil(dbMessage)
        XCTAssertNil(dbMessage?.localState)
    }

    func test_markMessage_deleting() throws {
        let id = MessageId.unique
        try createMessage(id: id, localState: .sending)

        runUpdateMessageLocalStateAndWait(id: id, to: .deleting)

        let dbMessage = message(for: id)
        XCTAssertNotNil(dbMessage)
        XCTAssertEqual(dbMessage?.localState, .deleting)
    }

    private func runUpdateMessageLocalStateAndWait(id: MessageId, to state: LocalMessageState?) {
        let expectation = self.expectation(description: "Mark Message completes")
        repository.updateMessage(withID: id, localState: state) { _ in
            expectation.fulfill()
        }
        waitForExpectations(timeout: defaultTimeout, handler: nil)
    }

    // MARK: saveSuccessfullyDeletedMessage

    func test_saveSuccessfullyDeletedMessage_nonExistingMessage() throws {
        let id = MessageId.unique
        let message = MessagePayload.dummy(messageId: id, authorUserId: .anonymous)
        let error = runSaveSuccessfullyDeletedMessageAndWait(message: message)

        XCTAssertNil(self.message(for: id))
        XCTAssertNil(error)
    }

    func test_saveSuccessfullyDeletedMessage_nonExistingChannel() throws {
        let id = MessageId.unique
        try createMessage(id: id, localState: .deleting)
        try database.writeSynchronously { session in
            let message = session.message(id: id)
            message?.channel = nil
        }

        let message = MessagePayload.dummy(messageId: id, authorUserId: .anonymous)
        let error = runSaveSuccessfullyDeletedMessageAndWait(message: message)

        let dbMessage = self.message(for: id)
        XCTAssertNotNil(dbMessage)
        XCTAssertEqual(dbMessage?.localState, .deleting)
        XCTAssertNil(error)
    }

    func test_saveSuccessfullyDeletedMessage_noHardDelete() throws {
        let id = MessageId.unique
        try createMessage(id: id, localState: .deleting)

        let message = MessagePayload.dummy(messageId: id, authorUserId: .anonymous)
        let error = runSaveSuccessfullyDeletedMessageAndWait(message: message)

        let dbMessage = self.message(for: id)
        XCTAssertNotNil(dbMessage)
        XCTAssertNil(dbMessage?.localState)
        XCTAssertNil(error)
    }

    func test_saveSuccessfullyDeletedMessage_hardDelete() throws {
        let id = MessageId.unique
        try createMessage(id: id, localState: .deleting)
        try database.writeSynchronously { session in
            let message = session.message(id: id)
            message?.isHardDeleted = true
        }

        let message = MessagePayload.dummy(messageId: id, authorUserId: .anonymous)
        let error = runSaveSuccessfullyDeletedMessageAndWait(message: message)

        XCTAssertNil(self.message(for: id))
        XCTAssertNil(error)
    }

    func test_saveSuccessfullyDeletedMessage_hardDelete_shouldDeleteReplies() throws {
        let id = MessageId.unique
        let replyId = MessageId.unique
        try createMessage(id: id, localState: .deleting)
        try database.writeSynchronously { session in
            let message = try XCTUnwrap(session.message(id: id))
            let cid = try XCTUnwrap(message.cid)
            _ = try session.saveMessage(
                payload: .dummy(messageId: replyId, parentId: message.id),
                for: ChannelId(cid: cid),
                syncOwnReactions: false,
                cache: nil
            )
            message.isHardDeleted = true
        }

        let message = MessagePayload.dummy(messageId: id, authorUserId: .anonymous)
        let error = runSaveSuccessfullyDeletedMessageAndWait(message: message)

        XCTAssertNil(self.message(for: id))
        XCTAssertNil(self.message(for: replyId))
        XCTAssertNil(error)
    }

    func test_saveSuccessfullyDeletedMessage_noHardDelete_shouldNotDeleteReplies() throws {
        let id = MessageId.unique
        let replyId = MessageId.unique
        try createMessage(id: id, localState: .deleting)
        try database.writeSynchronously { session in
            let message = try XCTUnwrap(session.message(id: id))
            let cid = try XCTUnwrap(message.cid)
            _ = try session.saveMessage(
                payload: .dummy(messageId: replyId, parentId: message.id),
                for: ChannelId(cid: cid),
                syncOwnReactions: false,
                cache: nil
            )
        }

        let message = MessagePayload.dummy(messageId: id, authorUserId: .anonymous)
        let error = runSaveSuccessfullyDeletedMessageAndWait(message: message)

        XCTAssertNotNil(self.message(for: id))
        XCTAssertNotNil(self.message(for: replyId))
        XCTAssertNil(error)
    }

    private func runSaveSuccessfullyDeletedMessageAndWait(message: MessagePayload) -> Error? {
        let expectation = self.expectation(description: "Mark Message completes")
        nonisolated(unsafe) var error: Error?
        repository.saveSuccessfullyDeletedMessage(message: message) {
            error = $0
            expectation.fulfill()
        }
        waitForExpectations(timeout: defaultTimeout, handler: nil)
        return error
    }

    private func message(for id: MessageId) -> ChatMessage? {
        nonisolated(unsafe) var dbMessage: ChatMessage?
        try? database.writeSynchronously { session in
            dbMessage = try? session.message(id: id)?.asModel()
        }
        return dbMessage
    }

    // MARK: undoReactionAddition

    func test_undoReactionAddition_nonExistingReaction() {
        let expectation = self.expectation(description: "Undo ReactionCompletes")
        repository.undoReactionAddition(on: "message_id", type: "type") {
            expectation.fulfill()
        }
        waitForExpectations(timeout: defaultTimeout, handler: nil)

        // We are making sure the completion is executed even if the reaction is not there
        XCTAssertTrue(true)
    }

    func test_undoReactionAddition_existingReaction() throws {
        let cid = ChannelId(type: .messaging, id: "c")
        let messageId = "message_id"
        let userId = "user_id"
        let reactionType: MessageReactionType = "reaction"

        // We need a user, a channel, a message and an existing reaction
        try database.createCurrentUser(id: userId)
        try database.writeSynchronously { session in
            try session.saveChannel(payload: .dummy(cid: cid), query: nil, cache: nil)
            try session.saveMessage(
                payload: .dummy(messageId: messageId, authorUserId: .unique),
                for: cid,
                syncOwnReactions: false,
                cache: nil
            )
            _ = try session.addReaction(to: messageId, type: reactionType, score: 1, enforceUnique: false, extraData: [:], localState: nil)
        }

        // We undo reaction
        let expectation = self.expectation(description: "Undo ReactionCompletes")
        repository.undoReactionAddition(on: messageId, type: reactionType) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: defaultTimeout, handler: nil)

        nonisolated(unsafe) var reactionState: LocalReactionState?
        try database.writeSynchronously { session in
            let reaction = session.reaction(messageId: messageId, userId: userId, type: reactionType)
            reactionState = reaction?.localState
        }

        // Should update existing local state
        XCTAssertEqual(reactionState, .sendingFailed)
    }

    // MARK: undoReactionDeletion

    func test_undoReactionDeletion_nonExistingMessage() {
        let expectation = self.expectation(description: "Undo ReactionCompletes")
        repository.undoReactionDeletion(on: "message_id", type: "type", score: 10) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: defaultTimeout, handler: nil)

        // We are making sure the completion is executed even if the reaction is not there
        XCTAssertTrue(true)
    }

    func test_undoReactionDeletion_existingMessage() throws {
        let cid = ChannelId(type: .messaging, id: "c")
        let messageId = "message_id"
        let userId = "user_id"
        let reactionType: MessageReactionType = "reaction"

        // We need a user, a channel, a message and an existing reaction
        try database.createCurrentUser(id: userId)
        try database.writeSynchronously { session in
            try session.saveChannel(payload: .dummy(cid: cid), query: nil, cache: nil)
            try session.saveMessage(
                payload: .dummy(messageId: messageId, authorUserId: .unique),
                for: cid,
                syncOwnReactions: false,
                cache: nil
            )
        }

        // We undo reaction
        let expectation = self.expectation(description: "Undo ReactionCompletes")
        repository.undoReactionDeletion(on: messageId, type: reactionType, score: 10) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: defaultTimeout, handler: nil)

        nonisolated(unsafe) var reactionState: LocalReactionState?
        nonisolated(unsafe) var reactionScore: Int64?
        try database.writeSynchronously { session in
            let reaction = session.reaction(messageId: messageId, userId: userId, type: reactionType)
            reactionState = reaction?.localState
            reactionScore = reaction?.score
        }

        // Should update existing local state
        XCTAssertEqual(reactionState, .deletingFailed)
        XCTAssertEqual(reactionScore, 10)
    }

    // MARK: - Interceptor Tests

    final class MockSendMessageInterceptor: SendMessageInterceptor {
        var sendMessageCalled = false
        var receivedMessage: ChatMessage?
        var receivedOptions: SendMessageOptions?
        var completionResult: Result<SendMessageResponse, Error> = .success(.init(message: .mock()))

        func sendMessage(
            _ message: ChatMessage,
            options: SendMessageOptions,
            completion: @escaping ((Result<SendMessageResponse, Error>) -> Void)
        ) {
            sendMessageCalled = true
            receivedMessage = message
            receivedOptions = options
            completion(completionResult)
        }
        
        func simulateSuccess(message: ChatMessage) {
            completionResult = .success(.init(message: message))
        }
        
        func simulateFailure(error: Error) {
            completionResult = .failure(error)
        }
    }

    func test_setInterceptor_storesInterceptor() {
        // Given
        let interceptor = MockSendMessageInterceptor()
        
        // When
        repository.setInterceptor(interceptor)
        
        // Then
        XCTAssertNotNil(repository.interceptor)
    }
    
    func test_sendMessage_withInterceptor_usesInterceptor() throws {
        // Given
        let id = MessageId.unique
        let interceptor = MockSendMessageInterceptor()
        repository.setInterceptor(interceptor)
        try createMessage(id: id, localState: .pendingSend)

        // When
        interceptor.simulateSuccess(message: .mock(id: id))
        let exp = expectation(description: "Send Message completes")
        repository.sendMessage(with: id) { _ in
            exp.fulfill()
        }
        wait(for: [exp], timeout: defaultTimeout)

        // Then
        XCTAssertTrue(interceptor.sendMessageCalled)
        XCTAssertEqual(interceptor.receivedMessage?.id, id)
        XCTAssertFalse(interceptor.receivedOptions?.skipPush ?? true)
        XCTAssertFalse(interceptor.receivedOptions?.skipEnrichUrl ?? true)
        XCTAssertNil(apiClient.request_endpoint) // API client should not be called
    }
    
    func test_sendMessage_withInterceptor_passesSkipOptions() throws {
        // Given
        let id = MessageId.unique
        let interceptor = MockSendMessageInterceptor()
        repository.setInterceptor(interceptor)
        try createMessage(id: id, localState: .pendingSend, skipPush: true, skipEnrichUrl: true)
        
        // When
        interceptor.simulateSuccess(message: .mock(id: id))
        let exp = expectation(description: "Send Message completes")
        repository.sendMessage(with: id) { _ in
            exp.fulfill()
        }
        wait(for: [exp], timeout: defaultTimeout)

        // Then
        XCTAssertTrue(interceptor.sendMessageCalled)
        XCTAssertTrue(interceptor.receivedOptions?.skipPush ?? false)
        XCTAssertTrue(interceptor.receivedOptions?.skipEnrichUrl ?? false)
    }
    
    func test_sendMessage_withInterceptor_whenLocalStatePendingSend_shouldMarkStateSending() throws {
        // Given
        let id = MessageId.unique
        let interceptor = MockSendMessageInterceptor()
        repository.setInterceptor(interceptor)
        try createMessage(id: id, localState: .pendingSend)
        
        // When
        interceptor.simulateSuccess(message: .mock(id: id, localState: .pendingSend))
        let exp = expectation(description: "Send Message completes")
        repository.sendMessage(with: id) { _ in
            exp.fulfill()
        }
        wait(for: [exp], timeout: defaultTimeout)

        // Then
        var messageState: LocalMessageState?
        try database.writeSynchronously { session in
            messageState = session.message(id: id)?.localMessageState
        }
        XCTAssertEqual(messageState, .sending)
    }
    
    func test_sendMessage_withInterceptor_whenLocalStateNil_shouldMarkStatePublished() throws {
        // Given
        let id = MessageId.unique
        let interceptor = MockSendMessageInterceptor()
        repository.setInterceptor(interceptor)
        try createMessage(id: id, localState: .pendingSend)

        // When
        interceptor.simulateSuccess(message: .mock(id: id, localState: nil))
        let exp = expectation(description: "Send Message completes")
        repository.sendMessage(with: id) { _ in
            exp.fulfill()
        }
        wait(for: [exp], timeout: defaultTimeout)

        // Then
        var messageState: LocalMessageState?
        try database.writeSynchronously { session in
            messageState = session.message(id: id)?.localMessageState
        }
        XCTAssertNil(messageState)
    }

    func test_sendMessage_withInterceptor_whenFailure_shouldMarkStateSendingFailed() throws {
        // Given
        let id = MessageId.unique
        let interceptor = MockSendMessageInterceptor()
        repository.setInterceptor(interceptor)
        try createMessage(id: id, localState: .pendingSend)

        // When
        interceptor.simulateFailure(error: TestError())
        let exp = expectation(description: "Send Message completes")
        repository.sendMessage(with: id) { _ in
            exp.fulfill()
        }
        wait(for: [exp], timeout: defaultTimeout)

        // Then
        var messageState: LocalMessageState?
        try database.writeSynchronously { session in
            messageState = session.message(id: id)?.localMessageState
        }
        XCTAssertEqual(messageState, .sendingFailed)
    }
}

extension MessageRepositoryTests {
    @discardableResult
    private func createMessage(
        id: MessageId,
        localState: LocalMessageState,
        skipPush: Bool = false,
        skipEnrichUrl: Bool = false
    ) throws -> MessageDTO {
        try database.createCurrentUser()
        try database.createChannel(cid: cid)
        nonisolated(unsafe) var message: MessageDTO!
        try database.writeSynchronously { session in
            message = try session.createNewMessage(
                in: self.cid,
                messageId: .unique,
                text: "Message pending send",
                pinning: nil,
                quotedMessageId: nil,
                isSilent: false,
                isSystem: false,
                skipPush: skipPush,
                skipEnrichUrl: skipEnrichUrl,
                extraData: [:]
            )
            message.id = id
            message.localMessageState = localState
        }
        return message
    }

    private func runSendMessageAndWait(id: MessageId) -> Result<ChatMessage, MessageRepositoryError>? {
        let expectation = self.expectation(description: "Send Message completes")
        nonisolated(unsafe) var result: Result<ChatMessage, MessageRepositoryError>?
        repository.sendMessage(with: id) {
            result = $0
            expectation.fulfill()
        }
        waitForExpectations(timeout: defaultTimeout, handler: nil)
        return result
    }
}
