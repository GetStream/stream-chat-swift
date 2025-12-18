//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChannelUpdater_Tests: XCTestCase {
    var apiClient: APIClient_Spy!
    var database: DatabaseContainer_Spy!
    var channelRepository: ChannelRepository_Mock!
    var messageRepository: MessageRepository_Mock!
    var paginationStateHandler: MessagesPaginationStateHandler_Mock!
    var channelUpdater: ChannelUpdater!

    override func setUp() {
        super.setUp()

        apiClient = APIClient_Spy()
        database = DatabaseContainer_Spy()
        channelRepository = ChannelRepository_Mock(database: database, apiClient: apiClient)
        messageRepository = MessageRepository_Mock(database: database, apiClient: apiClient)
        paginationStateHandler = MessagesPaginationStateHandler_Mock()
        channelUpdater = ChannelUpdater(
            channelRepository: channelRepository,
            messageRepository: messageRepository,
            paginationStateHandler: paginationStateHandler,
            database: database,
            apiClient: apiClient
        )
    }

    override func tearDown() {
        apiClient.cleanUp()
        apiClient = nil
        channelRepository = nil
        channelUpdater = nil
        messageRepository = nil

        AssertAsync.canBeReleased(&database)
        database = nil

        super.tearDown()
    }

    // MARK: - UpdateChannelQuery

    func test_updateChannelQuery_makesCorrectAPICall() {
        // Simulate `update(channelQuery:)` call
        let query = ChannelQuery(cid: .unique)
        channelUpdater.update(channelQuery: query, isInRecoveryMode: false)

        let referenceEndpoint: Endpoint<ChannelPayload> = .updateChannel(query: query)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }

    func test_updateChannelQueryRecovery_makesCorrectAPICall() {
        // Simulate `update(channelQuery:)` call
        let query = ChannelQuery(cid: .unique)
        channelUpdater.update(channelQuery: query, isInRecoveryMode: true)

        let referenceEndpoint: Endpoint<ChannelPayload> = .updateChannel(query: query)
        XCTAssertEqual(apiClient.recoveryRequest_endpoint, AnyEndpoint(referenceEndpoint))
    }

    func test_updateChannelQuery_successfulResponseData_areSavedToDB() {
        // Simulate `update(channelQuery:)` call
        let expectedPaginationParameter = PaginationParameter.lessThan(.unique)
        let query = ChannelQuery(cid: .unique, paginationParameter: expectedPaginationParameter)
        let expectation = self.expectation(description: "Update completes")
        nonisolated(unsafe) var updateResult: Result<ChannelPayload, Error>!
        channelUpdater.update(channelQuery: query, isInRecoveryMode: false, completion: { result in
            updateResult = result
            expectation.fulfill()
        })

        XCTAssertEqual(paginationStateHandler.beginCallCount, 1)
        XCTAssertEqual(paginationStateHandler.beginCalledWith?.parameter, expectedPaginationParameter)
        XCTAssertEqual(paginationStateHandler.endCallCount, 0)

        // Simulate API response with channel data
        let cid = ChannelId(type: .messaging, id: .unique)
        let payload = dummyPayload(with: cid, numberOfMessages: 2)
        apiClient.test_simulateResponse(.success(payload))

        waitForExpectations(timeout: defaultTimeout)

        let channel = database.viewContext.channel(cid: cid)
        XCTAssertNotNil(channel)
        XCTAssertNil(updateResult.error)
        XCTAssertEqual(channel?.messages.count, 2)

        XCTAssertEqual(paginationStateHandler.endCallCount, 1)
        XCTAssertEqual(paginationStateHandler.endCalledWith?.0?.parameter, expectedPaginationParameter)
        XCTAssertEqual(paginationStateHandler.endCalledWith?.1.value?.count, 2)
    }

    func test_updateChannelQuery_whenNoPagination_thenCallsPaginationStateHandlerWithNil() {
        // Simulate `update(channelQuery:)` call with no pagination
        let query = ChannelQuery(channelPayload: .unique)
        let expectation = self.expectation(description: "Update completes")
        var updateResult: Result<ChannelPayload, Error>!
        channelUpdater.update(channelQuery: query, isInRecoveryMode: false, completion: { result in
            updateResult = result
            expectation.fulfill()
        })

        // Assert begin is called with nil pagination
        XCTAssertEqual(paginationStateHandler.beginCallCount, 1)
        XCTAssertNil(paginationStateHandler.beginCalledWith)
        XCTAssertEqual(paginationStateHandler.endCallCount, 0)

        // Simulate API response with channel data
        let cid = ChannelId(type: .messaging, id: .unique)
        let payload = dummyPayload(with: cid, numberOfMessages: 2)
        apiClient.test_simulateResponse(.success(payload))

        waitForExpectations(timeout: defaultTimeout)

        let channel = database.viewContext.channel(cid: cid)
        XCTAssertNotNil(channel)
        XCTAssertNil(updateResult.error)
        XCTAssertEqual(channel?.messages.count, 2)

        // Assert end is called with nil pagination
        XCTAssertEqual(paginationStateHandler.endCallCount, 1)
        XCTAssertNil(paginationStateHandler.endCalledWith?.0)
        XCTAssertEqual(paginationStateHandler.endCalledWith?.1.value?.count, 2)
    }

    func test_updateChannelQuery_successfulResponseData_oldestMessageAtAndNewestMessageAtAreSavedToDB() {
        // Simulate `update(channelQuery:)` call
        let query = ChannelQuery(cid: .unique)
        let expectation = self.expectation(description: "Update completes")
        nonisolated(unsafe) var updateResult: Result<ChannelPayload, Error>!
        channelUpdater.update(channelQuery: query, isInRecoveryMode: false, completion: { result in
            updateResult = result
            expectation.fulfill()
        })

        let expectedOldestFetchMessage = MessagePayload.dummy(createdAt: .unique)
        let expectedNewestFetchMessage = MessagePayload.dummy(createdAt: .unique)
        paginationStateHandler.mockState.oldestFetchedMessage = expectedOldestFetchMessage
        paginationStateHandler.mockState.newestFetchedMessage = expectedNewestFetchMessage

        // Simulate API response with channel data
        let cid = ChannelId(type: .messaging, id: .unique)
        let payload = dummyPayload(with: cid, numberOfMessages: 2)
        apiClient.test_simulateResponse(.success(payload))

        waitForExpectations(timeout: defaultTimeout)

        let channel = database.viewContext.channel(cid: cid)
        XCTAssertNotNil(channel)
        XCTAssertNil(updateResult.error)
        XCTAssertEqual(channel?.newestMessageAt, expectedNewestFetchMessage.createdAt.bridgeDate)
        XCTAssertEqual(channel?.oldestMessageAt, expectedOldestFetchMessage.createdAt.bridgeDate)
    }

    func test_updateChannelQueryRecovery_successfulResponseData_areSavedToDB() {
        // Simulate `update(channelQuery:)` call
        let query = ChannelQuery(cid: .unique)
        let expectation = self.expectation(description: "Update completes")
        channelUpdater.update(channelQuery: query, isInRecoveryMode: true, completion: { result in
            XCTAssertNil(result.error)
            expectation.fulfill()
        })

        // Simulate API response with channel data
        let cid = ChannelId(type: .messaging, id: .unique)
        let payload = dummyPayload(with: cid, numberOfMessages: 2)
        apiClient.test_simulateRecoveryResponse(.success(payload))

        waitForExpectations(timeout: defaultTimeout)

        // Assert the data is stored in the DB
        let channel = database.viewContext.channel(cid: cid)
        XCTAssertNotNil(channel)
        XCTAssertEqual(channel?.messages.count, 2)
    }

    func test_updateChannelQuery_successfulResponseData_areSavedToDB_localOnlyMessagesAreKept() throws {
        let cid = ChannelId(type: .messaging, id: .unique)

        try database.createCurrentUser()
        try database.createChannel(cid: cid, withMessages: false)
        // Local only message
        try database.createMessage(cid: cid, localState: .sendingFailed)
        try database.createMessage(cid: cid, localState: .pendingSend)
        // Not local only message
        try database.createMessage(cid: cid, localState: .syncing)

        try database.writeSynchronously { session in
            let channel = session.channel(cid: cid)
            XCTAssertEqual(channel?.messages.count, 3)
        }

        // Simulate `update(channelQuery:)` call
        let query = ChannelQuery(cid: cid)
        let expectation = self.expectation(description: "Update completes")
        channelUpdater.update(channelQuery: query, isInRecoveryMode: false, completion: { result in
            XCTAssertNil(result.error)
            expectation.fulfill()
        })

        // Simulate API response with channel data
        let payload = dummyPayload(with: cid, numberOfMessages: 2)
        apiClient.test_simulateResponse(.success(payload))

        waitForExpectations(timeout: defaultTimeout)

        // Assert the data is stored in the DB
        let channel = database.viewContext.channel(cid: cid)
        XCTAssertNotNil(channel)
        XCTAssertEqual(channel?.messages.count, 4)
    }

    func test_updateChannelQueryRecovery_successfulResponseData_areSavedToDB_localOnlyMessagesAreKept() throws {
        let cid = ChannelId(type: .messaging, id: .unique)

        try database.createCurrentUser()
        try database.createChannel(cid: cid, withMessages: false)
        // Local only message
        try database.createMessage(cid: cid, localState: .sendingFailed)
        try database.createMessage(cid: cid, localState: .pendingSend)
        // Not local only message
        try database.createMessage(cid: cid, localState: .syncing)

        try database.writeSynchronously { session in
            let channel = session.channel(cid: cid)
            XCTAssertEqual(channel?.messages.count, 3)
        }

        // Simulate `update(channelQuery:)` call
        let query = ChannelQuery(cid: .unique)
        let expectation = self.expectation(description: "Update completes")
        channelUpdater.update(channelQuery: query, isInRecoveryMode: true, completion: { result in
            XCTAssertNil(result.error)
            expectation.fulfill()
        })

        // Simulate API response with channel data
        let payload = dummyPayload(with: cid, numberOfMessages: 2)
        apiClient.test_simulateRecoveryResponse(.success(payload))

        waitForExpectations(timeout: defaultTimeout)

        // Assert the data is stored in the DB
        let channel = database.viewContext.channel(cid: cid)
        XCTAssertNotNil(channel)
        XCTAssertEqual(channel?.messages.count, 4)
    }

    func test_updateChannelQuery_errorResponse_isPropagatedToCompletion() {
        // Simulate `update(channelQuery:)` call
        let query = ChannelQuery(cid: .unique)
        nonisolated(unsafe) var completionCalledError: Error?
        channelUpdater.update(channelQuery: query, isInRecoveryMode: false, completion: { completionCalledError = $0.error })

        // Simulate API response with failure
        let error = TestError()
        apiClient.test_simulateResponse(Result<ChannelPayload, Error>.failure(error))

        // Assert the completion is called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }

    func test_updateChannelQueryRecovery_errorResponse_isPropagatedToCompletion() {
        // Simulate `update(channelQuery:)` call
        let query = ChannelQuery(cid: .unique)
        nonisolated(unsafe) var completionCalledError: Error?
        channelUpdater.update(channelQuery: query, isInRecoveryMode: true, completion: { completionCalledError = $0.error })

        // Simulate API response with failure
        let error = TestError()
        apiClient.test_simulateRecoveryResponse(Result<ChannelPayload, Error>.failure(error))

        // Assert the completion is called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }

    func test_updateChannelQuery_completionForCreatedChannelCalled() {
        // Simulate `update(channelQuery:)` call
        let query = ChannelQuery(channelPayload: .unique)
        nonisolated(unsafe) var cid: ChannelId = .unique

        var channel: ChatChannel? {
            try? database.viewContext.channel(cid: cid)?.asModel()
        }

        let callback: @Sendable (ChannelId) -> Void = {
            cid = $0
            // Assert channel is not saved to DB before callback returns
            AssertAsync.staysTrue(channel == nil)
        }

        // Simulate `updateChannel` call
        let completionCalled = expectation(description: "completion called")
        channelUpdater
            .update(channelQuery: query, isInRecoveryMode: false, onChannelCreated: callback, completion: { _ in
                completionCalled.fulfill()
            })

        // Simulate API response with channel data
        let payload = dummyPayload(with: query.cid!)
        apiClient.test_simulateResponse(.success(payload))

        wait(for: [completionCalled], timeout: defaultTimeout)

        // Assert `onChannelCreated` is called
        XCTAssertEqual(cid, query.cid)
        // Assert channel is saved to DB after
        AssertAsync.willBeTrue(channel != nil)
    }

    func test_updateChannelQueryRecovery_completionForCreatedChannelCalled() {
        // Simulate `update(channelQuery:)` call
        let query = ChannelQuery(channelPayload: .unique)
        nonisolated(unsafe) var cid: ChannelId = .unique

        var channel: ChatChannel? {
            try? database.viewContext.channel(cid: cid)?.asModel()
        }

        let callback: @Sendable (ChannelId) -> Void = {
            cid = $0
            // Assert channel is not saved to DB before callback returns
            AssertAsync.staysTrue(channel == nil)
        }

        // Simulate `updateChannel` call
        let completionCalled = expectation(description: "completion called")
        channelUpdater
            .update(channelQuery: query, isInRecoveryMode: true, onChannelCreated: callback, completion: { _ in
                completionCalled.fulfill()
            })

        // Simulate API response with channel data
        let payload = dummyPayload(with: query.cid!)
        apiClient.test_simulateRecoveryResponse(.success(payload))

        wait(for: [completionCalled], timeout: defaultTimeout)

        // Assert `onChannelCreated` is called
        XCTAssertEqual(cid, query.cid)
        // Assert channel is saved to DB after
        AssertAsync.willBeTrue(channel != nil)
    }

    func test_updateChannelQuery_successfulResponseData_oldMessagesAreNotKeptIfPaginationDoesNotHaveParameter() throws {
        let cid = ChannelId(type: .messaging, id: .unique)
        let query = ChannelQuery(cid: cid, pageSize: 10, paginationParameter: nil, membersLimit: 10, watchersLimit: 10)

        // Populate messages for channel
        try database.writeSynchronously { session in
            try session.saveChannel(payload: self.dummyPayload(with: cid, numberOfMessages: 0))
            try (1...3).forEach {
                try session.saveMessage(
                    payload: self.dummyMessagePayload(id: "\($0)dames"),
                    for: cid,
                    syncOwnReactions: false,
                    cache: nil
                )
            }
        }

        XCTAssertEqual(database.viewContext.channel(cid: cid)?.messages.count, 3)

        // Simulate `update(channelQuery:)` call
        let expectation = self.expectation(description: "update call completion")
        channelUpdater.update(channelQuery: query, isInRecoveryMode: false, completion: { result in
            XCTAssertNil(result.error)
            expectation.fulfill()
        })

        // Simulate API response with channel data
        let payload = dummyPayload(with: cid, numberOfMessages: 1)
        apiClient.test_simulateResponse(.success(payload))

        waitForExpectations(timeout: defaultTimeout, handler: nil)

        let channel = database.viewContext.channel(cid: cid)
        XCTAssertNotNil(channel)
        // Removes old ones, only keeps the one in the simulated response
        XCTAssertEqual(channel?.messages.count, 1)
    }

    func test_updateChannelQueryRecovery_successfulResponseData_oldMessagesAreNotKeptIfPaginationDoesNotHaveParameter() throws {
        let cid = ChannelId(type: .messaging, id: .unique)
        let query = ChannelQuery(cid: cid, pageSize: 10, paginationParameter: nil, membersLimit: 10, watchersLimit: 10)

        // Populate messages for channel
        try database.writeSynchronously { session in
            try session.saveChannel(payload: self.dummyPayload(with: cid, numberOfMessages: 0))
            try (1...3).forEach {
                try session.saveMessage(
                    payload: self.dummyMessagePayload(id: "\($0)dames"),
                    for: cid,
                    syncOwnReactions: false,
                    cache: nil
                )
            }
        }

        XCTAssertEqual(database.viewContext.channel(cid: cid)?.messages.count, 3)

        // Simulate `update(channelQuery:)` call
        let expectation = self.expectation(description: "update call completion")
        channelUpdater.update(channelQuery: query, isInRecoveryMode: true, completion: { result in
            XCTAssertNil(result.error)
            expectation.fulfill()
        })

        // Simulate API response with channel data
        let payload = dummyPayload(with: cid, numberOfMessages: 1)
        apiClient.test_simulateRecoveryResponse(.success(payload))

        waitForExpectations(timeout: defaultTimeout, handler: nil)

        let channel = database.viewContext.channel(cid: cid)
        XCTAssertNotNil(channel)
        // Removes old ones, only keeps the one in the simulated response
        XCTAssertEqual(channel?.messages.count, 1)
    }

    func test_updateChannelQuery_successfulResponseData_oldMessagesAreKeptIfPaginationHasParameter() throws {
        let cid = ChannelId(type: .messaging, id: .unique)
        let query = ChannelQuery(
            cid: cid,
            pageSize: 10,
            paginationParameter: .greaterThan("something"),
            membersLimit: 10,
            watchersLimit: 10
        )

        // Populate messages for channel
        try database.writeSynchronously { session in
            try session.saveChannel(payload: self.dummyPayload(with: cid, numberOfMessages: 0))
            try (1...3).forEach {
                try session.saveMessage(
                    payload: self.dummyMessagePayload(id: "\($0)"),
                    for: cid,
                    syncOwnReactions: false,
                    cache: nil
                )
            }
        }

        XCTAssertEqual(database.viewContext.channel(cid: cid)?.messages.count, 3)

        // Simulate `update(channelQuery:)` call
        let expectation = self.expectation(description: "update call completion")
        channelUpdater.update(channelQuery: query, isInRecoveryMode: false, completion: { result in
            XCTAssertNil(result.error)
            expectation.fulfill()
        })

        // Simulate API response with channel data
        let payload = dummyPayload(with: cid, numberOfMessages: 1)
        apiClient.test_simulateResponse(.success(payload))

        waitForExpectations(timeout: defaultTimeout, handler: nil)

        let channel = database.viewContext.channel(cid: cid)
        XCTAssertNotNil(channel)
        // Adds the message in the simulated response on top of the existing ones as we are paginating
        XCTAssertEqual(channel?.messages.count, 4)
    }

    func test_updateChannelQueryRecovery_successfulResponseData_oldMessagesAreKeptIfPaginationHasParameter() throws {
        let cid = ChannelId(type: .messaging, id: .unique)
        let query = ChannelQuery(
            cid: cid,
            pageSize: 10,
            paginationParameter: .greaterThan("something"),
            membersLimit: 10,
            watchersLimit: 10
        )

        // Populate messages for channel
        try database.writeSynchronously { session in
            try session.saveChannel(payload: self.dummyPayload(with: cid, numberOfMessages: 0))
            try (1...3).forEach {
                try session.saveMessage(
                    payload: self.dummyMessagePayload(id: "\($0)"),
                    for: cid,
                    syncOwnReactions: false,
                    cache: nil
                )
            }
        }

        XCTAssertEqual(database.viewContext.channel(cid: cid)?.messages.count, 3)

        // Simulate `update(channelQuery:)` call
        let expectation = self.expectation(description: "update call completion")
        channelUpdater.update(channelQuery: query, isInRecoveryMode: true, completion: { result in
            XCTAssertNil(result.error)
            expectation.fulfill()
        })

        // Simulate API response with channel data
        let payload = dummyPayload(with: cid, numberOfMessages: 1)
        apiClient.test_simulateRecoveryResponse(.success(payload))

        waitForExpectations(timeout: defaultTimeout, handler: nil)

        let channel = database.viewContext.channel(cid: cid)
        XCTAssertNotNil(channel)
        // Adds the message in the simulated response on top of the existing ones as we are paginating
        XCTAssertEqual(channel?.messages.count, 4)
    }

    func test_updateChannelQuery_whenIsJumpingToMessage_thenDeleteAllPreviousMessagesFromChannel() throws {
        let cid = ChannelId(type: .messaging, id: .unique)
        let query = ChannelQuery(cid: cid, paginationParameter: .around(.unique))

        let previousMessagesCount = 10
        try database.writeSynchronously { session in
            try session.saveChannel(payload: self.dummyPayload(
                with: cid, numberOfMessages: previousMessagesCount
            ))
        }

        let expectation = self.expectation(description: "Update completes")
        channelUpdater.update(channelQuery: query, isInRecoveryMode: false, completion: { _ in
            expectation.fulfill()
        })

        let expectedMessagesCount = 5
        let payload = dummyPayload(with: cid, numberOfMessages: expectedMessagesCount)
        apiClient.test_simulateResponse(.success(payload))

        waitForExpectations(timeout: defaultTimeout)

        let channel = try XCTUnwrap(database.viewContext.channel(cid: cid))
        XCTAssertEqual(channel.messages.count, expectedMessagesCount)
    }

    func test_updateChannelQuery_whenIsJumpingToMessage_whenRequestFails_thenDoesNotDeleteMessages() throws {
        let cid = ChannelId(type: .messaging, id: .unique)
        let query = ChannelQuery(cid: cid, paginationParameter: .around(.unique))

        let previousMessagesCount = 10
        try database.writeSynchronously { session in
            try session.saveChannel(payload: self.dummyPayload(
                with: cid, numberOfMessages: previousMessagesCount
            ))
        }

        let expectation = self.expectation(description: "Update completes")
        channelUpdater.update(channelQuery: query, isInRecoveryMode: false, completion: { _ in
            expectation.fulfill()
        })

        let expectedMessagesCount = previousMessagesCount
        let payload = dummyPayload(with: cid, numberOfMessages: expectedMessagesCount)
        apiClient.test_simulateResponse(.success(payload))

        waitForExpectations(timeout: defaultTimeout)

        let channel = try XCTUnwrap(database.viewContext.channel(cid: cid))
        XCTAssertEqual(channel.messages.count, expectedMessagesCount)
    }

    // MARK: - Messages

    func test_createNewMessage() throws {
        // Prepare the current user and channel first
        let cid: ChannelId = .unique
        let currentUserId: UserId = .unique

        _ = try waitFor { completion in
            database.write({ (session) in
                let currentUserPayload: CurrentUserPayload = .dummy(
                    userId: currentUserId,
                    role: .admin,
                    extraData: [:]
                )

                try session.saveCurrentUser(payload: currentUserPayload)

                try session.saveChannel(payload: self.dummyPayload(with: cid))

            }, completion: completion)
        }

        // New message values
        let text: String = .unique
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

        // Create new message
        let newMessage: ChatMessage = try waitFor { completion in
            channelUpdater.createNewMessage(
                in: cid,
                messageId: .unique,
                text: text,
                pinning: MessagePinning(expirationDate: .unique),
                isSilent: false,
                isSystem: false,
                command: command,
                arguments: arguments,
                attachments: attachmentEnvelopes,
                mentionedUserIds: [currentUserId],
                quotedMessageId: nil,
                skipPush: true,
                skipEnrichUrl: true,
                extraData: extraData
            ) { result in
                do {
                    let newMessage = try result.get()
                    completion(newMessage)
                } catch {
                    XCTFail("Saving the message failed. \(error)")
                }
            }
        }

        // Make sure when creating a new message, the cid is locally available.
        XCTAssertNotNil(newMessage.cid)

        func id(for envelope: AnyAttachmentPayload) -> AttachmentId {
            .init(cid: cid, messageId: newMessage.id, index: attachmentEnvelopes.firstIndex(of: envelope)!)
        }

        let messageDTO: MessageDTO = try XCTUnwrap(
            database.viewContext.message(id: newMessage.id)
        )
        XCTAssertEqual(messageDTO.skipPush, true)
        XCTAssertEqual(messageDTO.skipEnrichUrl, true)
        XCTAssertEqual(messageDTO.mentionedUserIds, [currentUserId])
        XCTAssertEqual(messageDTO.type, "regular")

        let message = try messageDTO.asModel()
        XCTAssertEqual(message.text, text)
        XCTAssertEqual(message.command, command)
        XCTAssertEqual(message.arguments, arguments)
        XCTAssertEqual(message.attachmentCounts.count, 3)
        XCTAssertEqual(message.imageAttachments, [imageAttachmentEnvelope.attachment(id: id(for: imageAttachmentEnvelope))])
        XCTAssertEqual(message.fileAttachments, [fileAttachmentEnvelope.attachment(id: id(for: fileAttachmentEnvelope))])
        XCTAssertEqual(
            message.attachments(payloadType: TestAttachmentPayload.self),
            [customAttachmentEnvelope.attachment(id: id(for: customAttachmentEnvelope))]
        )

        XCTAssertEqual(message.extraData, [:])
        XCTAssertEqual(message.localState, .pendingSend)
        XCTAssertEqual(message.isPinned, true)
        XCTAssertEqual(message.isSilent, false)
    }

    func test_createNewMessage_propagatesErrorWhenSavingFails() throws {
        // Prepare the current user and channel first
        let cid: ChannelId = .unique
        let currentUserId: UserId = .unique

        _ = try waitFor { completion in
            database.write({ (session) in
                let currentUserPayload: CurrentUserPayload = .dummy(
                    userId: currentUserId,
                    role: .admin,
                    extraData: [:]
                )

                try session.saveCurrentUser(payload: currentUserPayload)

                try session.saveChannel(payload: self.dummyPayload(with: cid))

            }, completion: completion)
        }

        // Simulate the DB failing with `TestError`
        let testError = TestError()
        database.write_errorResponse = testError

        let result: Result<ChatMessage, Error> = try waitFor { completion in
            channelUpdater.createNewMessage(
                in: .unique,
                messageId: .unique,
                text: .unique,
                isSilent: false,
                isSystem: false,
                command: .unique,
                arguments: .unique,
                mentionedUserIds: [.unique],
                quotedMessageId: nil,
                skipPush: false,
                skipEnrichUrl: false,
                extraData: [:]
            ) { completion($0) }
        }

        AssertResultFailure(result, testError)
    }

    // MARK: - Update channel

    func test_updateChannel_makesCorrectAPICall() {
        let channelPayload: ChannelEditDetailPayload = .unique

        // Simulate `updateChannel(channelPayload:, completion:)` call
        channelUpdater.updateChannel(channelPayload: channelPayload)

        // Assert correct endpoint is called
        let referenceEndpoint: Endpoint<EmptyResponse> = .updateChannel(channelPayload: channelPayload)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }

    func test_updateChannel_successfulResponse_isPropagatedToCompletion() {
        // Simulate `updateChannel(channelPayload:, completion:)` call
        nonisolated(unsafe) var completionCalled = false
        channelUpdater.updateChannel(channelPayload: .unique) { error in
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

    func test_updateChannel_errorResponse_isPropagatedToCompletion() {
        // Simulate `updateChannel(channelPayload:, completion:)` call
        nonisolated(unsafe) var completionCalledError: Error?
        channelUpdater.updateChannel(channelPayload: .unique) { completionCalledError = $0 }

        // Simulate API response with failure
        let error = TestError()
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.failure(error))

        // Assert the completion is called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }
    
    func test_updateChannel_noPagination_clearsMembers() throws {
        let context = database.backgroundReadOnlyContext
        let cid = ChannelId.unique
        try database.createChannel(cid: cid)
        try database.createMember(cid: cid)
        // Initially 2 members (one is created with the channel)
        context.performAndWait {
            let members = context.channel(cid: cid)?.members
            XCTAssertEqual(2, members?.count)
        }
        
        // Response has 1 member
        let members = [MemberPayload.dummy()]
        apiClient.test_mockResponseResult(
            .success(
                ChannelPayload.dummy(
                    channel: .dummy(
                        cid: cid,
                        members: members
                    ),
                    members: members
                )
            )
        )
        
        let query = ChannelQuery(cid: .unique)
        let expectation = XCTestExpectation()
        channelUpdater.update(channelQuery: query, isInRecoveryMode: false, completion: { _ in
            expectation.fulfill()
        })
        wait(for: [expectation], timeout: defaultTimeout)
        
        context.performAndWait {
            let dto = context.channel(cid: cid)
            XCTAssertEqual(1, dto?.members.count)
        }
    }

    // MARK: - Partial channel update

    func test_partialChannelUpdate_makesCorrectAPICall() {
        let updates: ChannelEditDetailPayload = .unique
        let unsetProperties: [String] = ["user.id", "channel_store"]

        // Simulate `partialChannelUpdate(updates:unsetProperties:completion:)` call
        channelUpdater.partialChannelUpdate(updates: updates, unsetProperties: unsetProperties)

        // Assert correct endpoint is called
        let referenceEndpoint: Endpoint<EmptyResponse> = .partialChannelUpdate(updates: updates, unsetProperties: unsetProperties)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }

    func test_partialChannelUpdate_successfulResponse_isPropagatedToCompletion() {
        // Simulate `partialChannelUpdate(updates:unsetProperties:completion:)` call
        nonisolated(unsafe) var receivedError: Error?
        let expectation = self.expectation(description: "partialChannelUpdate completion")
        channelUpdater.partialChannelUpdate(updates: .unique, unsetProperties: []) { error in
            receivedError = error
            expectation.fulfill()
        }

        // Simulate API response with success
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.success(.init()))
        waitForExpectations(timeout: defaultTimeout)

        XCTAssertNil(receivedError)
    }

    func test_partialChannelUpdate_errorResponse_isPropagatedToCompletion() {
        // Simulate `partialChannelUpdate(updates:unsetProperties:completion:)` call
        nonisolated(unsafe) var receivedError: Error?
        let expectation = self.expectation(description: "partialChannelUpdate completion")
        channelUpdater.partialChannelUpdate(updates: .unique, unsetProperties: []) { error in
            receivedError = error
            expectation.fulfill()
        }

        // Simulate API response with failure
        let error = TestError()
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.failure(error))
        waitForExpectations(timeout: defaultTimeout)

        XCTAssertEqual(receivedError, error)
    }

    // MARK: - Mute channel

    func test_muteChannel_makesCorrectAPICall() {
        let channelID = ChannelId.unique

        // Simulate `muteChannel()` call
        channelUpdater.muteChannel(cid: channelID)

        // Assert correct endpoint is called
        let referenceEndpoint: Endpoint<MutedChannelPayloadResponse> = .muteChannel(cid: channelID)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }
    
    func test_muteChannelWithExpiration_makesCorrectAPICall() {
        let channelID = ChannelId.unique
        let expiration = 1_000_000

        // Simulate `muteChannel(cid:, mute:, completion:)` call
        channelUpdater.muteChannel(cid: channelID, expiration: expiration)

        // Assert correct endpoint is called
        let referenceEndpoint: Endpoint<MutedChannelPayloadResponse> = .muteChannel(cid: channelID, expiration: expiration)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }

    func test_muteChannel_successfulResponse_isPropagatedToCompletion() throws {
        // Pre-save channel and current user
        let cid = ChannelId.unique
        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: .dummy(userId: .unique, role: .admin))
            try session.saveChannel(payload: .dummy(channel: .dummy(cid: cid)))
        }

        // Simulate `muteChannel(cid:, completion:)` call
        let exp = expectation(description: "muteChannel completion")
        channelUpdater.muteChannel(cid: cid) { error in
            XCTAssertNil(error)
            exp.fulfill()
        }

        // Simulate API response with success
        apiClient.test_simulateResponse(
            Result<MutedChannelPayloadResponse, Error>.success(
                .init(
                    channelMute: .init(
                        mutedChannel: .dummy(cid: cid),
                        user: .dummy(userId: .unique),
                        createdAt: .unique,
                        updatedAt: .unique
                    )
                )
            )
        )

        waitForExpectations(timeout: defaultTimeout)
        XCTAssert(database.viewContext.channel(cid: cid)?.mute != nil)
    }
    
    func test_muteChannelWithExpiration_successfulResponse_isPropagatedToCompletion() {
        let expiration = 1_000_000
        
        // Simulate `muteChannel(cid:, completion:, expiration:)` call
        nonisolated(unsafe) var completionCalled = false
        channelUpdater.muteChannel(cid: .unique, expiration: expiration) { error in
            XCTAssertNil(error)
            completionCalled = true
        }

        // Assert completion is not called yet
        XCTAssertFalse(completionCalled)

        // Simulate API response with success
        apiClient.test_simulateResponse(
            Result<MutedChannelPayloadResponse, Error>.success(
                .init(
                    channelMute: .init(
                        mutedChannel: .dummy(),
                        user: .dummy(userId: .unique),
                        createdAt: .unique,
                        updatedAt: .unique
                    )
                )
            )
        )

        // Assert completion is called
        AssertAsync.willBeTrue(completionCalled)
    }

    func test_muteChannel_errorResponse_isPropagatedToCompletion() {
        // Simulate `muteChannel(cid:, completion:)` call
        nonisolated(unsafe) var completionCalledError: Error?
        channelUpdater.muteChannel(cid: .unique) { completionCalledError = $0 }

        // Simulate API response with failure
        let error = TestError()
        apiClient.test_simulateResponse(Result<MutedChannelPayloadResponse, Error>.failure(error))

        // Assert the completion is called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }
    
    func test_muteChannelWithExpiration_errorResponse_isPropagatedToCompletion() {
        let expiration = 1_000_000
        
        // Simulate `muteChannel(cid:, completion:, expiration:)` call
        nonisolated(unsafe) var completionCalledError: Error?
        channelUpdater.muteChannel(cid: .unique, expiration: expiration) { completionCalledError = $0 }

        // Simulate API response with failure
        let error = TestError()
        apiClient.test_simulateResponse(Result<MutedChannelPayloadResponse, Error>.failure(error))

        // Assert the completion is called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }

    // MARK: - Unmute channel

    func test_unmuteChannel_makesCorrectAPICall() {
        let channelID = ChannelId.unique

        // Simulate `unmuteChannel(cid:, completion:)` call
        channelUpdater.unmuteChannel(cid: channelID)

        // Assert correct endpoint is called
        let referenceEndpoint: Endpoint<EmptyResponse> = .unmuteChannel(cid: channelID)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }

    func test_unmuteChannel_successfulResponse_isPropagatedToCompletion() throws {
        // Pre-save muted channel
        let cid = ChannelId.unique
        try database.writeSynchronously { session in
            let userId = UserId.unique
            try session.saveCurrentUser(payload: .dummy(userId: userId, role: .admin))
            try session.saveChannel(payload: .dummy(channel: .dummy(cid: cid)))
            try session.saveChannelMute(
                payload: .init(
                    mutedChannel: .dummy(cid: cid),
                    user: .dummy(userId: userId),
                    createdAt: .unique,
                    updatedAt: .unique
                )
            )
        }
        XCTAssertEqual(try? database.viewContext.channel(cid: cid)?.asModel().isMuted, true)

        // Simulate `unmuteChannel(cid:, completion:)` call
        nonisolated(unsafe) var completionCalled = false
        channelUpdater.unmuteChannel(cid: cid) { error in
            XCTAssertNil(error)
            completionCalled = true
        }

        // Assert completion is not called yet
        XCTAssertFalse(completionCalled)

        // Simulate API response with success
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.success(.init()))

        // Assert completion is called
        AssertAsync.willBeTrue(completionCalled)
        // Assert the channel is unmuted in the DB
        AssertAsync.willBeEqual(
            try? database.viewContext.channel(cid: cid)?.asModel().isMuted,
            false
        )
    }

    func test_unmuteChannel_errorResponse_isPropagatedToCompletion() {
        // Simulate `unmuteChannel(cid:, completion:)` call
        nonisolated(unsafe) var completionCalledError: Error?
        channelUpdater.unmuteChannel(cid: .unique) { completionCalledError = $0 }

        // Simulate API response with failure
        let error = TestError()
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.failure(error))

        // Assert the completion is called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }

    // MARK: - Delete channel

    func test_deleteChannel_makesCorrectAPICall() {
        let channelID = ChannelId.unique

        // Simulate `deleteChannel(cid:, completion:)` call
        channelUpdater.deleteChannel(cid: channelID)

        // Assert correct endpoint is called
        let referenceEndpoint: Endpoint<EmptyResponse> = .deleteChannel(cid: channelID)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }

    func test_deleteChannel_successfulResponse_isPropagatedToCompletion() {
        // Simulate `deleteChannel(cid:, completion:)` call
        nonisolated(unsafe) var completionCalled = false
        channelUpdater.deleteChannel(cid: .unique) { error in
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

    func test_deleteChannel_errorResponse_isPropagatedToCompletion() {
        // Simulate `deleteChannel(cid:, completion:)` call
        nonisolated(unsafe) var completionCalledError: Error?
        channelUpdater.deleteChannel(cid: .unique) { completionCalledError = $0 }

        // Simulate API response with failure
        let error = TestError()
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.failure(error))

        // Assert the completion is called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }

    // MARK: - Truncate channel

    func test_truncateChannel_makesCorrectAPICallWithoutMessage() {
        let channelID = ChannelId.unique
        let skipPush = true
        let hardDelete = true

        // Simulate `truncateChannel(cid:, completion:)` call
        channelUpdater.truncateChannel(
            cid: channelID,
            skipPush: skipPush,
            hardDelete: hardDelete,
            systemMessage: nil
        )

        // Assert correct endpoint is called
        let referenceEndpoint: Endpoint<EmptyResponse> = .truncateChannel(
            cid: channelID,
            skipPush: skipPush,
            hardDelete: hardDelete,
            message: nil
        )

        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }

    func test_truncateChannel_makesCorrectAPICallWithMessage() throws {
        // GIVEN
        let currentUserId: UserId = .unique
        let currentUserName = "John"
        try channelUpdater.database.createCurrentUser(id: currentUserId, name: currentUserName)
        let currentUser: UserRequestBody = .dummy(
            userId: currentUserId,
            name: currentUserName,
            imageURL: nil
        )

        let channelID = ChannelId.unique
        let skipPush = true
        let hardDelete = true
        let systemMessage = "System message"

        // WHEN
        // Simulate `truncateChannel(cid:, completion:)` call
        channelUpdater.truncateChannel(
            cid: channelID,
            skipPush: skipPush,
            hardDelete: hardDelete,
            systemMessage: systemMessage
        )

        // THEN
        AssertAsync { [unowned self] in
            // Assert correct endpoint is called
            Assert.willBeEqual(self.apiClient.request_endpoint, AnyEndpoint(.truncateChannel(
                cid: channelID,
                skipPush: skipPush,
                hardDelete: hardDelete,
                message: MessageRequestBody(
                    // inject generated message id
                    id: (
                        self.apiClient
                            .request_endpoint?.body?
                            .encodable as? ChannelTruncateRequestPayload
                    )?
                        .message?.id ?? "id",
                    user: currentUser,
                    text: systemMessage,
                    type: nil,
                    extraData: [:]
                )
            )))
        }
    }

    func test_truncateChannel_failsAPICallWithMessageWhenNoCurrentUser() throws {
        // GIVEN
        let expectation = expectation(description: "When no current user is provided, truncate channel with system message fails")
        let channelID = ChannelId.unique
        let skipPush = true
        let hardDelete = true
        let systemMessage = "System message"

        // WHEN
        // Simulate `truncateChannel(cid:, completion:)` call
        channelUpdater.truncateChannel(
            cid: channelID,
            skipPush: skipPush,
            hardDelete: hardDelete,
            systemMessage: systemMessage
        ) { error in
            // THEN
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        // In this case, timeout `10` should be used for both local and CI runs
        wait(for: [expectation], timeout: 10)
    }

    func test_truncateChannel_successfulResponse_isPropagatedToCompletion() {
        // Simulate `truncateChannel(cid:, completion:)` call
        nonisolated(unsafe) var completionCalled = false
        channelUpdater.truncateChannel(cid: .unique) { error in
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

    func test_truncateChannel_errorResponse_isPropagatedToCompletion() {
        // Simulate `truncateChannel(cid:, completion:)` call
        nonisolated(unsafe) var completionCalledError: Error?
        channelUpdater.truncateChannel(cid: .unique) { completionCalledError = $0 }

        // Simulate API response with failure
        let error = TestError()
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.failure(error))

        // Assert the completion is called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }

    // MARK: - Hide channel

    func test_hideChannel_makesCorrectAPICall() {
        let channelID = ChannelId.unique
        let clearHistory = true

        // Simulate `hideChannel(cid:, clearHistory:, completion:)` call
        channelUpdater.hideChannel(cid: channelID, clearHistory: clearHistory)

        // Assert correct endpoint is called
        let referenceEndpoint: Endpoint<EmptyResponse> = .hideChannel(cid: channelID, clearHistory: clearHistory)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }

    func test_hideChannel_successfulResponse_isPropagatedToCompletion() throws {
        // This part is for the case where the channel is already hidden on backend
        // But SDK is not aware of this (so channel.hiddenAt is not set)
        // Consecutive `hideChannel` calls won't generate `channel.hidden` events
        // and SDK has no way to learn channel was hidden
        // So, ChannelUpdater marks the Channel as hidden on successful API response

        // Create a channel in DB
        let cid = ChannelId.unique

        try database.writeSynchronously {
            try $0.saveChannel(payload: self.dummyPayload(with: cid))
        }

        var channel: ChannelDTO? { database.viewContext.channel(cid: cid) }

        // Assert that channel is not hidden
        XCTAssertEqual(channel?.isHidden, false)

        // Simulate `hideChannel(cid:, clearHistory:, completion:)` call
        let exp = expectation(description: "should hide channel")
        channelUpdater.hideChannel(cid: cid, clearHistory: true) { error in
            XCTAssertNil(error)
            exp.fulfill()
        }

        // Simulate API response with success
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.success(.init()))

        // In this case, timeout `10` should be used for both local and CI runs
        wait(for: [exp], timeout: 10)

        // Ensure channel is marked as hidden
        XCTAssertEqual(channel?.isHidden, true)
    }

    func test_hideChannel_errorResponse_isPropagatedToCompletion() throws {
        // Create a channel in DB
        let cid = ChannelId.unique

        try database.writeSynchronously {
            try $0.saveChannel(payload: self.dummyPayload(with: cid))
        }

        var channel: ChannelDTO? {
            database.viewContext.channel(cid: cid)
        }

        // Assert that channel is not hidden
        XCTAssertEqual(channel?.isHidden, false)

        // Simulate `hideChannel(cid:, clearHistory:, completion:)` call
        nonisolated(unsafe) var completionCalledError: Error?
        channelUpdater.hideChannel(cid: .unique, clearHistory: true) { completionCalledError = $0 }

        // Simulate API response with failure
        let error = TestError()
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.failure(error))

        // Assert the completion is called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)

        // Assert that channel is not hidden
        XCTAssertEqual(channel?.isHidden, false)
    }

    // MARK: - Show channel

    func test_showChannel_makesCorrectAPICall() {
        let channelID = ChannelId.unique

        // Simulate `showChannel(cid:)` call
        channelUpdater.showChannel(cid: channelID)

        // Assert correct endpoint is called
        let referenceEndpoint: Endpoint<EmptyResponse> = .showChannel(cid: channelID)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }

    func test_showChannel_successfulResponse_isPropagatedToCompletion() {
        // Simulate `showChannel(cid:)` call
        nonisolated(unsafe) var completionCalled = false
        channelUpdater.showChannel(cid: .unique) { error in
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

    func test_showChannel_errorResponse_isPropagatedToCompletion() {
        // Simulate `showChannel(cid:)` call
        nonisolated(unsafe) var completionCalledError: Error?
        channelUpdater.showChannel(cid: .unique) { completionCalledError = $0 }

        // Simulate API response with failure
        let error = TestError()
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.failure(error))

        // Assert the completion is called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }
    
    // MARK: - Load Members
    
    func test_loadMembersWithReads_makesCorrectAPICall() async throws {
        let channelID = ChannelId.unique
        let membersPagination = Pagination(pageSize: 25)
        try database.createChannel(cid: channelID)
        
        // Dummy response for exiting the API call
        apiClient.test_mockResponseResult(.success(ChannelPayload.dummy()))
        
        let result = try await channelUpdater.loadMembersWithReads(
            in: channelID,
            membersPagination: membersPagination,
            memberListSorting: []
        )
        XCTAssertEqual(0, result.count)
        
        // Assert correct endpoint is called
        var expectedQuery = ChannelQuery(
            cid: channelID,
            pageSize: 0,
            messagesPagination: MessagesPagination(pageSize: 0), // avoid default set of messages
            membersPagination: membersPagination,
            watchersLimit: 0 // avoid default set of watchers
        )
        expectedQuery.options = .state
        let referenceEndpoint: Endpoint<ChannelPayload> = .updateChannel(
            query: expectedQuery
        )
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }

    // MARK: - Add members

    func test_addMembers_makesCorrectAPICall() {
        let channelID = ChannelId.unique
        let userIds: Set<UserId> = Set([UserId.unique])

        // Simulate `addMembers(cid:, mute:, userIds:)` call
        channelUpdater.addMembers(
            cid: channelID,
            members: userIds.map { MemberInfo(userId: $0, extraData: nil) },
            hideHistory: false
        )

        // Assert correct endpoint is called
        let referenceEndpoint: Endpoint<EmptyResponse> = .addMembers(
            cid: channelID,
            members: userIds.map { MemberInfoRequest(userId: $0, extraData: nil) },
            hideHistory: false
        )
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }
    
    func test_addMembersWithMessage_makesCorrectAPICall() {
        let channelID = ChannelId.unique
        let userIds: Set<UserId> = Set([UserId.unique])
        let message: String = "Someone joined the channel"
        let senderId: String = .unique

        // Simulate `addMembers(cid:, mute:, userIds:)` call
        channelUpdater.addMembers(
            currentUserId: senderId,
            cid: channelID,
            members: userIds.map { MemberInfo(userId: $0, extraData: nil) },
            message: message,
            hideHistory: false
        )
        
        let body = apiClient.request_endpoint?.body?.encodable as? [String: AnyEncodable]
        let messageId = (body?["message"]?.encodable as? MessageRequestBody)?.id ?? .newUniqueId
        
        // Assert correct endpoint is called
        let messageRequestBody = MessageRequestBody(
            id: messageId,
            user: UserRequestBody(id: senderId, name: nil, imageURL: nil, extraData: [:]),
            text: message,
            type: nil,
            extraData: [:]
        )
        let referenceEndpoint: Endpoint<EmptyResponse> = .addMembers(
            cid: channelID,
            members: userIds.map { MemberInfoRequest(userId: $0, extraData: nil) },
            hideHistory: false,
            messagePayload: messageRequestBody
        )
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }
    
    func test_addMembersWithHideHistoryBefore_makesCorrectAPICall() {
        let channelID = ChannelId.unique
        let userIds: Set<UserId> = Set([UserId.unique])
        let hideHistoryBefore = Date()

        // Simulate `addMembers` call with hideHistoryBefore
        channelUpdater.addMembers(
            cid: channelID,
            members: userIds.map { MemberInfo(userId: $0, extraData: nil) },
            hideHistory: false,
            hideHistoryBefore: hideHistoryBefore
        )

        // Assert correct endpoint is called
        let referenceEndpoint: Endpoint<EmptyResponse> = .addMembers(
            cid: channelID,
            members: userIds.map { MemberInfoRequest(userId: $0, extraData: nil) },
            hideHistory: false,
            hideHistoryBefore: hideHistoryBefore
        )
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }
    
    func test_addMembersWithHideHistoryBefore_takesPrecedenceOverHideHistory() {
        let channelID = ChannelId.unique
        let userIds: Set<UserId> = Set([UserId.unique])
        let hideHistoryBefore = Date()

        // Simulate `addMembers` call with both hideHistory and hideHistoryBefore
        channelUpdater.addMembers(
            cid: channelID,
            members: userIds.map { MemberInfo(userId: $0, extraData: nil) },
            hideHistory: true,
            hideHistoryBefore: hideHistoryBefore
        )

        // Assert correct endpoint is called with hideHistoryBefore (precedence)
        let referenceEndpoint: Endpoint<EmptyResponse> = .addMembers(
            cid: channelID,
            members: userIds.map { MemberInfoRequest(userId: $0, extraData: nil) },
            hideHistory: true,
            hideHistoryBefore: hideHistoryBefore
        )
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
        
        // Verify the body contains hide_history_before and not hide_history
        let body = apiClient.request_endpoint?.body?.encodable as? [String: AnyEncodable]
        XCTAssertNotNil(body?["hide_history_before"])
        XCTAssertNil(body?["hide_history"])
    }

    func test_addMembers_successfulResponse_isPropagatedToCompletion() {
        let channelID = ChannelId.unique
        let userIds: Set<UserId> = Set([UserId.unique])

        // Simulate `addMembers(cid:, mute:, userIds:)` call
        nonisolated(unsafe) var completionCalled = false
        channelUpdater.addMembers(
            cid: channelID,
            members: userIds.map { MemberInfo(userId: $0, extraData: nil) },
            hideHistory: false
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

    func test_addMembers_errorResponse_isPropagatedToCompletion() {
        let channelID = ChannelId.unique
        let userIds: Set<UserId> = Set([UserId.unique])

        nonisolated(unsafe) var completionCalledError: Error?
        channelUpdater.addMembers(
            cid: channelID,
            members: userIds.map { MemberInfo(userId: $0, extraData: nil) },
            hideHistory: false
        ) {
            completionCalledError = $0
        }

        // Simulate API response with failure
        let error = TestError()
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.failure(error))

        // Assert the completion is called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }

    // MARK: - Invite members

    func test_inviteMembers_makesCorrectAPICall() {
        let channelID = ChannelId.unique
        let userIds: Set<UserId> = Set([UserId.unique])

        // Simulate `inviteMembers(cid:, mute:, userIds:)` call
        channelUpdater.inviteMembers(cid: channelID, userIds: userIds)

        // Assert correct endpoint is called
        let referenceEndpoint: Endpoint<EmptyResponse> = .inviteMembers(cid: channelID, userIds: userIds)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }

    func test_inviteMembers_successfulResponse_isPropagatedToCompletion() {
        let channelID = ChannelId.unique
        let userIds: Set<UserId> = Set([UserId.unique])

        // Simulate `inviteMembers(cid:, mute:, userIds:)` call
        nonisolated(unsafe) var completionCalled = false
        channelUpdater.inviteMembers(cid: channelID, userIds: userIds) { error in
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

    func test_inviteMembers_errorResponse_isPropagatedToCompletion() {
        let channelID = ChannelId.unique
        let userIds: Set<UserId> = Set([UserId.unique])

        // Simulate `inviteMembers(cid:, channelID:, userIds:)` call
        nonisolated(unsafe) var completionCalledError: Error?
        channelUpdater.inviteMembers(cid: channelID, userIds: userIds) { completionCalledError = $0 }

        // Simulate API response with failure
        let error = TestError()
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.failure(error))

        // Assert the completion is called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }

    // MARK: - Accept invite

    func test_acceptInvite_makesCorrectAPICall() {
        let channelID = ChannelId.unique
        let message = "Hooray"

        channelUpdater.acceptInvite(cid: channelID, message: message)

        // Assert correct endpoint is called
        let referenceEndpoint: Endpoint<EmptyResponse> = .acceptInvite(cid: channelID, message: message)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }

    func test_acceptInvite_successfulResponse_isPropagatedToCompletion() {
        let channelID = ChannelId.unique
        let message = "Hooray"

        // Simulate `acceptInvite(cid:, mute:, userIds:)` call
        nonisolated(unsafe) var completionCalled = false
        channelUpdater.acceptInvite(cid: channelID, message: message) { error in
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

    func test_acceptInvite_errorResponse_isPropagatedToCompletion() {
        let channelID = ChannelId.unique

        nonisolated(unsafe) var completionCalledError: Error?
        channelUpdater.acceptInvite(cid: channelID, message: "Hooray") { completionCalledError = $0 }

        // Simulate API response with failure
        let error = TestError()
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.failure(error))

        // Assert the completion is called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }

    // MARK: - Reject invite

    func test_rejectInvite_makesCorrectAPICall() {
        let channelID = ChannelId.unique

        channelUpdater.rejectInvite(cid: channelID)

        // Assert correct endpoint is called
        let referenceEndpoint: Endpoint<EmptyResponse> = .rejectInvite(cid: channelID)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }

    func test_rejectInvite_successfulResponse_isPropagatedToCompletion() {
        let channelID = ChannelId.unique

        // Simulate `rejectInvite(cid:, mute:, userIds:)` call
        nonisolated(unsafe) var completionCalled = false
        channelUpdater.rejectInvite(cid: channelID) { error in
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

    func test_rejectInvite_errorResponse_isPropagatedToCompletion() {
        let channelID = ChannelId.unique

        nonisolated(unsafe) var completionCalledError: Error?
        channelUpdater.rejectInvite(cid: channelID) { completionCalledError = $0 }

        // Simulate API response with failure
        let error = TestError()
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.failure(error))

        // Assert the completion is called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }

    // MARK: - Remove members

    func test_removeMembers_makesCorrectAPICall() {
        let channelID = ChannelId.unique
        let userIds: Set<UserId> = Set([UserId.unique])

        // Simulate `removeMembers(cid:, mute:, userIds:)` call
        channelUpdater.removeMembers(cid: channelID, userIds: userIds)

        // Assert correct endpoint is called
        let referenceEndpoint: Endpoint<EmptyResponse> = .removeMembers(cid: channelID, userIds: userIds)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }
    
    func test_removeMembersWithMessage_makesCorrectAPICall() {
        let channelID = ChannelId.unique
        let userIds: Set<UserId> = Set([UserId.unique])
        let message: String = "Someone left the channel"
        let senderId: String = .unique

        // Simulate `removeMembers(cid:, mute:, userIds:)` call
        channelUpdater.removeMembers(
            currentUserId: senderId,
            cid: channelID,
            userIds: userIds,
            message: message
        )
        
        let body = apiClient.request_endpoint?.body?.encodable as? [String: AnyEncodable]
        let messageId = (body?["message"]?.encodable as? MessageRequestBody)?.id ?? .newUniqueId
        
        // Assert correct endpoint is called
        let messageRequestBody = MessageRequestBody(
            id: messageId,
            user: UserRequestBody(id: senderId, name: nil, imageURL: nil, extraData: [:]),
            text: message,
            type: nil,
            extraData: [:]
        )
        let referenceEndpoint: Endpoint<EmptyResponse> = .removeMembers(
            cid: channelID,
            userIds: userIds,
            messagePayload: messageRequestBody
        )
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }

    func test_removeMembers_successfulResponse_isPropagatedToCompletion() {
        let channelID = ChannelId.unique
        let userIds: Set<UserId> = Set([UserId.unique])

        // Simulate `removeMembers(cid:, mute:, userIds:)` call
        nonisolated(unsafe) var completionCalled = false
        channelUpdater.removeMembers(cid: channelID, userIds: userIds) { error in
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

    func test_removeMembers_errorResponse_isPropagatedToCompletion() {
        let channelID = ChannelId.unique
        let userIds: Set<UserId> = Set([UserId.unique])

        // Simulate `removeMembers(cid:, mute:, completion:)` call
        nonisolated(unsafe) var completionCalledError: Error?
        channelUpdater.removeMembers(cid: channelID, userIds: userIds) { completionCalledError = $0 }

        // Simulate API response with failure
        let error = TestError()
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.failure(error))

        // Assert the completion is called with the error
        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }

    // MARK: - Mark channel as read

    func test_markRead_makesCorrectAPICall() {
        let cid = ChannelId.unique
        let userId = UserId.unique

        channelUpdater.markRead(cid: cid, userId: userId)

        XCTAssertEqual(channelRepository.markReadCid, cid)
        XCTAssertEqual(channelRepository.markReadUserId, userId)
    }

    func test_markRead_successfulResponse_isPropagatedToCompletion() {
        let expectation = self.expectation(description: "markRead completes")
        nonisolated(unsafe) var receivedError: Error?

        channelRepository.markReadResult = .success(())
        channelUpdater.markRead(cid: .unique, userId: .unique) { error in
            receivedError = error
            expectation.fulfill()
        }

        waitForExpectations(timeout: defaultTimeout)
        XCTAssertNil(receivedError)
    }

    func test_markRead_errorResponse_isPropagatedToCompletion() {
        let expectation = self.expectation(description: "markRead completes")
        let mockedError = TestError()
        nonisolated(unsafe) var receivedError: Error?

        channelRepository.markReadResult = .failure(mockedError)
        channelUpdater.markRead(cid: .unique, userId: .unique) { error in
            receivedError = error
            expectation.fulfill()
        }

        waitForExpectations(timeout: defaultTimeout)
        XCTAssertEqual(receivedError, mockedError)
    }

    // MARK: - Mark channel as unread

    func test_markUnread_makesCorrectAPICall() {
        let cid = ChannelId.unique
        let userId = UserId.unique
        let messageId = MessageId.unique
        let lastReadMessageId = MessageId.unique

        channelUpdater.markUnread(cid: cid, userId: userId, from: .messageId(messageId), lastReadMessageId: lastReadMessageId)

        XCTAssertEqual(channelRepository.markUnreadCid, cid)
        XCTAssertEqual(channelRepository.markUnreadUserId, userId)
        XCTAssertEqual(channelRepository.markUnreadCriteria, .messageId(messageId))
        XCTAssertEqual(channelRepository.markUnreadLastReadMessageId, lastReadMessageId)
    }

    func test_markUnread_successfulResponse_isPropagatedToCompletion() {
        let expectation = self.expectation(description: "markUnread completes")
        nonisolated(unsafe) var receivedError: Error?

        channelRepository.markUnreadResult = .success(.mock(cid: .unique))
        channelUpdater.markUnread(cid: .unique, userId: .unique, from: .messageId(.unique), lastReadMessageId: .unique) { result in
            receivedError = result.error
            expectation.fulfill()
        }

        waitForExpectations(timeout: defaultTimeout)
        XCTAssertNil(receivedError)
    }

    func test_markUnread_errorResponse_isPropagatedToCompletion() {
        let expectation = self.expectation(description: "markUnread completes")
        let mockedError = TestError()
        nonisolated(unsafe) var receivedError: Error?

        channelRepository.markUnreadResult = .failure(mockedError)
        channelUpdater.markUnread(cid: .unique, userId: .unique, from: .messageId(.unique), lastReadMessageId: .unique) { result in
            receivedError = result.error
            expectation.fulfill()
        }

        waitForExpectations(timeout: defaultTimeout)
        XCTAssertEqual(receivedError, mockedError)
    }

    // MARK: - Enable slow mode (cooldown)

    func test_enableSlowMode_makesCorrectAPICall() {
        let cid = ChannelId.unique
        let cooldownDuration = Int.random(in: 0...120)

        channelUpdater.enableSlowMode(cid: cid, cooldownDuration: cooldownDuration)

        let referenceEndpoint = Endpoint<EmptyResponse>.enableSlowMode(cid: cid, cooldownDuration: cooldownDuration)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }

    func test_enableSlowMode_successfulResponse_isPropagatedToCompletion() {
        nonisolated(unsafe) var completionCalled = false
        channelUpdater.enableSlowMode(cid: .unique, cooldownDuration: .random(in: 0...120)) { error in
            XCTAssertNil(error)
            completionCalled = true
        }

        XCTAssertFalse(completionCalled)

        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.success(.init()))

        AssertAsync.willBeTrue(completionCalled)
    }

    func test_enableSlowMode_errorResponse_isPropagatedToCompletion() {
        nonisolated(unsafe) var completionCalledError: Error?
        channelUpdater.enableSlowMode(cid: .unique, cooldownDuration: .random(in: 0...120)) { completionCalledError = $0 }

        let error = TestError()
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.failure(error))

        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }

    // MARK: - Disable slow mode

    func test_disableSlowMode_makesCorrectAPICall() {
        let cid = ChannelId.unique

        channelUpdater.disableSlowMode(cid: cid) { _ in }

        // Assert that disableSlowMode calls enableSlowMode endpoint with cooldownDuration: 0
        let referenceEndpoint = Endpoint<EmptyResponse>.enableSlowMode(cid: cid, cooldownDuration: 0)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }

    func test_disableSlowMode_successfulResponse_isPropagatedToCompletion() {
        var completionCalled = false
        channelUpdater.disableSlowMode(cid: .unique) { error in
            XCTAssertNil(error)
            completionCalled = true
        }

        XCTAssertFalse(completionCalled)

        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.success(.init()))

        AssertAsync.willBeTrue(completionCalled)
    }

    func test_disableSlowMode_errorResponse_isPropagatedToCompletion() {
        var completionCalledError: Error?
        channelUpdater.disableSlowMode(cid: .unique) { completionCalledError = $0 }

        let error = TestError()
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.failure(error))

        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }

    // MARK: - Start watching

    func test_startWatching_makesCorrectAPICall() {
        let cid = ChannelId.unique

        channelUpdater.startWatching(cid: cid, isInRecoveryMode: false)

        var query = ChannelQuery(cid: cid)
        query.options = .all
        let referenceEndpoint: Endpoint<ChannelPayload> = .updateChannel(query: query)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }

    func test_startWatchingRecovery_makesCorrectAPICall() {
        let cid = ChannelId.unique

        channelUpdater.startWatching(cid: cid, isInRecoveryMode: true)

        var query = ChannelQuery(cid: cid)
        query.options = .all
        let referenceEndpoint: Endpoint<ChannelPayload> = .updateChannel(query: query)
        XCTAssertEqual(apiClient.recoveryRequest_endpoint, AnyEndpoint(referenceEndpoint))
    }

    func test_startWatching_successfulResponse_isPropagatedToCompletion() {
        nonisolated(unsafe) var completionCalled = false
        let cid = ChannelId.unique
        channelUpdater.startWatching(cid: cid, isInRecoveryMode: false) { error in
            XCTAssertNil(error)
            completionCalled = true
        }

        XCTAssertFalse(completionCalled)

        // Simulate API response with channel data
        let payload = dummyPayload(with: cid)
        apiClient.test_simulateResponse(.success(payload))

        AssertAsync.willBeTrue(completionCalled)
    }

    func test_startWatchingRecovery_successfulResponse_isPropagatedToCompletion() {
        nonisolated(unsafe) var completionCalled = false
        let cid = ChannelId.unique
        channelUpdater.startWatching(cid: cid, isInRecoveryMode: true) { error in
            XCTAssertNil(error)
            completionCalled = true
        }

        XCTAssertFalse(completionCalled)

        // Simulate API response with channel data
        let payload = dummyPayload(with: cid)
        apiClient.test_simulateRecoveryResponse(.success(payload))

        AssertAsync.willBeTrue(completionCalled)
    }

    func test_startWatching_errorResponse_isPropagatedToCompletion() {
        nonisolated(unsafe) var completionCalledError: Error?
        channelUpdater.startWatching(cid: .unique, isInRecoveryMode: false) { completionCalledError = $0 }

        let error = TestError()
        apiClient.test_simulateResponse(Result<ChannelPayload, Error>.failure(error))

        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }

    func test_startWatchingRecovery_errorResponse_isPropagatedToCompletion() {
        nonisolated(unsafe) var completionCalledError: Error?
        channelUpdater.startWatching(cid: .unique, isInRecoveryMode: true) { completionCalledError = $0 }

        let error = TestError()
        apiClient.test_simulateRecoveryResponse(Result<ChannelPayload, Error>.failure(error))

        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }

    // MARK: - Stop watching

    func test_stopWatching_makesCorrectAPICall() {
        let cid = ChannelId.unique

        channelUpdater.stopWatching(cid: cid)

        let referenceEndpoint: Endpoint<EmptyResponse> = .stopWatching(cid: cid)

        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }

    func test_stopWatching_successfulResponse_isPropagatedToCompletion() {
        nonisolated(unsafe) var completionCalled = false
        let cid = ChannelId.unique
        channelUpdater.stopWatching(cid: cid) { error in
            XCTAssertNil(error)
            completionCalled = true
        }

        XCTAssertFalse(completionCalled)

        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.success(.init()))

        AssertAsync.willBeTrue(completionCalled)
    }

    func test_stopWatching_errorResponse_isPropagatedToCompletion() {
        nonisolated(unsafe) var completionCalledError: Error?
        channelUpdater.stopWatching(cid: .unique) { completionCalledError = $0 }

        let error = TestError()
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.failure(error))

        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }

    // MARK: - Channel watchers

    func test_channelWatchers_makesCorrectAPICall() {
        let cid = ChannelId.unique
        let query = ChannelWatcherListQuery(cid: cid)

        channelUpdater.channelWatchers(query: query)

        let referenceEndpoint: Endpoint<ChannelPayload> = .channelWatchers(query: query)

        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }

    func test_channelWatchers_successfulResponse_isPropagatedToCompletion() {
        nonisolated(unsafe) var completionCalled = false
        let cid = ChannelId.unique
        let query = ChannelWatcherListQuery(cid: cid)
        channelUpdater.channelWatchers(query: query) { result in
            XCTAssertNil(result.error)
            completionCalled = true
        }

        XCTAssertFalse(completionCalled)

        apiClient.test_simulateResponse(
            Result<ChannelPayload, Error>.success(dummyPayload(with: cid))
        )

        AssertAsync.willBeTrue(completionCalled)
    }

    func test_channelWatchers_errorResponse_isPropagatedToCompletion() {
        nonisolated(unsafe) var completionCalledError: Error?
        let query = ChannelWatcherListQuery(cid: .unique)
        channelUpdater.channelWatchers(query: query) { completionCalledError = $0.error }

        let error = TestError()
        apiClient.test_simulateResponse(Result<ChannelPayload, Error>.failure(error))

        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }

    func test_channelWatchers_clearsWatchers_whenFirstPageIsRequestedAndEmpty() throws {
        // Create a dummy channel
        let cid = ChannelId.unique
        try database.createChannel(cid: cid, withMessages: false)

        var channel: ChatChannel? {
            try? database.viewContext.channel(cid: cid)?.asModel()
        }

        // Assert that the dummy channel has a watcher
        assert(!(channel?.lastActiveWatchers.isEmpty ?? true))

        // Save first watcher's id so we can compare later
        let firstWatcherId = channel?.lastActiveWatchers.first?.id

        // Call `channelWatchers` for this channel
        // This query doesn't provide any `offset` so it's requesting the first page of watchers
        let query = ChannelWatcherListQuery(cid: cid)
        let completionCalled = expectation(description: "completion called")
        channelUpdater.channelWatchers(query: query) { _ in completionCalled.fulfill() }

        // Simulate successful response
        apiClient.test_simulateResponse(
            Result<ChannelPayload, Error>.success(dummyPayload(with: cid, watchers: []))
        )

        wait(for: [completionCalled], timeout: defaultTimeout)

        // Assert that the old watcher is replaced
        AssertAsync {
            Assert.willBeFalse(channel?.lastActiveWatchers.contains(where: { $0.id == firstWatcherId }) ?? true)
        }
    }

    // MARK: - Freeze channel

    func test_freezeChannel_makesCorrectAPICall() {
        let cid = ChannelId.unique
        let freeze = Bool.random()

        channelUpdater.freezeChannel(freeze, cid: cid)

        let referenceEndpoint: Endpoint<EmptyResponse> = .freezeChannel(freeze, cid: cid)

        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(referenceEndpoint))
    }

    func test_freezeChannel_successfulResponse_isPropagatedToCompletion() {
        nonisolated(unsafe) var completionCalled = false
        let cid = ChannelId.unique
        let freeze = Bool.random()
        channelUpdater.freezeChannel(freeze, cid: cid) { error in
            XCTAssertNil(error)
            completionCalled = true
        }

        XCTAssertFalse(completionCalled)

        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.success(.init()))

        AssertAsync.willBeTrue(completionCalled)
    }

    func test_freezeChannel_errorResponse_isPropagatedToCompletion() {
        nonisolated(unsafe) var completionCalledError: Error?
        channelUpdater.freezeChannel(.random(), cid: .unique) { completionCalledError = $0 }

        let error = TestError()
        apiClient.test_simulateResponse(Result<EmptyResponse, Error>.failure(error))

        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }

    // MARK: - UploadFile

    func test_uploadFile_makesCorrectAPICall() {
        let cid = ChannelId.unique
        let type = AttachmentType.image

        XCTAssertNil(apiClient.uploadFile_attachment)

        channelUpdater.uploadFile(type: type, localFileURL: .localYodaImage, cid: cid) { _ in }

        XCTAssertNotNil(apiClient.uploadFile_attachment)
    }

    func test_uploadFile_successfulResponse_isPropagatedToCompletion() {
        let cid = ChannelId.unique
        let type = AttachmentType.image

        nonisolated(unsafe) var completionCalled = false
        channelUpdater.uploadFile(type: type, localFileURL: .localYodaImage, cid: cid) { result in
            do {
                let uploadedAttachment = try result.get()
                XCTAssertEqual(uploadedAttachment.remoteURL, .localYodaQuote)
            } catch {
                XCTFail("Error \(error)")
            }
            completionCalled = true
        }

        let attachment = UploadedAttachment(
            attachment: ChatMessageImageAttachment.mock(id: .unique).asAnyAttachment,
            remoteURL: .localYodaQuote,
            thumbnailURL: nil
        )
        apiClient.uploadFile_completion?(.success(attachment))

        AssertAsync.willBeTrue(completionCalled)
    }

    func test_uploadFile_errorResponse_isPropagatedToCompletion() {
        let cid = ChannelId.unique
        let type = AttachmentType.image

        nonisolated(unsafe) var completionCalledError: Error?
        channelUpdater.uploadFile(type: type, localFileURL: .localYodaImage, cid: cid) { result in
            do {
                _ = try result.get()
                XCTFail("Error: Shouldn't succeed")
            } catch {
                completionCalledError = error
            }
        }

        let error = TestError()
        apiClient.uploadFile_completion?(.failure(error))

        AssertAsync.willBeEqual(completionCalledError as? TestError, error)
    }

    // MARK: - Load pinned messages

    func test_loadPinnedMessages_makesCorrectAPICall() {
        // Create channel id
        let cid = ChannelId.unique

        // Create query
        let query = PinnedMessagesQuery(pageSize: 10, pagination: .aroundMessage(.unique))

        // Simulate `loadPinnedMessages` call
        channelUpdater.loadPinnedMessages(in: cid, query: query, completion: { _ in })

        // Create expected endpoint
        let endpoint: Endpoint<PinnedMessagesPayload> = .pinnedMessages(cid: cid, query: query)

        // Assert correct endpoint is called
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(endpoint))
    }

    func test_loadPinnedMessages_propagatesResultsToCompletion() {
        // Create channel id
        let cid = ChannelId.unique

        try! database.writeSynchronously { session in
            try session.saveChannel(payload: .dummy(cid: cid), query: nil, cache: nil)
        }

        // Create query
        let query = PinnedMessagesQuery(pageSize: 10, pagination: .aroundMessage(.unique))

        // Simulate `loadPinnedMessages` call
        nonisolated(unsafe) var completionPayload: [ChatMessage]?
        channelUpdater.loadPinnedMessages(in: cid, query: query) {
            completionPayload = try? $0.get()
        }

        // Simulate API response
        let payload = PinnedMessagesPayload(messages: [
            .dummy(messageId: .unique, authorUserId: .unique),
            .dummy(messageId: .unique, authorUserId: .unique),
            .dummy(messageId: .unique, authorUserId: .unique)
        ])

        apiClient.test_simulateResponse(Result<PinnedMessagesPayload, Error>.success(payload))

        // Assert payload is propagated to completion
        AssertAsync.willBeEqual(
            completionPayload?.map(\.id),
            payload.messages.map(\.id)
        )
    }

    func test_loadPinnedMessages_propagatesErrorToCompletion() {
        // Simulate `loadPinnedMessages` call
        nonisolated(unsafe) var completionError: Error?
        channelUpdater.loadPinnedMessages(in: .unique, query: .init(pageSize: 10, pagination: nil)) {
            completionError = $0.error
        }

        // Simulate API error
        let error = TestError()
        apiClient.test_simulateResponse(Result<PinnedMessagesPayload, Error>.failure(error))

        // Assert error is propagated to completion
        AssertAsync.willBeEqual(completionError as? TestError, error)
    }

    func test_loadPinnedMessages_doesNotRetainUpdater() {
        // Simulate `loadPinnedMessages` call
        channelUpdater.loadPinnedMessages(in: .unique, query: .init(pageSize: 10, pagination: nil)) { _ in }

        // Assert updater can be released
        AssertAsync.canBeReleased(&channelUpdater)
    }

    // MARK: - enrichUrl

    func test_enrichUrl_whenSuccess() {
        let exp = expectation(description: "enrichUrl completes")
        let url = URL(string: "www.google.com")!
        nonisolated(unsafe) var linkPayload: LinkAttachmentPayload?
        channelUpdater.enrichUrl(url) { result in
            XCTAssertNil(result.error)
            linkPayload = result.value
            exp.fulfill()
        }

        apiClient.test_simulateResponse(.success(LinkAttachmentPayload(
            originalURL: url,
            title: "Google"
        )))

        wait(for: [exp], timeout: defaultTimeout)

        XCTAssertEqual(linkPayload?.originalURL, url)
        XCTAssertEqual(linkPayload?.title, "Google")
    }

    func test_enrichUrl_whenFailure() {
        let exp = expectation(description: "enrichUrl completes")
        let url = URL(string: "www.google.com")!
        nonisolated(unsafe) var linkPayload: LinkAttachmentPayload?
        channelUpdater.enrichUrl(url) { result in
            XCTAssertNotNil(result.error)
            linkPayload = result.value
            exp.fulfill()
        }

        apiClient
            .test_simulateResponse(Result<LinkAttachmentPayload, Error>.failure(ClientError()))

        wait(for: [exp], timeout: defaultTimeout)

        XCTAssertNil(linkPayload)
    }

    // MARK: - setPushPreference

    func test_setPushPreference_makesCorrectAPICall() {
        // GIVEN
        let cid: ChannelId = .unique
        let preference = PushPreferenceRequestPayload(
            chatLevel: "mentions",
            channelId: cid.rawValue,
            disabledUntil: nil,
            removeDisable: true
        )

        // WHEN
        channelUpdater.setPushPreference(preference, cid: cid) { _ in }

        // THEN
        let expectedEndpoint: Endpoint<PushPreferencesPayloadResponse> = .pushPreferences([preference])
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }

    func test_setPushPreference_successfulResponse_savesToDatabase() {
        // GIVEN
        let cid: ChannelId = .unique
        let preference = PushPreferenceRequestPayload(
            chatLevel: "all",
            channelId: cid.rawValue,
            disabledUntil: nil,
            removeDisable: true
        )

        let response = PushPreferencesPayloadResponse(
            userPreferences: [:],
            channelPreferences: [
                "userId": [
                    cid.rawValue: PushPreferencePayload(
                        chatLevel: "all",
                        disabledUntil: nil
                    )
                ]
            ]
        )

        // WHEN
        var completionCalled = false
        channelUpdater.setPushPreference(preference, cid: cid) { result in
            XCTAssertNil(result.error)
            completionCalled = true
        }

        apiClient.test_simulateResponse(.success(response))

        // THEN
        AssertAsync.willBeTrue(completionCalled)
    }

    func test_setPushPreference_propagatesNetworkError() {
        // GIVEN
        let cid: ChannelId = .unique
        let preference = PushPreferenceRequestPayload(
            chatLevel: "mentions",
            channelId: cid.rawValue,
            disabledUntil: nil,
            removeDisable: true
        )

        // WHEN
        var completionError: Error?
        channelUpdater.setPushPreference(preference, cid: cid) { result in
            if case let .failure(error) = result {
                completionError = error
            }
        }

        let error = TestError()
        apiClient.test_simulateResponse(Result<PushPreferencesPayloadResponse, Error>.failure(error))

        // THEN
        AssertAsync.willBeEqual(completionError as? TestError, error)
    }

    func test_setPushPreference_whenNoChannelPreferences_returnsError() {
        // GIVEN
        let cid: ChannelId = .unique
        let preference = PushPreferenceRequestPayload(
            chatLevel: "mentions",
            channelId: cid.rawValue,
            disabledUntil: nil,
            removeDisable: true
        )

        let response = PushPreferencesPayloadResponse(
            userPreferences: [:],
            channelPreferences: [:]
        )

        // WHEN
        var completionError: Error?
        channelUpdater.setPushPreference(preference, cid: cid) { result in
            if case let .failure(error) = result {
                completionError = error
            }
        }

        apiClient.test_simulateResponse(.success(response))

        // THEN
        AssertAsync.willBeTrue(completionError is ClientError.ChannelDoesNotExist)
    }
}
