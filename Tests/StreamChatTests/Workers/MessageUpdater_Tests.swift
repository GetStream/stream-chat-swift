//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class MessageUpdater_Tests: XCTestCase {
    var webSocketClient: WebSocketClient_Mock!
    var apiClient: APIClient_Spy!
    var database: DatabaseContainer_Spy!
    var messageRepository: MessageRepository_Mock!
    var paginationStateHandler: MessagesPaginationStateHandler_Mock!
    var messageUpdater: MessageUpdater!

    // MARK: Setup

    override func setUp() {
        super.setUp()

        webSocketClient = WebSocketClient_Mock()
        apiClient = APIClient_Spy()
        database = DatabaseContainer_Spy()
        messageRepository = MessageRepository_Mock(database: database, apiClient: apiClient)
        paginationStateHandler = MessagesPaginationStateHandler_Mock()
        messageUpdater = MessageUpdater(
            isLocalStorageEnabled: true,
            messageRepository: messageRepository,
            paginationStateHandler: paginationStateHandler,
            database: database,
            apiClient: apiClient
        )
    }

    override func tearDown() {
        super.tearDown()
        apiClient.cleanUp()
        messageRepository.clear()

        AssertAsync {
            Assert.canBeReleased(&messageRepository)
            Assert.canBeReleased(&messageUpdater)
            Assert.canBeReleased(&webSocketClient)
            Assert.canBeReleased(&apiClient)
            Assert.canBeReleased(&database)
        }
    }

    func recreateUpdater(isLocalStorageEnabled: Bool) {
        messageUpdater = MessageUpdater(
            isLocalStorageEnabled: isLocalStorageEnabled,
            messageRepository: messageRepository,
            paginationStateHandler: paginationStateHandler,
            database: database,
            apiClient: apiClient
        )
    }

    // MARK: Edit message

    func test_editMessage_propagates_CurrentUserDoesNotExist_Error() throws {
        // Simulate `editMessage(messageId:, text:)` call
        let completionError = try waitFor {
            messageUpdater.editMessage(messageId: .unique, text: .unique, skipEnrichUrl: false, completion: $0)
        }

        // Assert `CurrentUserDoesNotExist` is received
        XCTAssertTrue(completionError is ClientError.CurrentUserDoesNotExist)
    }

    func test_editMessage_propagates_MessageDoesNotExist_Error() throws {
        // Create current user is the database
        try database.createCurrentUser()

        // Simulate `editMessage(messageId:, text:)` call
        let completionError = try waitFor {
            messageUpdater.editMessage(messageId: .unique, text: .unique, skipEnrichUrl: false, completion: $0)
        }

        // Assert `MessageDoesNotExist` is received
        XCTAssertTrue(completionError is ClientError.MessageDoesNotExist)
    }

    func test_editMessage_updatesLocalMessageCorrectly() throws {
        let pairs: [(LocalMessageState?, LocalMessageState?)] = [
            (nil, .pendingSync),
            (.pendingSync, .pendingSync),
            (.syncingFailed, .pendingSync),
            (.deletingFailed, .pendingSync),
            (.pendingSend, .pendingSend),
            (.sendingFailed, .pendingSend)
        ]

        for (initialState, expectedState) in pairs {
            let currentUserId: UserId = .unique
            let messageId: MessageId = .unique
            let updatedText: String = .unique

            // Flush the database
            let exp = expectation(description: "removeAllData completion")
            database.removeAllData { error in
                if let error = error {
                    XCTFail("removeAllData failed with \(error)")
                }
                exp.fulfill()
            }
            wait(for: [exp], timeout: defaultTimeout)

            // Create current user is the database
            try database.createCurrentUser(id: currentUserId)

            // Create a new message in the database
            try database.createMessage(
                id: messageId,
                authorId: currentUserId,
                updatedAt: .distantPast,
                localState: initialState
            )

            // Load the message
            let message = try XCTUnwrap(database.viewContext.message(id: messageId))
            let originalMessageUpdatedAt = message.updatedAt

            // Create a new message quoting the message that will be edited
            let quotingMessageId = MessageId.unique
            try database.createMessage(id: quotingMessageId, authorId: currentUserId, quotedMessageId: messageId)

            // Edit created message with new text
            let completionError = try waitFor {
                messageUpdater.editMessage(messageId: messageId, text: updatedText, skipEnrichUrl: true, completion: $0)
            }

            // Load the edited message
            let editedMessage = try XCTUnwrap(database.viewContext.message(id: messageId))

            // Load the message quoting the edited message
            let quotingMessage = try XCTUnwrap(database.viewContext.message(id: quotingMessageId))

            // Assert completion is called without any error
            XCTAssertNil(completionError)
            // Assert message still has expected local state
            XCTAssertEqual(message.localMessageState, expectedState)
            // Assert message text is updated correctly
            XCTAssertEqual(message.text, updatedText)
            // The quoting message should have the same updatedAt so that it triggers a DB Update
            XCTAssertEqual(editedMessage.updatedAt, quotingMessage.updatedAt)
            // The edited message should have a different updatedAt than the original one
            XCTAssertTrue(editedMessage.updatedAt != originalMessageUpdatedAt)
            // The edited message should have the skipEnrichUrl updated.
            XCTAssertEqual(editedMessage.skipEnrichUrl, true)
        }
    }

    func test_editMessage_whenBounced_shouldResendMessage() throws {
        let currentUserId: UserId = .unique
        let messageId: MessageId = .unique
        let updatedText: String = .unique

        // Flush the database
        let exp = expectation(description: "removeAllData completion")
        database.removeAllData { error in
            if let error = error {
                XCTFail("removeAllData failed with \(error)")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: defaultTimeout)

        // Create current user is the database
        try database.createCurrentUser(id: currentUserId)

        // Create a new bounced message in the database
        let channelId = ChannelId.unique
        try database.writeSynchronously { session in
            try session.saveChannel(payload: .dummy(channel: .dummy(cid: channelId)))
            try session.saveMessage(
                payload: .dummy(
                    messageId: messageId,
                    moderationDetails: .init(
                        originalText: "",
                        action: MessageModerationAction.bounce.rawValue
                    )
                ),
                for: channelId,
                syncOwnReactions: false,
                cache: nil
            )
        }

        // Load the message
        let message = try XCTUnwrap(database.viewContext.message(id: messageId))

        // Edit created message with new text
        let completionError = try waitFor {
            messageUpdater.editMessage(messageId: messageId, text: updatedText, skipEnrichUrl: false, completion: $0)
        }

        // Load the edited message
        let editedMessage = try XCTUnwrap(database.viewContext.message(id: messageId))

        // Assert completion is called without any error
        XCTAssertNil(completionError)
        // Assert message still has expected local state
        XCTAssertEqual(message.localMessageState, .pendingSend)
        // Assert message text is updated correctly
        XCTAssertEqual(message.text, updatedText)
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
            let exp = expectation(description: "removeAllData completion")
            database.removeAllData { error in
                if let error = error {
                    XCTFail("removeAllData failed with \(error)")
                }
                exp.fulfill()
            }
            wait(for: [exp], timeout: defaultTimeout)

            // Create current user is the database
            try database.createCurrentUser(id: currentUserId)

            // Create a new message in the database
            try database.createMessage(id: messageId, authorId: currentUserId, text: initialText, localState: state)

            // Edit created message with new text
            let completionError = try waitFor {
                messageUpdater.editMessage(messageId: messageId, text: updatedText, skipEnrichUrl: false, completion: $0)
            }

            // Load the message
            let message = try XCTUnwrap(database.viewContext.message(id: messageId))
            let extraData = try XCTUnwrap(
                message.extraData
                    .map { try? JSONDecoder.default.decode([String: RawJSON].self, from: $0) }
            )

            // Assert `MessageEditing` error is received
            XCTAssertTrue(completionError is ClientError.MessageEditing)
            // Assert message stays in the same state
            XCTAssertEqual(message.localMessageState, state)
            // Assert message's text stays the same
            XCTAssertEqual(message.text, initialText)
            // Assert message's extra data stays the same
            XCTAssertEqual(extraData, [:])
        }
    }

    func test_editMessage_updatesLocalMessageCorrectlyWithExtraData() throws {
        let currentUserId: UserId = .unique
        let messageId: MessageId = .unique
        let updatedText: String = .unique
        let extraData: [String: RawJSON] = ["custom": .number(0)]
        let updatedExtraData: [String: RawJSON] = ["custom": .number(1)]

        // Create current user is the database
        try database.createCurrentUser(id: currentUserId)

        // Create a new message in the database
        try database.createMessage(id: messageId, authorId: currentUserId, extraData: extraData)
        let createdMessage = try XCTUnwrap(database.viewContext.message(id: messageId))

        let encodedCreatedExtraData = try XCTUnwrap(
            createdMessage.extraData
                .map { try? JSONDecoder.default.decode([String: RawJSON].self, from: $0) }
        )
        // Assert message's extra data is updated
        XCTAssertEqual(encodedCreatedExtraData, extraData)

        // Edit created message with new text
        let completionError = try waitFor {
            messageUpdater.editMessage(
                messageId: messageId,
                text: updatedText,
                skipEnrichUrl: false,
                extraData: updatedExtraData,
                completion: $0
            )
        }

        // Load the message
        let message = try XCTUnwrap(database.viewContext.message(id: messageId))
        let encodedExtraData = try XCTUnwrap(
            message.extraData
                .map { try? JSONDecoder.default.decode([String: RawJSON].self, from: $0) }
        )

        // Assert completion is called without any error
        XCTAssertNil(completionError)
        // Assert message's extra data is updated
        XCTAssertEqual(encodedExtraData, updatedExtraData)
    }

    func test_editMessage_doesntUpdatesLocalMessageIfExtraDataAreNil() throws {
        let currentUserId: UserId = .unique
        let messageId: MessageId = .unique
        let updatedText: String = .unique
        let extraData: [String: RawJSON] = ["custom": .number(0)]

        // Create current user is the database
        try database.createCurrentUser(id: currentUserId)

        // Create a new message in the database
        try database.createMessage(id: messageId, authorId: currentUserId, extraData: extraData)
        let createdMessage = try XCTUnwrap(database.viewContext.message(id: messageId))

        let encodedCreatedExtraData = try XCTUnwrap(
            createdMessage.extraData
                .map { try? JSONDecoder.default.decode([String: RawJSON].self, from: $0) }
        )
        // Assert message's extra data is updated
        XCTAssertEqual(encodedCreatedExtraData, extraData)

        // Edit created message with new text
        let completionError = try waitFor {
            messageUpdater.editMessage(
                messageId: messageId,
                text: updatedText,
                skipEnrichUrl: false,
                extraData: nil,
                completion: $0
            )
        }

        // Load the message
        let message = try XCTUnwrap(database.viewContext.message(id: messageId))
        let encodedExtraData = try XCTUnwrap(
            message.extraData
                .map { try? JSONDecoder.default.decode([String: RawJSON].self, from: $0) }
        )

        // Assert completion is called without any error
        XCTAssertNil(completionError)
        // Assert message's extra data is updated
        XCTAssertEqual(encodedExtraData, extraData)
    }

    func test_editMessage_updatesAttachments() throws {
        let currentUserId: UserId = .unique
        let messageId: MessageId = .unique
        let updatedText: String = .unique
        let originalAttachmentTypes: [AttachmentType] = [.audio, .file]
        let updatedAttachmentsTypes: [AttachmentType] = [.voiceRecording, .image]

        // Create current user is the database
        try database.createCurrentUser(id: currentUserId)

        // Create a new message in the database
        try database.createMessage(
            id: messageId,
            authorId: currentUserId,
            attachments: originalAttachmentTypes.map { MessageAttachmentPayload.dummy(type: $0) }
        )
        let createdMessage = try XCTUnwrap(database.viewContext.message(id: messageId))
        let databaseAttachmentTypes = createdMessage.attachments.map(\.attachmentType)

        XCTAssertEqual(databaseAttachmentTypes.sorted { $0.rawValue < $1.rawValue }, originalAttachmentTypes.sorted { $0.rawValue < $1.rawValue })

        // Edit created message with new attaachments
        let completionError = try waitFor {
            messageUpdater.editMessage(
                messageId: messageId,
                text: updatedText,
                skipEnrichUrl: false,
                attachments: updatedAttachmentsTypes.map { AnyAttachmentPayload.mock(type: $0) },
                completion: $0
            )
        }

        // Load the message
        let message = try XCTUnwrap(database.viewContext.message(id: messageId))
        let updatedDatabaseAttachmentTypes = message.attachments.map(\.attachmentType)

        // Assert completion is called without any error
        XCTAssertNil(completionError)
        // Assert message's attachments are updated
        XCTAssertEqual(updatedDatabaseAttachmentTypes.sorted { $0.rawValue < $1.rawValue }, updatedAttachmentsTypes.sorted { $0.rawValue < $1.rawValue })
    }

    // MARK: Delete message

    func test_deleteMessage_sendsCorrectAPICall_ifMessageDoesNotExistLocally() throws {
        let messageId: MessageId = .unique

        // Create current user in the database
        try database.createCurrentUser()

        // Simulate `deleteMessage(messageId:)` call
        messageUpdater.deleteMessage(messageId: messageId, hard: false)

        // Assert correct endpoint is called
        let expectedEndpoint: Endpoint<MessagePayload.Boxed> = .deleteMessage(messageId: messageId, hard: false)
        AssertAsync.willBeEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }

    func test_deleteMessage_propogatesRequestError() throws {
        let messageId: MessageId = .unique

        // Create current user in the database
        try database.createCurrentUser()

        // Simulate `deleteMessage(messageId:)` call
        var completionCalledError: Error?
        messageUpdater.deleteMessage(messageId: messageId, hard: false) {
            completionCalledError = $0
        }

        // Assert correct endpoint is called
        let expectedEndpoint: Endpoint<MessagePayload.Boxed> = .deleteMessage(messageId: messageId, hard: false)
        AssertAsync.willBeEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))

        // Simulate API response with error
        let testError = TestError()
        let response: Result<MessagePayload.Boxed, Error> = .failure(testError)
        apiClient.test_simulateResponse(response)

        // Assert completion is called without any error
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
    }

    func test_deleteMessage_propogatesDatabaseError_beforeAPICall() throws {
        // Update database container to throw the error on write
        let databaseError = TestError()
        database.write_errorResponse = databaseError

        // Simulate `deleteMessage(messageId:)` call
        let completionError = try waitFor {
            messageUpdater.deleteMessage(messageId: .unique, hard: false, completion: $0)
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
        let expectation = self.expectation(description: "Delete message completion")
        messageUpdater.deleteMessage(messageId: messageId, hard: false) {
            completionCalledError = $0
            expectation.fulfill()
        }

        // Assert correct endpoint is called
        let expectedEndpoint: Endpoint<MessagePayload.Boxed> = .deleteMessage(messageId: messageId, hard: false)
        AssertAsync.willBeEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))

        // Update database container to throw the error on write
        let databaseError = TestError()
        messageRepository.saveSuccessfullyDeletedMessageError = databaseError

        // Simulate API response with success
        let response: Result<MessagePayload.Boxed, Error> =
            .success(.init(message: .dummy(messageId: .unique, authorUserId: .unique)))
        apiClient.test_simulateResponse(response)

        waitForExpectations(timeout: defaultTimeout, handler: nil)
        // Assert database error is propogated
        XCTAssertEqual(completionCalledError as? TestError, databaseError)
    }

    func test_deleteMessage_whenIsLocalOnly_shouldNotCallAPI_shouldHardDelete() throws {
        recreateUpdater(isLocalStorageEnabled: true)

        let currentUserId: UserId = .unique
        let messageId: MessageId = .unique

        // Flush the database
        let exp = expectation(description: "removeAllData completion")
        database.removeAllData { error in
            if let error = error {
                XCTFail("removeAllData failed with \(error)")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: defaultTimeout)

        // Create current user in the database
        try database.createCurrentUser(id: currentUserId)

        // Create a new message in the database
        try database.createMessage(id: messageId, authorId: currentUserId, type: .ephemeral)

        let expectation = expectation(description: "deleteMessage")

        // Simulate `deleteMessage(messageId:)` call
        messageUpdater.deleteMessage(messageId: messageId, hard: false) { error in
            XCTAssertNil(error)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: defaultTimeout)
        let message = try XCTUnwrap(database.viewContext.message(id: messageId))

        XCTAssertNotNil(message.deletedAt)
        XCTAssertEqual(message.type, MessageType.deleted.rawValue)
        XCTAssertEqual(message.isHardDeleted, true)
        XCTAssertNil(apiClient.request_endpoint)
    }

    func test_deleteMessage_updatesMessageStateCorrectly() throws {
        let currentUserId: UserId = .unique
        let messageId: MessageId = .unique

        let pairs: [(Result<MessagePayload.Boxed, Error>, LocalMessageState?)] = [
            (.success(.init(message: .dummy(messageId: messageId, authorUserId: currentUserId))), nil),
            (.failure(TestError()), .deletingFailed)
        ]

        for (networkResult, expectedState) in pairs {
            messageRepository.clear()

            // Flush the database
            let exp = expectation(description: "removeAllData completion")
            database.removeAllData { error in
                if let error = error {
                    XCTFail("removeAllData failed with \(error)")
                }
                exp.fulfill()
            }
            wait(for: [exp], timeout: defaultTimeout)

            // Create current user in the database
            try database.createCurrentUser(id: currentUserId)

            // Create message authored by current user in the database
            try database.createMessage(id: messageId, authorId: currentUserId)

            // Simulate `deleteMessage(messageId:)` call
            messageUpdater.deleteMessage(messageId: messageId, hard: false)

            // Load the message
            let message = try XCTUnwrap(database.viewContext.message(id: messageId))

            // Assert message's local state becomes `deleting`
            AssertAsync.willBeEqual(message.localMessageState, .deleting)

            // Simulate API response
            apiClient.test_simulateResponse(networkResult)

            // Assert message's local state becomes expected
            if expectedState == nil {
                XCTAssertCall("saveSuccessfullyDeletedMessage(message:completion:)", on: messageRepository, times: 1)
            } else {
                XCTAssertNotCall("saveSuccessfullyDeletedMessage(message:completion:)", on: messageRepository)
            }
        }
    }

    func test_deleteMessage_whenHardDelete_whenSuccess_removesFromDatabase() throws {
        let currentUserId: UserId = .unique
        let messageId: MessageId = .unique

        // Flush the database
        let exp = expectation(description: "removeAllData completion")
        database.removeAllData { error in
            if let error = error {
                XCTFail("removeAllData failed with \(error)")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: defaultTimeout)

        // Create current user in the database
        try database.createCurrentUser(id: currentUserId)

        // Create message authored by current user in the database
        try database.createMessage(id: messageId, authorId: currentUserId)

        // Simulate `deleteMessage(messageId:)` call
        messageUpdater.deleteMessage(messageId: messageId, hard: true)

        // Load the message
        let message = try XCTUnwrap(database.viewContext.message(id: messageId))

        // Assert message's local state becomes `deleting`
        AssertAsync.willBeEqual(message.localMessageState, .deleting)

        // The message is marked has being hard deleted
        XCTAssertEqual(message.isHardDeleted, true)

        // Simulate API response
        let networkResult: Result<MessagePayload.Boxed, Error> = .success(
            .init(message: .dummy(messageId: messageId, authorUserId: currentUserId))
        )
        apiClient.test_simulateResponse(networkResult)

        // Message will be marked for delete
        XCTAssertCall("saveSuccessfullyDeletedMessage(message:completion:)", on: messageRepository, times: 1)
    }

    func test_deleteMessage_whenHardDelete_whenFailure_resetsIsHardDelete() throws {
        let currentUserId: UserId = .unique
        let messageId: MessageId = .unique

        // Flush the database
        let exp = expectation(description: "removeAllData completion")
        database.removeAllData { error in
            if let error = error {
                XCTFail("removeAllData failed with \(error)")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: defaultTimeout)

        // Create current user in the database
        try database.createCurrentUser(id: currentUserId)

        // Create message authored by current user in the database
        try database.createMessage(id: messageId, authorId: currentUserId)

        // Simulate `deleteMessage(messageId:)` call
        messageUpdater.deleteMessage(messageId: messageId, hard: true)

        // Load the message
        let message = try XCTUnwrap(database.viewContext.message(id: messageId))

        // Assert message's local state becomes `deleting`
        AssertAsync.willBeEqual(message.localMessageState, .deleting)

        // The message is marked has being hard deleted
        XCTAssertEqual(message.isHardDeleted, true)

        // Simulate API response
        let networkResult: Result<MessagePayload.Boxed, Error> = .failure(TestError())
        apiClient.test_simulateResponse(networkResult)

        // Local message state is set to deleting failed
        AssertAsync.willBeEqual(message.localMessageState, .deletingFailed)

        // isHardDelete state is reset
        let messageAfterHardDelete = database.viewContext.message(id: messageId)
        XCTAssertEqual(messageAfterHardDelete?.isHardDeleted, false)
    }

    func test_deleteBouncedMessage_isDeletedLocally_whenLocalStateIsSendingFailed() throws {
        let currentUserId: UserId = .unique
        let messageId: MessageId = .unique

        // Flush the database
        let exp = expectation(description: "removeAllData completion")
        database.removeAllData { error in
            if let error = error {
                XCTFail("removeAllData failed with \(error)")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: defaultTimeout)

        // Create current user in the database
        try database.createCurrentUser(id: currentUserId)

        // Create message authored by current user in the database
        try database.createMessage(id: messageId, authorId: currentUserId)

        // Simulate message on a state where it failed to be sent due to moderation
        try database.writeSynchronously { session in
            guard let messageDTO = session.message(id: messageId) else { return }

            messageDTO.moderationDetails = MessageModerationDetailsDTO.create(
                from: .init(originalText: "", action: MessageModerationAction.bounce.rawValue),
                context: self.database.writableContext
            )
            messageDTO.localMessageState = .sendingFailed
        }

        // Simulate `deleteMessage(messageId:)` call
        messageUpdater.deleteMessage(messageId: messageId, hard: false)

        // Load the message
        let message = try XCTUnwrap(database.viewContext.message(id: messageId))

        // Assert Bounced Message Gets locally deleted
        AssertAsync.willBeEqual(message.type, MessageType.deleted.rawValue)

        // The message is marked has being hard deleted
        XCTAssertEqual(message.isHardDeleted, true)
    }

    func test_deleteBouncedMessage_isNotDeletedLocally_whenLocalStateIsNotSendingFailed() throws {
        let currentUserId: UserId = .unique
        let messageId: MessageId = .unique

        // Flush the database
        let exp = expectation(description: "removeAllData completion")
        database.removeAllData { error in
            if let error = error {
                XCTFail("removeAllData failed with \(error)")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: defaultTimeout)

        // Create current user in the database
        try database.createCurrentUser(id: currentUserId)

        // Create message authored by current user in the database
        try database.createMessage(id: messageId, authorId: currentUserId)

        // Simulate message on a state where it failed to be sent due to moderation
        try database.writeSynchronously { session in
            guard let messageDTO = session.message(id: messageId) else { return }

            messageDTO.moderationDetails = MessageModerationDetailsDTO.create(
                from: .init(originalText: "", action: MessageModerationAction.bounce.rawValue),
                context: self.database.writableContext
            )
        }

        // Simulate `deleteMessage(messageId:)` call
        messageUpdater.deleteMessage(messageId: messageId, hard: false)

        // Load the message
        let message = try XCTUnwrap(database.viewContext.message(id: messageId))

        // Assert Bounced Message Does not get deleted locally
        AssertAsync.willBeEqual(message.type, MessageType.regular.rawValue)
    }

    func test_deleteBouncedMessage_updatesChannelPreviewCorrectly() throws {
        let firstMessageId: MessageId = .unique
        let secondMessageId: MessageId = .unique
        let cid: ChannelId = .unique
        let emptyChannelPayload: ChannelPayload = .dummy(channel: .dummy(cid: cid))

        // Flush the database
        let exp = expectation(description: "removeAllData completion")
        database.removeAllData { error in
            if let error = error {
                XCTFail("removeAllData failed with \(error)")
            }
            exp.fulfill()
        }
        waitForExpectations(timeout: defaultTimeout)

        let firstPreviewMessage: MessagePayload = .dummy(
            type: .regular,
            messageId: firstMessageId,
            authorUserId: .unique
        )

        let secondPreviewMessage: MessagePayload = .dummy(
            type: .regular,
            messageId: secondMessageId,
            authorUserId: .unique
        )

        let channelPayload: ChannelPayload = .dummy(
            channel: emptyChannelPayload.channel,
            messages: [firstPreviewMessage, secondPreviewMessage]
        )

        // Save channel information to database and mark message as failedToBeSentDueToModeration
        try database.writeSynchronously { session in
            try session.saveChannel(payload: channelPayload)

            guard let messageDTO = session.message(id: secondMessageId) else { return }

            messageDTO.moderationDetails = MessageModerationDetailsDTO.create(
                from: .init(originalText: "", action: MessageModerationAction.bounce.rawValue),
                context: self.database.writableContext
            )
            messageDTO.localMessageState = .sendingFailed
        }

        // Load the message
        let message = try XCTUnwrap(database.viewContext.message(id: secondMessageId))

        // Delete second message
        let expectation = expectation(description: "deleteMessage completes")
        messageUpdater.deleteMessage(messageId: secondMessageId, hard: false) { _ in
            expectation.fulfill()
        }

        waitForExpectations(timeout: defaultTimeout)
        let channelDTO = try XCTUnwrap(database.viewContext.channel(cid: cid))

        // Assert channel preview is updated with the previous message
        XCTAssertEqual(channelDTO.previewMessage?.id, firstPreviewMessage.id)
    }

    // MARK: Get message

    func test_getMessage_shouldForwardSuccess() {
        let cid: ChannelId = .unique
        let messageId: MessageId = .unique
        let message = ChatMessage.unique

        messageRepository.getMessageResult = .success(message)
        // Simulate `getMessage(cid:, messageId:)` call
        var result: Result<ChatMessage, Error>!
        let expectation = self.expectation(description: "getMessage completes")
        messageUpdater.getMessage(cid: cid, messageId: messageId) {
            result = $0
            expectation.fulfill()
        }

        waitForExpectations(timeout: defaultTimeout)
        XCTAssertEqual(result.value, message)
    }

    func test_getMessage_shouldForwardError() {
        let cid: ChannelId = .unique
        let messageId: MessageId = .unique
        let error = ClientError.ConnectionError()

        messageRepository.getMessageResult = .failure(error)
        // Simulate `getMessage(cid:, messageId:)` call
        var result: Result<ChatMessage, Error>!
        let expectation = self.expectation(description: "getMessage completes")
        messageUpdater.getMessage(cid: cid, messageId: messageId) {
            result = $0
            expectation.fulfill()
        }

        waitForExpectations(timeout: defaultTimeout)
        XCTAssertEqual(result.error, error)
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
        let isSilent = false
        let command: String = .unique
        let arguments: String = .unique
        let extraData: [String: RawJSON] = [:]

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
        let newMessage: ChatMessage = try waitFor { completion in
            messageUpdater.createNewReply(
                in: cid,
                messageId: .unique,
                text: text,
                pinning: MessagePinning(expirationDate: .unique),
                command: command,
                arguments: arguments,
                parentMessageId: parentMessageId,
                attachments: attachmentEnvelopes,
                mentionedUserIds: mentionedUserIds,
                showReplyInChannel: showReplyInChannel,
                isSilent: isSilent,
                quotedMessageId: nil,
                skipPush: true,
                skipEnrichUrl: false,
                extraData: extraData
            ) { result in
                if let newMessage = try? result.get() {
                    completion(newMessage)
                } else {
                    XCTFail("Saving the message failed.")
                }
            }
        }

        func id(for envelope: AnyAttachmentPayload) -> AttachmentId {
            .init(cid: cid, messageId: newMessage.id, index: attachmentEnvelopes.firstIndex(of: envelope)!)
        }

        let messageDTO: MessageDTO = try XCTUnwrap(database.viewContext.message(id: newMessage.id))
        XCTAssertEqual(messageDTO.skipPush, true)
        XCTAssertEqual(messageDTO.skipEnrichUrl, false)
        XCTAssertEqual(messageDTO.showInsideThread, true)
        XCTAssertEqual(messageDTO.mentionedUserIds, [currentUserId])

        let message: ChatMessage = try messageDTO.asModel()
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
        XCTAssertEqual(message.extraData, [:])
        XCTAssertEqual(message.localState, .pendingSend)
        XCTAssertTrue(message.isPinned)
        XCTAssertEqual(message.isSilent, isSilent)
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

        let result: Result<ChatMessage, Error> = try waitFor { completion in
            messageUpdater.createNewReply(
                in: .unique,
                messageId: .unique,
                text: .unique,
                pinning: nil,
                command: .unique,
                arguments: .unique,
                parentMessageId: .unique,
                attachments: [],
                mentionedUserIds: [.unique],
                showReplyInChannel: false,
                isSilent: false,
                quotedMessageId: nil,
                skipPush: false,
                skipEnrichUrl: false,
                extraData: [:]
            ) { completion($0) }
        }

        AssertResultFailure(result, testError)
    }

    // MARK: Load replies

    func test_loadReplies_makesCorrectAPICall() {
        let repliesPayload: MessageRepliesPayload = .init(messages: [
            .dummy(messageId: .unique, authorUserId: .unique)
        ])
        let messageId: MessageId = .unique
        let pagination: MessagesPagination = .init(pageSize: 25)

        // Simulate `loadReplies` call
        let exp = expectation(description: "load replies should complete")
        messageUpdater.loadReplies(cid: .unique, messageId: messageId, pagination: pagination) { _ in
            exp.fulfill()
        }

        XCTAssertEqual(paginationStateHandler.beginCallCount, 1)
        XCTAssertEqual(paginationStateHandler.beginCalledWith, pagination)
        XCTAssertEqual(paginationStateHandler.endCallCount, 0)

        // Assert correct endpoint is called
        let expectedEndpoint: Endpoint<MessageRepliesPayload> = .loadReplies(
            messageId: messageId,
            pagination: pagination
        )
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))

        // Simulate API response with success
        apiClient.test_simulateResponse(Result<MessageRepliesPayload, Error>.success(repliesPayload))

        waitForExpectations(timeout: defaultTimeout)

        XCTAssertEqual(paginationStateHandler.endCallCount, 1)
        XCTAssertEqual(paginationStateHandler.endCalledWith?.0, pagination)
        XCTAssertEqual(paginationStateHandler.endCalledWith?.1.value?.count, repliesPayload.messages.count)
    }

    func test_loadReplies_propagatesRequestError() {
        // Simulate `loadReplies` call
        var completionCalledError: Error?
        messageUpdater.loadReplies(cid: .unique, messageId: .unique, pagination: .init(pageSize: 25)) {
            completionCalledError = $0.error
        }

        // Simulate API response with failure
        let error = TestError()
        apiClient.test_simulateResponse(Result<MessageRepliesPayload, Error>.failure(error))

        // Assert the completion is called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }

    func test_loadReplies_propagatesDatabaseError() throws {
        let repliesPayload: MessageRepliesPayload = .init(messages: [
            .dummy(messageId: .unique, authorUserId: .unique)
        ])
        let cid = ChannelId.unique

        // Create channel in the database
        try database.createChannel(cid: cid)

        // Update database container to throw the error on write
        let testError = TestError()
        database.write_errorResponse = testError

        // Simulate `loadReplies` call
        var completionCalledError: Error?
        messageUpdater.loadReplies(cid: cid, messageId: .unique, pagination: .init(pageSize: 25)) {
            completionCalledError = $0.error
        }

        // Simulate API response with success
        apiClient.test_simulateResponse(Result<MessageRepliesPayload, Error>.success(repliesPayload))

        // Assert database error is propagated
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
    }

    func test_loadReplies_savesMessagesToDatabase_savedMessagesShouldAppearInsideThread() throws {
        let currentUserId: UserId = .unique
        let messageIds: [MessageId] = [.unique, .unique, .unique]
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
        let repliesPayload: MessageRepliesPayload = .init(
            messages: messageIds.map { .dummy(messageId: $0, authorUserId: .unique) }
        )
        apiClient.test_simulateResponse(Result<MessageRepliesPayload, Error>.success(repliesPayload))

        // Assert completion is called
        AssertAsync.willBeTrue(completionCalled)

        // Assert fetched message is saved to the database
        let messageDTOs = messageIds.compactMap { database.viewContext.message(id: $0) }
        XCTAssertEqual(messageDTOs.count, 3)
        XCTAssertEqual(messageDTOs.map(\.showInsideThread), [true, true, true])
    }

    func test_loadReplies_shouldSetNewestReplyAt() throws {
        let pagination = MessagesPagination(pageSize: 3, parameter: .around(.unique))
        let expectedNewestReplyAt = Date.unique
        let repliesPayload: MessageRepliesPayload = .init(
            messages: [
                .dummy(),
                .dummy(),
                .dummy()
            ]
        )

        paginationStateHandler.mockState.newestFetchedMessage = .dummy(createdAt: expectedNewestReplyAt)

        try AssertLoadReplies(expectedNewestReplyAt: expectedNewestReplyAt, for: repliesPayload, with: pagination)
    }

    func test_loadReplies_whenNewestFetchedMessageIsNil_shouldSetNewestReplyAtToNil() throws {
        let pagination = MessagesPagination(pageSize: 3, parameter: nil)
        let repliesPayload: MessageRepliesPayload = .init(
            messages: [
                .dummy(),
                .dummy(),
                .dummy()
            ]
        )

        paginationStateHandler.mockState.newestFetchedMessage = nil

        try AssertLoadReplies(expectedNewestReplyAt: nil, for: repliesPayload, with: pagination)
    }

    func test_loadReplies_whenIsFirstPage_shouldClearCurrentMessagesExcludingLocalOnly() throws {
        let firstPage = MessagesPagination(pageSize: 25, parameter: nil)
        try AssertLoadReplies(shouldClearCurrentMessagesExcludingLocalOnly: true, for: firstPage)
    }

    func test_loadReplies_whenIsJumpingToMessage_shouldClearCurrentMessagesExcludingLocalOnly() throws {
        let midPage = MessagesPagination(pageSize: 25, parameter: .around(.unique))
        try AssertLoadReplies(shouldClearCurrentMessagesExcludingLocalOnly: true, for: midPage)
    }

    func test_loadReplies_whenIsLoadingPreviousMessages_shouldNotClearCurrentMessages() throws {
        let previousPage = MessagesPagination(pageSize: 25, parameter: .lessThan(.unique))
        try AssertLoadReplies(shouldClearCurrentMessagesExcludingLocalOnly: false, for: previousPage)
    }

    // MARK: - Load reactions

    func test_loadReactions_makesCorrectAPICall() {
        let messageId: MessageId = .unique
        let pagination: Pagination = .init(pageSize: 25)

        messageUpdater.loadReactions(cid: .unique, messageId: messageId, pagination: pagination)

        let expectedEndpoint: Endpoint<MessageReactionsPayload> = .loadReactions(
            messageId: messageId,
            pagination: pagination
        )
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }

    func test_loadReactions_propagatesRequestError() {
        var completionCalledError: Error?
        messageUpdater.loadReactions(cid: .unique, messageId: .unique, pagination: .init(pageSize: 25)) {
            completionCalledError = $0.error
        }

        let error = TestError()
        apiClient.test_simulateResponse(Result<MessageReactionsPayload, Error>.failure(error))

        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }

    func test_loadReactions_propagatesDatabaseError() throws {
        let reactionsPayload: MessageReactionsPayload = .init(
            reactions: [
                .dummy(messageId: .unique, user: .dummy(userId: .unique)),
                .dummy(messageId: .unique, user: .dummy(userId: .unique))
            ]
        )

        // Create channel in the database
        let cid = ChannelId.unique
        try database.createChannel(cid: cid)

        // Update database container to throw the error on write
        let testError = TestError()
        database.write_errorResponse = testError

        var completionCalledError: Error?
        messageUpdater.loadReactions(cid: cid, messageId: .unique, pagination: .init(pageSize: 25)) {
            completionCalledError = $0.error
        }

        // Simulate API response with success
        apiClient.test_simulateResponse(Result<MessageReactionsPayload, Error>.success(reactionsPayload))

        // Assert database error is propagated
        AssertAsync.willBeEqual(completionCalledError as? TestError, testError)
    }

    func test_loadReactions_savesReactionsToDatabase_andCallsCompletionWithReactions() throws {
        let currentUserId: UserId = .unique
        let messageId: MessageId = .unique
        let cid: ChannelId = .unique

        // Create current user in the database
        try database.createCurrentUser(id: currentUserId)

        // Create channel in the database
        try database.createChannel(cid: cid)

        // Create message in the database
        try database.createMessage(id: messageId)

        let reactionsPayload: MessageReactionsPayload = .init(
            reactions: [
                .dummy(type: "like", messageId: messageId, user: .dummy(userId: currentUserId)),
                .dummy(type: "dislike", messageId: messageId, user: .dummy(userId: currentUserId))
            ]
        )

        var completionCalled = false
        messageUpdater.loadReactions(cid: cid, messageId: messageId, pagination: .init(pageSize: 25)) { result in
            XCTAssertEqual(try? result.get().count, reactionsPayload.reactions.count)
            completionCalled = true
        }

        // Simulate API response with success
        apiClient.test_simulateResponse(Result<MessageReactionsPayload, Error>.success(reactionsPayload))

        AssertAsync.willBeTrue(completionCalled)
        XCTAssertNotNil(database.viewContext.reaction(messageId: messageId, userId: currentUserId, type: "like"))
        XCTAssertNotNil(database.viewContext.reaction(messageId: messageId, userId: currentUserId, type: "dislike"))
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

        // Simulate message response with success.
        messageRepository.getMessageResult = .success(.mock(id: messageId, cid: cid, text: "", author: .mock(id: currentUserId)))

        // Simulate `flagMessage` call.
        let expectation = self.expectation(description: "Flag message completion")
        messageUpdater.flagMessage(true, with: messageId, in: cid) { error in
            XCTAssertNil(error)
            expectation.fulfill()
        }

        // Assert flag endpoint is called.
        let flagEndpoint: Endpoint<FlagMessagePayload> = .flagMessage(true, with: messageId)
        AssertAsync.willBeEqual(apiClient.request_endpoint, AnyEndpoint(flagEndpoint))

        // Add it to DB as it is as expected after a successful getMessage call
        try database.writeSynchronously { session in
            try session.saveMessage(
                payload: MessagePayload.dummy(messageId: messageId, authorUserId: currentUserId),
                for: cid,
                syncOwnReactions: true,
                cache: nil
            )
        }

        // Simulate flag API response.
        let flagMessagePayload = FlagMessagePayload(
            currentUser: .dummy(userId: currentUserId, role: .user),
            flaggedMessageId: messageId
        )
        apiClient.test_simulateResponse(.success(flagMessagePayload))

        waitForExpectations(timeout: defaultTimeout)

        // Load the message.
        var messageDTO: MessageDTO? {
            database.viewContext.message(id: messageId)
        }

        AssertAsync {
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
        let unflagEndpoint: Endpoint<FlagMessagePayload> = .flagMessage(false, with: messageId)
        AssertAsync.willBeEqual(apiClient.request_endpoint, AnyEndpoint(unflagEndpoint))

        // Simulate unflag API response.
        apiClient.test_simulateResponse(.success(flagMessagePayload))

        // Assert unflag completion is called.
        AssertAsync.willBeTrue(unflagCompletionCalled)

        AssertAsync {
            // Assert current user doesn't have the message as flagged.
            Assert.willBeFalse(messageDTO.flatMap { currentUserDTO.flaggedMessages.contains($0) } ?? true)
            // Assert message is not flagged by current user anymore.
            Assert.willBeEqual(messageDTO?.flaggedBy, nil)
        }
    }

    func test_flagMessage_propagatesError() {
        let messageId: MessageId = .unique
        let cid: ChannelId = .unique

        let networkError = TestError()
        messageRepository.getMessageResult = .failure(networkError)

        // Simulate `flagMessage` call and catch the error.
        var completionCalledError: Error?
        messageUpdater.flagMessage(true, with: messageId, in: cid) {
            completionCalledError = $0
        }

        // Assert the message network error is propogated.
        AssertAsync.willBeEqual(completionCalledError as? TestError, networkError)
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
        let flagEndpoint: Endpoint<FlagMessagePayload> = .flagMessage(true, with: messageId)
        AssertAsync.willBeEqual(apiClient.request_endpoint, AnyEndpoint(flagEndpoint))

        // Simulate flag API response with failure.
        let networkError = TestError()
        apiClient.test_simulateResponse(Result<FlagMessagePayload, Error>.failure(networkError))

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
        let flagEndpoint: Endpoint<FlagMessagePayload> = .flagMessage(true, with: messageId)
        AssertAsync.willBeEqual(apiClient.request_endpoint, AnyEndpoint(flagEndpoint))

        // Simulate flag API response with success.
        let payload = FlagMessagePayload(
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
        let flagEndpoint: Endpoint<FlagMessagePayload> = .flagMessage(true, with: messageId)
        AssertAsync.willBeEqual(apiClient.request_endpoint, AnyEndpoint(flagEndpoint))

        // Delete the message from the database.
        try database.writeSynchronously {
            let session = try XCTUnwrap($0 as? NSManagedObjectContext)
            let messageDTO = try XCTUnwrap(session.message(id: messageId))
            session.delete(messageDTO)
        }

        // Simulate flag API response with success.
        let payload = FlagMessagePayload(
            currentUser: .dummy(userId: currentUserId, role: .user),
            flaggedMessageId: messageId
        )
        apiClient.test_simulateResponse(.success(payload))

        // Assert `MessageDoesNotExist` error is propogated.
        AssertAsync.willBeTrue(completionCalledError is ClientError.MessageDoesNotExist)
    }

    // MARK: - Add reaction

    func setupReactionData(userId: UserId = .unique) throws -> MessageId {
        let messageId: MessageId = .unique
        try database.createCurrentUser(id: userId)
        try database.createMessage(id: messageId, authorId: userId)
        return messageId
    }

    func test_addReaction_makesCorrectAPICall() throws {
        let reactionType: MessageReactionType = "like"
        let reactionScore = 1
        let reactionExtraData: [String: RawJSON] = [:]
        let messageId: MessageId = try setupReactionData()

        let dbCall = XCTestExpectation(description: "database call")

        // Simulate `addReaction` call.
        messageUpdater.addReaction(
            reactionType,
            score: reactionScore,
            enforceUnique: false,
            extraData: reactionExtraData,
            messageId: messageId
        ) { error in
            dbCall.fulfill()
            XCTAssertNil(error)
        }

        // wait for the db call to be done
        wait(for: [dbCall], timeout: defaultTimeout)

        let request = apiClient.waitForRequest()

        XCTAssertNotNil(apiClient.request_endpoint)

        // Assert correct endpoint is called.
        XCTAssertEqual(
            request,
            AnyEndpoint(.addReaction(
                reactionType,
                score: reactionScore,
                enforceUnique: false,
                extraData: reactionExtraData,
                messageId: messageId
            ))
        )
    }

    func test_addReaction_propagatesSuccessfulResponse() throws {
        let messageId: MessageId = try setupReactionData()
        let dbCall = XCTestExpectation(description: "database call")

        // Simulate `addReaction` call
        messageUpdater.addReaction(
            .init(rawValue: .unique),
            score: 1,
            enforceUnique: false,
            extraData: [:],
            messageId: messageId
        ) { error in
            XCTAssertNil(error)
            dbCall.fulfill()
        }

        wait(for: [dbCall], timeout: defaultTimeout)

        // Requests are sent async so we need to wait for that
        apiClient.waitForRequest()

        // Simulate API response with success
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.success(.init()))
    }

    func test_addReaction_retry() throws {
        let userId: UserId = .unique
        let messageId: MessageId = try setupReactionData(userId: userId)
        let reactionType: MessageReactionType = .init(rawValue: .unique)
        let dbCall = XCTestExpectation(description: "database call")

        // Simulate `addReaction` call
        messageUpdater.addReaction(
            reactionType,
            score: 1,
            enforceUnique: false,
            extraData: [:],
            messageId: messageId
        ) { error in
            XCTAssertNil(error)
            dbCall.fulfill()
        }

        // wait for the db call to be done
        wait(for: [dbCall], timeout: defaultTimeout)

        guard let reaction = database.viewContext.reaction(messageId: messageId, userId: userId, type: reactionType) else {
            XCTFail()
            return
        }

        XCTAssertEqual(reaction.localState, .sending)

        // Simulate API response with failure - this kind of error is not retried
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.failure(TestError()))
        apiClient.waitForRequest()

        try database.writeSynchronously { _ in
            try self.database.writableContext.save()
        }

        guard let reactionReloaded = database.viewContext.reaction(messageId: messageId, userId: userId, type: reactionType) else {
            XCTFail()
            return
        }

        XCTAssertEqual(reactionReloaded.localState, .sendingFailed)
    }

    func test_addReaction_connectionError_localStorageEnabled() throws {
        let userId: UserId = .unique
        let messageId: MessageId = try setupReactionData(userId: userId)
        let reactionType: MessageReactionType = .init(rawValue: .unique)
        let dbCall = XCTestExpectation(description: "database call")

        recreateUpdater(isLocalStorageEnabled: true)

        // Simulate `addReaction` call
        messageUpdater.addReaction(
            reactionType, score: 1, enforceUnique: false, extraData: [:], messageId: messageId
        ) { error in
            XCTAssertNil(error)
            dbCall.fulfill()
        }
        // wait for the db call to be done
        wait(for: [dbCall], timeout: defaultTimeout)
        guard let reaction = database.viewContext.reaction(messageId: messageId, userId: userId, type: reactionType) else {
            XCTFail()
            return
        }

        XCTAssertEqual(reaction.localState, .sending)
        // Simulate API response with failure - this kind of error is not retried
        let networkError = NSError(domain: "", code: NSURLErrorNotConnectedToInternet, userInfo: nil)
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.failure(networkError))
        apiClient.waitForRequest()

        try database.writeSynchronously { _ in
            try self.database.writableContext.save()
        }

        guard let reactionReloaded = database.viewContext.reaction(messageId: messageId, userId: userId, type: reactionType) else {
            XCTFail()
            return
        }

        // Still sending, we keep it because we have offline queuing
        XCTAssertEqual(reactionReloaded.localState, .sending)
    }

    func test_addReaction_connectionError_localStorageDisabled() throws {
        let userId: UserId = .unique
        let messageId: MessageId = try setupReactionData(userId: userId)
        let reactionType: MessageReactionType = .init(rawValue: .unique)
        let dbCall = XCTestExpectation(description: "database call")

        recreateUpdater(isLocalStorageEnabled: false)

        // Simulate `addReaction` call
        messageUpdater.addReaction(
            reactionType, score: 1, enforceUnique: false, extraData: [:], messageId: messageId
        ) { error in
            XCTAssertNil(error)
            dbCall.fulfill()
        }
        // wait for the db call to be done
        wait(for: [dbCall], timeout: defaultTimeout)
        guard let reaction = database.viewContext.reaction(messageId: messageId, userId: userId, type: reactionType) else {
            XCTFail()
            return
        }

        XCTAssertEqual(reaction.localState, .sending)
        // Simulate API response with failure - this kind of error is not retried
        let networkError = NSError(domain: "", code: NSURLErrorNotConnectedToInternet, userInfo: nil)
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.failure(networkError))
        apiClient.waitForRequest()

        try database.writeSynchronously { _ in
            try self.database.writableContext.save()
        }

        guard let reactionReloaded = database.viewContext.reaction(messageId: messageId, userId: userId, type: reactionType) else {
            XCTFail()
            return
        }

        XCTAssertEqual(reactionReloaded.localState, .sendingFailed)
    }

    // MARK: - Delete reaction

    func test_deleteReaction_makesCorrectAPICall() throws {
        let reactionType: MessageReactionType = "like"
        let messageId: MessageId = try setupReactionData()

        let dbCall = XCTestExpectation(description: "database call")

        // Simulate `deleteReaction` call.
        messageUpdater.deleteReaction(reactionType, messageId: messageId) { error in
            XCTAssertNil(error)
            dbCall.fulfill()
        }

        // wait for the db call to be done
        wait(for: [dbCall], timeout: defaultTimeout)

        // Assert correct endpoint is called.
        apiClient.waitForRequest()
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(.deleteReaction(reactionType, messageId: messageId)))
    }

    func test_deleteReaction_propagatesSuccessfulResponse() throws {
        let reactionType: MessageReactionType = "like"
        let messageId: MessageId = try setupReactionData()

        // Simulate `deleteReaction` call.
        let dbCall = XCTestExpectation(description: "database call")
        messageUpdater.deleteReaction(reactionType, messageId: messageId) { error in
            XCTAssertNil(error)
            dbCall.fulfill()
        }

        // wait for the db call to be done
        wait(for: [dbCall], timeout: defaultTimeout)

        // Simulate API response with success.
        apiClient.waitForRequest()
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.success(.init()))
    }

    func test_deleteReaction_propagatesError() throws {
        let userId: UserId = .unique
        let messageId: MessageId = try setupReactionData(userId: userId)
        let reactionType: MessageReactionType = .init(rawValue: .unique)

        try database.writeSynchronously { _ in
            try self.database.writableContext
                .saveReaction(payload: .dummy(
                    type: reactionType,
                    messageId: messageId,
                    user: .dummy(userId: userId),
                    extraData: [:]
                ), cache: nil)
        }

        // Simulate `deleteReaction` call.
        let dbCall = XCTestExpectation(description: "database call")
        messageUpdater.deleteReaction(reactionType, messageId: messageId) { error in
            XCTAssertNil(error)
            dbCall.fulfill()
        }

        // wait for the db call to be done
        wait(for: [dbCall], timeout: defaultTimeout)

        guard let reaction = database.viewContext.reaction(messageId: messageId, userId: userId, type: reactionType) else {
            XCTFail()
            return
        }

        XCTAssertEqual(reaction.localState, .pendingDelete)

        // Simulate API response with failure.
        let error = TestError()
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.failure(error))
        apiClient.waitForRequest()

        try database.writeSynchronously { _ in
            try self.database.writableContext.save()
        }

        guard let reactionReloaded = database.viewContext.reaction(messageId: messageId, userId: userId, type: reactionType) else {
            XCTFail()
            return
        }

        XCTAssertEqual(reactionReloaded.localState, .deletingFailed)
    }

    func test_deleteReaction_connectionError_localStorageEnabled() throws {
        let userId: UserId = .unique
        let messageId: MessageId = try setupReactionData(userId: userId)
        let reactionType: MessageReactionType = .init(rawValue: .unique)

        try database.writeSynchronously { _ in
            try self.database.writableContext
                .saveReaction(payload: .dummy(
                    type: reactionType,
                    messageId: messageId,
                    user: .dummy(userId: userId),
                    extraData: [:]
                ), cache: nil)
        }

        recreateUpdater(isLocalStorageEnabled: true)

        // Simulate `deleteReaction` call.
        let dbCall = XCTestExpectation(description: "database call")
        messageUpdater.deleteReaction(reactionType, messageId: messageId) { error in
            XCTAssertNil(error)
            dbCall.fulfill()
        }

        // wait for the db call to be done
        wait(for: [dbCall], timeout: defaultTimeout)

        guard let reaction = database.viewContext.reaction(messageId: messageId, userId: userId, type: reactionType) else {
            XCTFail()
            return
        }

        XCTAssertEqual(reaction.localState, .pendingDelete)

        // Simulate API response with failure.
        let networkError = NSError(domain: "", code: NSURLErrorNotConnectedToInternet, userInfo: nil)
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.failure(networkError))
        apiClient.waitForRequest()

        try database.writeSynchronously { _ in
            try self.database.writableContext.save()
        }

        guard let reactionReloaded = database.viewContext.reaction(messageId: messageId, userId: userId, type: reactionType) else {
            XCTFail()
            return
        }

        // Still pending, we keep it because we have offline queuing
        XCTAssertEqual(reactionReloaded.localState, .pendingDelete)
    }

    func test_deleteReaction_connectionError_localStorageDisabled() throws {
        let userId: UserId = .unique
        let messageId: MessageId = try setupReactionData(userId: userId)
        let reactionType: MessageReactionType = .init(rawValue: .unique)

        try database.writeSynchronously { _ in
            try self.database.writableContext
                .saveReaction(payload: .dummy(
                    type: reactionType,
                    messageId: messageId,
                    user: .dummy(userId: userId),
                    extraData: [:]
                ), cache: nil)
        }

        recreateUpdater(isLocalStorageEnabled: false)

        // Simulate `deleteReaction` call.
        let dbCall = XCTestExpectation(description: "database call")
        messageUpdater.deleteReaction(reactionType, messageId: messageId) { error in
            XCTAssertNil(error)
            dbCall.fulfill()
        }

        // wait for the db call to be done
        wait(for: [dbCall], timeout: defaultTimeout)

        guard let reaction = database.viewContext.reaction(messageId: messageId, userId: userId, type: reactionType) else {
            XCTFail()
            return
        }

        XCTAssertEqual(reaction.localState, .pendingDelete)

        // Simulate API response with failure.
        let networkError = NSError(domain: "", code: NSURLErrorNotConnectedToInternet, userInfo: nil)
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.failure(networkError))
        apiClient.waitForRequest()

        try database.writeSynchronously { _ in
            try self.database.writableContext.save()
        }

        guard let reactionReloaded = database.viewContext.reaction(messageId: messageId, userId: userId, type: reactionType) else {
            XCTFail()
            return
        }

        XCTAssertEqual(reactionReloaded.localState, .deletingFailed)
    }

    // MARK: - Pinning message

    func test_pinMessage_propagates_MessageDoesNotExist_Error() throws {
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
            let exp = expectation(description: "removeAllData completion")
            database.removeAllData { error in
                if let error = error {
                    XCTFail("removeAllData failed with \(error)")
                }
                exp.fulfill()
            }
            wait(for: [exp], timeout: defaultTimeout)

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
            XCTAssertEqual(message.pinExpires?.bridgeDate, pin.expirationDate)
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
            let exp = expectation(description: "removeAllData completion")
            database.removeAllData { error in
                if let error = error {
                    XCTFail("removeAllData failed with \(error)")
                }
                exp.fulfill()
            }
            wait(for: [exp], timeout: defaultTimeout)

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
            let exp = expectation(description: "removeAllData completion")
            database.removeAllData { error in
                if let error = error {
                    XCTFail("removeAllData failed with \(error)")
                }
                exp.fulfill()
            }
            wait(for: [exp], timeout: defaultTimeout)

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
            let exp = expectation(description: "removeAllData completion")
            database.removeAllData { error in
                if let error = error {
                    XCTFail("removeAllData failed with \(error)")
                }
                exp.fulfill()
            }
            wait(for: [exp], timeout: defaultTimeout)

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

    func test_resendMessage_whenSendingFailed_thenStateChangedToPendingSync() throws {
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

    func test_resendMessage_whenBounced_thenStateChangedToPendingSync() throws {
        let currentUserId: UserId = .unique
        let messageId: MessageId = .unique

        // Create current user is the database
        try database.createCurrentUser(id: currentUserId)

        // Create a new message in the database
        try database.writeSynchronously { session in
            let channelId = ChannelId.unique
            try session.saveChannel(payload: .dummy(channel: .dummy(cid: channelId)))
            try session.saveMessage(
                payload: .dummy(
                    messageId: messageId,
                    moderationDetails: .init(
                        originalText: "",
                        action: MessageModerationAction.bounce.rawValue
                    )
                ),
                for: channelId,
                syncOwnReactions: false,
                cache: nil
            )
        }

        // Resend bounced message
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

    func test_resendMessage_whenSendingFailed_thenSetFailedAttachmentsToPendingUpload() throws {
        let currentUserId: UserId = .unique
        let messageId: MessageId = .unique
        let cid: ChannelId = .unique
        let attachmentId1 = AttachmentId(cid: cid, messageId: messageId, index: 1)
        let attachmentId2 = AttachmentId(cid: cid, messageId: messageId, index: 2)
        let attachmentId3 = AttachmentId(cid: cid, messageId: messageId, index: 3)

        // Create current user is the database
        try database.createCurrentUser(id: currentUserId)

        // Create a new message in the database
        try database.createMessage(id: messageId, authorId: currentUserId, cid: cid, localState: .sendingFailed)

        // Create failed attachments
        try database.writeSynchronously { session in
            let attachment1 = try session.saveAttachment(
                payload: .audio(),
                id: attachmentId1
            )
            let attachment2 = try session.saveAttachment(
                payload: .audio(),
                id: attachmentId2
            )
            let attachment3 = try session.saveAttachment(
                payload: .audio(),
                id: attachmentId3
            )

            attachment1.localState = .uploadingFailed
            attachment2.localState = .uploadingFailed
            attachment3.localState = .uploaded
        }

        // Resend failed message
        let completionError = try waitFor {
            messageUpdater.resendMessage(with: messageId, completion: $0)
        }

        // Load the message
        let message = try XCTUnwrap(database.viewContext.message(id: messageId))

        // Assert completion is called without any error
        XCTAssertNil(completionError)
        
        // Assert failed attachments resent
        let attachment: (AttachmentId) -> AttachmentDTO? = { id in
            message.attachments.first(where: { $0.attachmentID == id })
        }
        XCTAssertEqual(attachment(attachmentId1)?.localState, .pendingUpload)
        XCTAssertEqual(attachment(attachmentId2)?.localState, .pendingUpload)
        XCTAssertEqual(attachment(attachmentId3)?.localState, .uploaded)
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

    func test_dispatchEphemeralMessageAction_cancel_changesPreviewMessage() throws {
        let cid: ChannelId = .unique
        let messageId: MessageId = .unique
        let currentUserId: UserId = .unique

        // Create current user is the database
        try database.createCurrentUser(id: currentUserId)
        // Create channel is the database
        try database.createChannel(cid: cid, withMessages: true)
        // Create a new `ephemeral` message in the database
        try database.createMessage(id: messageId, authorId: currentUserId, type: .ephemeral)

        // Set ephemeral message as channel's previewMessage
        try database.writeSynchronously { session in
            let message = try XCTUnwrap(session.message(id: messageId))
            let channel = try XCTUnwrap(session.channel(cid: cid))
            channel.previewMessage = message
        }

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
        // Assert `previewMessage` of the channel is updated
        XCTAssertFalse(message.previewOfChannel?.cid == cid.rawValue)
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
        let endpoint: Endpoint<MessagePayload.Boxed> = .dispatchEphemeralMessageAction(
            cid: cid,
            messageId: messageId,
            action: action
        )
        AssertAsync.willBeEqual(apiClient.request_endpoint, AnyEndpoint(endpoint))

        // Simulate message response.
        let messagePayload: MessagePayload.Boxed = .init(
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
        let endpoint: Endpoint<MessagePayload.Boxed> = .dispatchEphemeralMessageAction(
            cid: cid,
            messageId: messageId,
            action: action
        )
        AssertAsync.willBeEqual(apiClient.request_endpoint, AnyEndpoint(endpoint))

        // Simulate error response.
        let networkError = TestError()
        let result: Result<MessagePayload.Boxed, Error> = .failure(networkError)
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
        let endpoint: Endpoint<MessagePayload.Boxed> = .dispatchEphemeralMessageAction(
            cid: cid,
            messageId: messageId,
            action: action
        )
        AssertAsync.willBeEqual(apiClient.request_endpoint, AnyEndpoint(endpoint))

        // Update database container to throw the error on write
        let databaseError = TestError()
        database.write_errorResponse = databaseError

        // Simulate message response.
        let messagePayload: MessagePayload.Boxed = .init(
            message: .dummy(
                messageId: messageId,
                authorUserId: currentUserId
            )
        )
        apiClient.test_simulateResponse(.success(messagePayload))

        // Assert database error is propagated.
        AssertAsync.willBeEqual(completionCalledError as? TestError, databaseError)
    }

    // MARK: - Translate message

    func test_translate_makesCorrectAPICall() throws {
        let messageId: MessageId = .unique
        let language = TranslationLanguage.allCases.randomElement()!

        // Make translate call
        messageUpdater.translate(messageId: messageId, to: language)

        // Assert correct endpoint is called.
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(.translate(messageId: messageId, to: language)))
    }

    func test_translate_propagatesSuccessfulResponse() throws {
        let messageId: MessageId = .unique
        let language = TranslationLanguage.allCases.randomElement()!
        let cid: ChannelId = .unique

        try database.createChannel(cid: cid)

        // Make translate call
        var completionCalled = false
        messageUpdater.translate(messageId: messageId, to: language) { error in
            completionCalled = true
            XCTAssertNil(error)
        }

        // Simulate successful response
        apiClient.test_simulateResponse(
            Result<MessagePayload.Boxed, Error>.success(
                .init(
                    message: .dummy(
                        messageId: messageId,
                        authorUserId: .unique,
                        cid: cid
                    )
                )
            )
        )

        AssertAsync.willBeTrue(completionCalled)
    }

    func test_translate_propagatesRequestError() throws {
        let messageId: MessageId = .unique
        let language = TranslationLanguage.allCases.randomElement()!

        // Make translate call
        var completionCalled = false
        let testError = TestError()
        messageUpdater.translate(messageId: messageId, to: language) { error in
            completionCalled = true
            XCTAssertEqual(error as? TestError, testError)
        }

        // Simulate failure response
        apiClient.test_simulateResponse(
            Result<MessagePayload.Boxed, Error>.failure(testError)
        )

        AssertAsync.willBeTrue(completionCalled)
    }

    func test_translate_propagatesDatabaseError() throws {
        let messageId: MessageId = .unique
        let language = TranslationLanguage.allCases.randomElement()!
        let cid: ChannelId = .unique

        try database.createChannel(cid: cid)

        // Update database container to throw the error on write
        let testError = TestError()
        database.write_errorResponse = testError

        // Make translate call
        var completionCalled = false
        messageUpdater.translate(messageId: messageId, to: language) { error in
            completionCalled = true
            XCTAssertEqual(error as? TestError, testError)
        }

        // Simulate successful response
        apiClient.test_simulateResponse(
            Result<MessagePayload.Boxed, Error>.success(
                .init(
                    message: .dummy(
                        messageId: messageId,
                        authorUserId: .unique,
                        cid: cid
                    )
                )
            )
        )

        AssertAsync.willBeTrue(completionCalled)
    }
}

// MARK: - Helpers

extension MessageUpdater_Tests {
    private func AssertLoadReplies(
        expectedNewestReplyAt: Date?,
        for repliesPayload: MessageRepliesPayload,
        with pagination: MessagesPagination,
        line: UInt = #line,
        file: StaticString = #filePath
    ) throws {
        // GIVEN
        let parentMessageId = MessageId.unique
        let cid: ChannelId = .unique
        try database.createChannel(cid: cid)
        try database.writeSynchronously { session in
            try session.saveMessage(
                payload: .dummy(messageId: parentMessageId, text: "Example"),
                for: cid,
                syncOwnReactions: false,
                cache: nil
            )
        }

        // WHEN
        let exp = expectation(description: "load replies completes")
        messageUpdater.loadReplies(cid: cid, messageId: parentMessageId, pagination: pagination) { _ in
            exp.fulfill()
        }
        apiClient.test_simulateResponse(Result<MessageRepliesPayload, Error>.success(repliesPayload))
        waitForExpectations(timeout: defaultTimeout)

        // THEN
        let parentMessageDTO = try XCTUnwrap(database.viewContext.message(id: parentMessageId))
        XCTAssertEqual(parentMessageDTO.newestReplyAt?.bridgeDate, expectedNewestReplyAt)
    }

    private func AssertLoadReplies(
        shouldClearCurrentMessagesExcludingLocalOnly shouldClear: Bool,
        for pagination: MessagesPagination,
        line: UInt = #line,
        file: StaticString = #filePath
    ) throws {
        let parentMessageId = MessageId.unique
        let currentUserId: UserId = .unique
        let currentMessageIds: [MessageId] = [.unique, .unique, .unique]
        let messageIds: [MessageId] = [.unique, .unique, .unique]
        let cid: ChannelId = .unique

        // Save current messages
        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: .dummy(userId: currentUserId, role: .user))
            let channelDTO = try session.saveChannel(payload: .dummy(channel: .dummy(cid: cid)))
            let parentMessage = try session.saveMessage(
                payload: .dummy(messageId: parentMessageId),
                channelDTO: channelDTO,
                syncOwnReactions: false,
                cache: nil
            )
            try currentMessageIds.enumerated().forEach { index, message in
                let currentMessage = try session.saveMessage(
                    payload: .dummy(type: index == 0 ? .error : .regular, messageId: message),
                    channelDTO: channelDTO,
                    syncOwnReactions: false,
                    cache: nil
                )
                currentMessage.showInsideThread = true
                parentMessage.replies.insert(currentMessage)
            }
        }

        var currentMessageDTOs: [MessageDTO] {
            currentMessageIds.compactMap { database.viewContext.message(id: $0) }
        }

        XCTAssertEqual(currentMessageDTOs.map(\.showInsideThread), [true, true, true])

        // Simulate `loadReplies` call
        let exp = expectation(description: "should load replies")
        messageUpdater.loadReplies(cid: cid, messageId: parentMessageId, pagination: pagination) { _ in
            exp.fulfill()
        }

        // Simulate API response with success
        let repliesPayload: MessageRepliesPayload = .init(
            messages: messageIds.map { .dummy(messageId: $0, authorUserId: .unique) }
        )
        apiClient.test_simulateResponse(Result<MessageRepliesPayload, Error>.success(repliesPayload))

        waitForExpectations(timeout: defaultTimeout)

        var newMessageDTOs: [MessageDTO] {
            messageIds.compactMap { database.viewContext.message(id: $0) }
        }

        if shouldClear {
            // Previous current messages are not shown (excluding local messages).
            XCTAssertEqual(currentMessageDTOs.filter { $0.showInsideThread }.count, 1, file: file, line: line)
        } else {
            // Previous current messages are not discarded.
            XCTAssertEqual(currentMessageDTOs.map(\.showInsideThread), [true, true, true], file: file, line: line)
        }

        // Newly fetched messages are shown.
        XCTAssertEqual(newMessageDTOs.map(\.showInsideThread), [true, true, true], file: file, line: line)
    }
}
