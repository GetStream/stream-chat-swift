//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

class MessageRepositoryTests: XCTestCase {
    var database: DatabaseContainerMock!
    var apiClient: APIClientMock!
    var repository: MessageRepository!
    var cid: ChannelId!

    override func setUp() {
        let client = ChatClient.mock
        database = client.mockDatabaseContainer
        apiClient = client.mockAPIClient
        repository = MessageRepository(database: database, apiClient: apiClient)
        cid = .unique
    }

    // MARK: sendMessage

    func tests_sendMessage_notExistent() {
        let result = runSendMessageAndWait(id: .unique)
        XCTAssertEqual(result?.error, MessageRepositoryError.messageDoesNotExist)
    }

    func tests_sendMessage_notPendingSent() throws {
        let id = MessageId.unique
        try createMessage(id: id, localState: .deleting)

        let result = runSendMessageAndWait(id: id)
        XCTAssertEqual(result?.error, MessageRepositoryError.messageNotPendingSend)
    }

    func tests_sendMessage_noChannel() throws {
        let id = MessageId.unique
        let message = try createMessage(id: id, localState: .pendingSend)
        try database.writeSynchronously { _ in
            message.channel = nil
        }

        let result = runSendMessageAndWait(id: id)
        XCTAssertEqual(result?.error, MessageRepositoryError.messageDoesNotHaveValidChannel)
    }

    func tests_sendMessage_preAPIRequest() throws {
        let id = MessageId.unique
        try createMessage(id: id, localState: .pendingSend)
        repository.sendMessage(with: id) { _ in }

        wait(for: [apiClient.request_expectation], timeout: 0.1)

        var currentMessageState: LocalMessageState?
        try database.writeSynchronously { session in
            currentMessageState = session.message(id: id)?.localMessageState
        }

        XCTAssertEqual(currentMessageState, .sending)
    }

    func tests_sendMessage_APIFailure() throws {
        let id = MessageId.unique
        try createMessage(id: id, localState: .pendingSend)
        let expectation = self.expectation(description: "Send Message completes")
        var result: Result<ChatMessage, MessageRepositoryError>?
        repository.sendMessage(with: id) {
            result = $0
            expectation.fulfill()
        }

        wait(for: [apiClient.request_expectation], timeout: 0.1)

        let error = NSError(domain: "", code: 1, userInfo: nil)
        (apiClient.request_completion as? (Result<MessagePayload.Boxed, Error>) -> Void)?(.failure(error))

        wait(for: [expectation], timeout: 0.1)

        var currentMessageState: LocalMessageState?
        try database.writeSynchronously { session in
            currentMessageState = session.message(id: id)?.localMessageState
        }

        XCTAssertEqual(currentMessageState, .sendingFailed)
        XCTAssertEqual(result?.error, MessageRepositoryError.failedToSendMessage)
    }

    func tests_sendMessage_APISuccess() throws {
        let id = MessageId.unique
        try createMessage(id: id, localState: .pendingSend)
        let expectation = self.expectation(description: "Send Message completes")
        var result: Result<ChatMessage, MessageRepositoryError>?
        repository.sendMessage(with: id) {
            result = $0
            expectation.fulfill()
        }

        wait(for: [apiClient.request_expectation], timeout: 0.1)

        let payload = MessagePayload.Boxed(message: .dummy(messageId: id, authorUserId: .anonymous))
        (apiClient.request_completion as? (Result<MessagePayload.Boxed, Error>) -> Void)?(.success(payload))

        wait(for: [expectation], timeout: 0.1)

        var currentMessageState: LocalMessageState?
        try database.writeSynchronously { session in
            currentMessageState = session.message(id: id)?.localMessageState
        }

        XCTAssertNil(currentMessageState)
        XCTAssertNotNil(result?.value)
    }

    @discardableResult
    private func createMessage(id: MessageId, localState: LocalMessageState) throws -> MessageDTO {
        try database.createCurrentUser()
        try database.createChannel(cid: cid)
        var message: MessageDTO!
        try database.writeSynchronously { session in
            message = try session.createNewMessage(
                in: self.cid,
                text: "Message pending send",
                pinning: nil,
                quotedMessageId: nil,
                isSilent: false,
                extraData: [:]
            )
            message.id = id
            message.localMessageState = localState
        }
        return message
    }

    private func runSendMessageAndWait(id: MessageId) -> Result<ChatMessage, MessageRepositoryError>? {
        let expectation = self.expectation(description: "Send Message completes")
        var result: Result<ChatMessage, MessageRepositoryError>?
        repository.sendMessage(with: id) {
            result = $0
            expectation.fulfill()
        }
        waitForExpectations(timeout: 0.1, handler: nil)
        return result
    }

    // MARK: saveSuccessfullySentMessage

    func test_saveSuccessfullySentMessage_noChannel() {
        let loggerMock = LoggerMock()
        loggerMock.injectMock()
        let id = MessageId.unique
        let payload = MessagePayload.dummy(messageId: id, authorUserId: .anonymous, channel: nil)
        let message = runSaveSuccessfullySentMessageAndWait(payload: payload)
        XCTAssertNil(message)
        XCTAssertEqual(loggerMock.assertionFailureCalls, 1)
        loggerMock.restoreLogger()
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
        let loggerMock = LoggerMock()
        loggerMock.injectMock()
        let id = MessageId.unique
        let payload = MessagePayload.dummy(messageId: id, authorUserId: .anonymous, channel: nil)

        let message = runSaveSuccessfullySentMessageAndWait(payload: payload)

        // Should not be saved without a channel
        let dbMessage = self.message(for: id)
        XCTAssertNil(message)
        XCTAssertNil(dbMessage)
        XCTAssertEqual(loggerMock.assertionFailureCalls, 1)
        loggerMock.restoreLogger()
    }

    func test_saveSuccessfullySentMessage_channelPayload_newMessageWithChannel() throws {
        let id = MessageId.unique
        let payload = MessagePayload.dummy(messageId: id, authorUserId: .anonymous, channel: .dummy(cid: cid))
        let message = runSaveSuccessfullySentMessageAndWait(payload: payload)
        let dbMessage = self.message(for: id)
        var dbChannel: ChatChannel?
        try database.writeSynchronously { session in
            dbChannel = session.channel(cid: self.cid)?.asModel()
        }
        XCTAssertNotNil(message)
        XCTAssertNil(message?.localState)
        XCTAssertNotNil(dbMessage)
        XCTAssertNotNil(dbChannel)
    }

    private func runSaveSuccessfullySentMessageAndWait(payload: MessagePayload) -> ChatMessage? {
        let expectation = self.expectation(description: "Save Message completes")
        var result: ChatMessage?
        repository.saveSuccessfullySentMessage(cid: cid, message: payload) {
            result = $0
            expectation.fulfill()
        }
        waitForExpectations(timeout: 0.1, handler: nil)
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
        waitForExpectations(timeout: 0.1, handler: nil)

        let dbMessage = message(for: id)
        XCTAssertNotNil(dbMessage)
        XCTAssertNil(dbMessage?.localState)
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
        repository.updateMessage(withID: id, localState: state) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 0.1, handler: nil)
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

    private func runSaveSuccessfullyDeletedMessageAndWait(message: MessagePayload) -> Error? {
        let expectation = self.expectation(description: "Mark Message completes")
        var error: Error?
        repository.saveSuccessfullyDeletedMessage(message: message) {
            error = $0
            expectation.fulfill()
        }
        waitForExpectations(timeout: 0.1, handler: nil)
        return error
    }

    private func message(for id: MessageId) -> ChatMessage? {
        var dbMessage: ChatMessage?
        try? database.writeSynchronously { session in
            dbMessage = session.message(id: id)?.asModel()
        }
        return dbMessage
    }

    // MARK: undoReactionAddition

    func test_undoReactionAddition_nonExistingReaction() {
        let expectation = self.expectation(description: "Undo ReactionCompletes")
        repository.undoReactionAddition(on: "message_id", type: "type") {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 0.1, handler: nil)

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
            try session.saveChannel(payload: .dummy(cid: cid), query: nil)
            try session.saveMessage(payload: .dummy(messageId: messageId, authorUserId: .unique), for: cid, syncOwnReactions: false)
            _ = try session.addReaction(to: messageId, type: reactionType, score: 1, extraData: [:], localState: nil)
        }

        // We undo reaction
        let expectation = self.expectation(description: "Undo ReactionCompletes")
        repository.undoReactionAddition(on: messageId, type: reactionType) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 0.1, handler: nil)

        var reactionState: LocalReactionState?
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
        waitForExpectations(timeout: 0.1, handler: nil)

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
            try session.saveChannel(payload: .dummy(cid: cid), query: nil)
            try session.saveMessage(payload: .dummy(messageId: messageId, authorUserId: .unique), for: cid, syncOwnReactions: false)
        }

        // We undo reaction
        let expectation = self.expectation(description: "Undo ReactionCompletes")
        repository.undoReactionDeletion(on: messageId, type: reactionType, score: 10) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 0.1, handler: nil)

        var reactionState: LocalReactionState?
        var reactionScore: Int64?
        try database.writeSynchronously { session in
            let reaction = session.reaction(messageId: messageId, userId: userId, type: reactionType)
            reactionState = reaction?.localState
            reactionScore = reaction?.score
        }

        // Should update existing local state
        XCTAssertEqual(reactionState, .deletingFailed)
        XCTAssertEqual(reactionScore, 10)
    }
}
