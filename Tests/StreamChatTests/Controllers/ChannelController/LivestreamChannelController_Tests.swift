//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

/// Tests for `LivestreamChannelController` focused on controller-specific behaviour:
/// API wiring, delegate forwarding, sync repository tracking, manual event
/// registration, and forwarding to the underlying `LivestreamChannelHandler`.
///
/// Handler-internal behaviour (event handling, pagination state, message pruning,
/// typing aggregation, cooldown, etc.) is exercised in
/// `LivestreamChannelHandler_Tests`.
final class LivestreamChannelController_Tests: XCTestCase {
    fileprivate var env: TestEnvironment!

    var client: ChatClient_Mock!
    var channelQuery: ChannelQuery!
    var controller: LivestreamChannelController!

    override func setUp() {
        super.setUp()

        env = TestEnvironment()
        client = ChatClient.mock(config: ChatClient_Mock.defaultMockedConfig)
        channelQuery = ChannelQuery(cid: .unique)
        controller = LivestreamChannelController(
            channelQuery: channelQuery,
            client: client
        )
    }

    override func tearDown() {
        client?.cleanUp()
        env?.apiClient?.cleanUp()
        env = nil

        AssertAsync {
            Assert.canBeReleased(&controller)
            Assert.canBeReleased(&client)
            Assert.canBeReleased(&env)
        }

        channelQuery = nil

        super.tearDown()
    }
}

// MARK: - TestEnvironment

extension LivestreamChannelController_Tests {
    fileprivate final class TestEnvironment {
        var apiClient: APIClient_Spy?
        var appStateObserver: MockAppStateObserver?

        init() {
            apiClient = APIClient_Spy()
            appStateObserver = MockAppStateObserver()
        }
    }
}

// MARK: - Initialization Tests

extension LivestreamChannelController_Tests {
    func test_init_assignsValuesCorrectly() {
        let channelQuery = ChannelQuery(cid: .unique)
        let client = ChatClient.mock()
        let controller = LivestreamChannelController(
            channelQuery: channelQuery,
            client: client
        )

        XCTAssertEqual(controller.channelQuery.cid, channelQuery.cid)
        XCTAssert(controller.client === client)
        XCTAssertEqual(controller.cid, channelQuery.cid)
        XCTAssertNil(controller.channel)
        XCTAssertTrue(controller.messages.isEmpty)
        XCTAssertFalse(controller.isPaused)
        XCTAssertEqual(controller.skippedMessagesAmount, 0)
        XCTAssertTrue(controller.loadInitialMessagesFromCache)
        XCTAssertFalse(controller.countSkippedMessagesWhenPaused)
        XCTAssertNil(controller.maxMessageLimitOptions)
    }

    func test_init_registersForEventHandling() {
        let cid = ChannelId.unique
        let channelQuery = ChannelQuery(cid: cid)
        let client = ChatClient_Mock.mock()
        let eventNotificationCenter = EventNotificationCenter_Mock(
            database: DatabaseContainer_Spy()
        )
        client.mockedEventNotificationCenter = eventNotificationCenter

        _ = LivestreamChannelController(
            channelQuery: channelQuery,
            client: client
        )

        XCTAssertEqual(eventNotificationCenter.registerManualEventHandling_callCount, 1)
        XCTAssertEqual(eventNotificationCenter.registerManualEventHandling_calledWith, cid)
    }

    func test_deinit_unregistersEventHandling() {
        let cid = ChannelId.unique
        let channelQuery = ChannelQuery(cid: cid)
        let client = ChatClient_Mock.mock()
        let eventNotificationCenter = EventNotificationCenter_Mock(
            database: DatabaseContainer_Spy()
        )
        client.mockedEventNotificationCenter = eventNotificationCenter

        controller = LivestreamChannelController(
            channelQuery: channelQuery,
            client: client
        )

        controller = nil

        XCTAssertEqual(eventNotificationCenter.unregisterManualEventHandling_callCount, 1)
        XCTAssertEqual(eventNotificationCenter.unregisterManualEventHandling_calledWith, cid)
    }
}

// MARK: - Pagination Properties Tests

extension LivestreamChannelController_Tests {
    func test_hasLoadedAllNextMessages_whenMessagesArrayIsEmpty_thenReturnsTrue() {
        let result = controller.hasLoadedAllNextMessages

        XCTAssertTrue(result)
    }
}

// MARK: - Synchronize Tests

extension LivestreamChannelController_Tests {
    func test_synchronize_callsUpdaterWithCorrectParameters() {
        let mockUpdater = makeMockUpdater()
        controller = LivestreamChannelController(
            channelQuery: channelQuery,
            client: client,
            updater: mockUpdater
        )

        controller.synchronize()

        XCTAssertEqual(mockUpdater.update_callCount, 1)

        mockUpdater.cleanUp()
    }

    func test_synchronize_withCache_loadsInitialDataFromCache() {
        let cid = ChannelId.unique
        controller = LivestreamChannelController(
            channelQuery: ChannelQuery(cid: cid),
            client: client
        )
        controller.loadInitialMessagesFromCache = true

        let channelPayload = ChannelPayload.dummy(
            channel: .dummy(cid: cid),
            messages: [.dummy(), .dummy()]
        )

        try! client.databaseContainer.writeSynchronously { session in
            try session.saveChannel(payload: channelPayload)
        }

        controller.synchronize()

        XCTAssertNotNil(controller.channel)
        XCTAssertEqual(controller.channel?.cid, cid)
        XCTAssertEqual(controller.messages.count, 2)
    }

    func test_synchronize_withoutCache_doesNotLoadFromCache() {
        let cid = ChannelId.unique
        controller = LivestreamChannelController(
            channelQuery: ChannelQuery(cid: cid),
            client: client
        )
        controller.loadInitialMessagesFromCache = false

        let channelPayload = ChannelPayload.dummy(
            channel: .dummy(cid: cid),
            messages: [.dummy(), .dummy()]
        )

        try! client.databaseContainer.writeSynchronously { session in
            try session.saveChannel(payload: channelPayload)
        }

        controller.synchronize()

        XCTAssertNil(controller.channel)
        XCTAssertTrue(controller.messages.isEmpty)
    }

    func test_synchronize_successfulResponse_updatesChannelAndMessages() {
        let expectation = self.expectation(description: "Synchronize completes")
        nonisolated(unsafe) var synchronizeError: Error?

        let mockUpdater = makeMockUpdater()
        controller = LivestreamChannelController(
            channelQuery: channelQuery,
            client: client,
            updater: mockUpdater
        )

        controller.synchronize { error in
            synchronizeError = error
            expectation.fulfill()
        }

        let cid = ChannelId.unique
        let channelPayload = ChannelPayload.dummy(
            channel: .dummy(cid: cid),
            messages: [
                .dummy(messageId: "1", text: "Message 1"),
                .dummy(messageId: "2", text: "Message 2")
            ]
        )
        mockUpdater.update_completion?(.success(channelPayload))

        waitForExpectations(timeout: defaultTimeout)

        XCTAssertNil(synchronizeError)
        XCTAssertNotNil(controller.channel)
        XCTAssertEqual(controller.channel?.cid, cid)
        XCTAssertEqual(controller.messages.count, 2)
        XCTAssertEqual(controller.messages.map(\.id), ["2", "1"])

        mockUpdater.cleanUp()
    }

    func test_synchronize_failedResponse_callsCompletionWithError() {
        let expectation = self.expectation(description: "Synchronize completes")
        nonisolated(unsafe) var synchronizeError: Error?
        let testError = TestError()

        let mockUpdater = makeMockUpdater()
        controller = LivestreamChannelController(
            channelQuery: channelQuery,
            client: client,
            updater: mockUpdater
        )

        controller.synchronize { error in
            synchronizeError = error
            expectation.fulfill()
        }

        mockUpdater.update_completion?(.failure(testError))

        waitForExpectations(timeout: defaultTimeout)

        XCTAssertEqual(synchronizeError as? TestError, testError)
        XCTAssertNil(controller.channel)
        XCTAssertTrue(controller.messages.isEmpty)

        mockUpdater.cleanUp()
    }
}

// MARK: - Message Loading Tests

extension LivestreamChannelController_Tests {
    func test_loadPreviousMessages_withNoMessages_callsCompletionWithError() {
        let expectation = self.expectation(description: "Load previous messages completes")
        nonisolated(unsafe) var loadError: Error?

        controller.loadPreviousMessages { error in
            loadError = error
            expectation.fulfill()
        }

        waitForExpectations(timeout: defaultTimeout)

        XCTAssert(loadError is ClientError.ChannelEmptyMessages)
    }

    func test_loadPreviousMessages_makesCorrectAPICall() throws {
        controller.synchronize()
        let channelPayload = ChannelPayload.dummy(messages: [.dummy(messageId: "message1")])
        client.mockAPIClient.test_simulateResponse(.success(channelPayload))

        let apiClient = client.mockAPIClient

        controller.loadPreviousMessages(before: "specific-message-id", limit: 50)

        let expectedPagination = MessagesPagination(pageSize: 50, parameter: .lessThan("specific-message-id"))
        var expectedQuery = try XCTUnwrap(channelQuery)
        expectedQuery.pagination = expectedPagination
        let expectedEndpoint = Endpoint<ChannelPayload>.updateChannel(query: expectedQuery)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }

    func test_loadPreviousMessages_usesDefaultLimit() throws {
        controller.synchronize()
        let channelPayload = ChannelPayload.dummy(messages: [.dummy(messageId: "message1")])
        client.mockAPIClient.test_simulateResponse(.success(channelPayload))

        let apiClient = client.mockAPIClient

        controller.loadPreviousMessages(before: "specific-message-id")

        let expectedPagination = MessagesPagination(pageSize: 25, parameter: .lessThan("specific-message-id"))
        var expectedQuery = try XCTUnwrap(channelQuery)
        expectedQuery.pagination = expectedPagination
        let expectedEndpoint = Endpoint<ChannelPayload>.updateChannel(query: expectedQuery)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }

    func test_loadNextMessages_successfulResponse_prependsMessages() {
        let mockPaginationStateHandler = MockPaginationStateHandler()
        mockPaginationStateHandler.state = .init(
            newestFetchedMessage: .dummy(),
            hasLoadedAllNextMessages: false,
            hasLoadedAllPreviousMessages: false,
            isLoadingNextMessages: false,
            isLoadingPreviousMessages: false,
            isLoadingMiddleMessages: false
        )
        controller = LivestreamChannelController(
            channelQuery: channelQuery,
            client: client,
            paginationStateHandler: mockPaginationStateHandler
        )

        let initialChannelPayload = ChannelPayload.dummy(
            channel: .dummy(cid: channelQuery.cid!),
            messages: [
                .dummy(messageId: "old1"),
                .dummy(messageId: "old2")
            ]
        )
        try! client.databaseContainer.writeSynchronously { session in
            try session.saveChannel(payload: initialChannelPayload)
        }
        controller.synchronize()

        let expectation = self.expectation(description: "Load next messages completes")
        nonisolated(unsafe) var loadError: Error?

        controller.loadNextMessages(after: "old1") { error in
            loadError = error
            expectation.fulfill()
        }

        let channelPayload = ChannelPayload.dummy(
            messages: [
                .dummy(messageId: "new1", text: "New Message 1"),
                .dummy(messageId: "new2", text: "New Message 2")
            ]
        )
        client.mockAPIClient.test_simulateResponse(.success(channelPayload))

        waitForExpectations(timeout: defaultTimeout)

        XCTAssertNil(loadError)
        XCTAssertEqual(controller.messages.count, 4)
        XCTAssertEqual(Set(controller.messages.map(\.id)), Set(["new2", "new1", "old2", "old1"]))
    }

    func test_loadPageAroundMessageId_makesCorrectAPICall() throws {
        let apiClient = client.mockAPIClient

        controller.loadPageAroundMessageId("target-message-id", limit: 40)

        let expectedPagination = MessagesPagination(pageSize: 40, parameter: .around("target-message-id"))
        var expectedQuery = try XCTUnwrap(channelQuery)
        expectedQuery.pagination = expectedPagination
        let expectedEndpoint = Endpoint<ChannelPayload>.updateChannel(query: expectedQuery)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }

    func test_loadFirstPage_makesCorrectAPICall() throws {
        let apiClient = client.mockAPIClient

        controller.loadFirstPage()

        let expectedPagination = MessagesPagination(pageSize: 25, parameter: nil)
        var expectedQuery = try XCTUnwrap(channelQuery)
        expectedQuery.pagination = expectedPagination
        let expectedEndpoint = Endpoint<ChannelPayload>.updateChannel(query: expectedQuery)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }

    func test_loadPreviousMessages_successfulResponse_appendsMessages() {
        controller.synchronize()
        let initialPayload = ChannelPayload.dummy(
            messages: [
                .dummy(messageId: "new1", text: "New Message 1"),
                .dummy(messageId: "new2", text: "New Message 2")
            ]
        )
        client.mockAPIClient.test_simulateResponse(.success(initialPayload))

        let expectation = self.expectation(description: "Load previous messages completes")
        nonisolated(unsafe) var loadError: Error?

        controller.loadPreviousMessages(before: "new2") { error in
            loadError = error
            expectation.fulfill()
        }

        let channelPayload = ChannelPayload.dummy(
            messages: [
                .dummy(messageId: "old1", text: "Old Message 1"),
                .dummy(messageId: "old2", text: "Old Message 2")
            ]
        )
        client.mockAPIClient.test_simulateResponse(.success(channelPayload))

        waitForExpectations(timeout: defaultTimeout)

        XCTAssertNil(loadError)
        XCTAssertEqual(controller.messages.count, 4)
        XCTAssertEqual(controller.messages.map(\.id), ["new2", "new1", "old2", "old1"])
    }

    func test_loadPageAroundMessageId_successfulResponse_replacesMessages() {
        controller.synchronize()
        let initialPayload = ChannelPayload.dummy(
            messages: [
                .dummy(messageId: "old1", text: "Old Message 1"),
                .dummy(messageId: "old2", text: "Old Message 2")
            ]
        )
        client.mockAPIClient.test_simulateResponse(.success(initialPayload))

        let expectation = self.expectation(description: "Load page around message completes")
        nonisolated(unsafe) var loadError: Error?

        controller.loadPageAroundMessageId("target-message-id") { error in
            loadError = error
            expectation.fulfill()
        }

        let channelPayload = ChannelPayload.dummy(
            messages: [
                .dummy(messageId: "around1", text: "Around Message 1"),
                .dummy(messageId: "around2", text: "Around Message 2")
            ]
        )
        client.mockAPIClient.test_simulateResponse(.success(channelPayload))

        waitForExpectations(timeout: defaultTimeout)

        XCTAssertNil(loadError)
        XCTAssertEqual(controller.messages.count, 2)
        XCTAssertEqual(controller.messages.map(\.id), ["around2", "around1"])
    }
}

// MARK: - Pause/Resume Tests

extension LivestreamChannelController_Tests {
    func test_pause_forwardsToHandler() {
        let (controller, mockHandler) = makeControllerWithMockHandler()
        _ = controller

        controller.pause()

        XCTAssertEqual(mockHandler.pause_callCount, 1)
    }

    func test_resume_setsIsPausedToFalse() {
        controller.pause()
        XCTAssertTrue(controller.isPaused)

        let exp = expectation(description: "resume completes")
        controller.resume { error in
            XCTAssertNil(error)
            exp.fulfill()
        }

        let channelPayload = ChannelPayload.dummy(
            channel: .dummy(cid: .unique)
        )
        client.mockAPIClient.test_simulateResponse(.success(channelPayload))

        waitForExpectations(timeout: defaultTimeout)
        XCTAssertFalse(controller.isPaused)
    }

    func test_resume_resetsSkippedMessagesAmount() {
        controller.countSkippedMessagesWhenPaused = true

        controller.pause()

        controller.didReceiveEvent(MessageNewEvent(
            user: .unique,
            message: .unique,
            channel: .mock(cid: controller.cid!),
            createdAt: .unique,
            watcherCount: nil,
            unreadCount: nil
        ))
        XCTAssertEqual(controller.skippedMessagesAmount, 1)

        controller.resume()

        XCTAssertEqual(controller.skippedMessagesAmount, 0)
    }

    func test_resume_callsLoadFirstPage() throws {
        let apiClient = client.mockAPIClient
        controller.pause()

        controller.resume()

        let expectedPagination = MessagesPagination(pageSize: 25, parameter: nil)
        var expectedQuery = try XCTUnwrap(channelQuery)
        expectedQuery.pagination = expectedPagination
        let expectedEndpoint = Endpoint<ChannelPayload>.updateChannel(query: expectedQuery)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }

    func test_resume_whenNotPaused_doesNothing() {
        XCTAssertFalse(controller.isPaused)
        let apiClient = client.mockAPIClient

        controller.resume()

        XCTAssertNil(apiClient.request_endpoint)
    }

    func test_resume_whenAlreadyResuming_doesNothing() {
        controller.pause()
        XCTAssertTrue(controller.isPaused)

        controller.resume()

        let apiClient = client.mockAPIClient
        let firstCallCount = apiClient.request_allRecordedCalls.count

        controller.resume()

        let secondCallCount = apiClient.request_allRecordedCalls.count
        XCTAssertEqual(firstCallCount, secondCallCount, "No additional loadFirstPage call should be made when already resuming")
    }
}

// MARK: - Delegate Tests

extension LivestreamChannelController_Tests {
    @MainActor func test_delegate_isCalledWhenChannelUpdates() {
        let delegate = LivestreamChannelControllerDelegate_Mock()
        controller.delegate = delegate

        let channelPayload = ChannelPayload.dummy(
            channel: .dummy(cid: .unique)
        )

        controller.synchronize()
        client.mockAPIClient.test_simulateResponse(.success(channelPayload))

        AssertAsync.willBeTrue(delegate.didUpdateChannelCalled)
        AssertAsync.willBeEqual(delegate.didUpdateChannelCalledWith?.cid, channelPayload.channel.cid)
    }

    @MainActor func test_delegate_isCalledWhenMessagesUpdate() {
        let delegate = LivestreamChannelControllerDelegate_Mock()
        controller.delegate = delegate

        let channelPayload = ChannelPayload.dummy(
            messages: [.dummy(), .dummy()]
        )

        controller.synchronize()
        client.mockAPIClient.test_simulateResponse(.success(channelPayload))

        AssertAsync.willBeTrue(delegate.didUpdateMessagesCalled)
        AssertAsync.willBeEqual(delegate.didUpdateMessagesCalledWith?.count, 2)
    }

    @MainActor func test_delegate_isCalledWhenPauseStateChanges() {
        let delegate = LivestreamChannelControllerDelegate_Mock()
        controller.delegate = delegate

        controller.pause()

        AssertAsync.willBeTrue(delegate.didChangePauseStateCalled)
        AssertAsync.willBeTrue(delegate.didChangePauseStateCalledWith ?? false)
    }

    @MainActor func test_delegate_isCalledWhenSkippedMessagesAmountChanges() {
        let delegate = LivestreamChannelControllerDelegate_Mock()
        controller.delegate = delegate
        controller.countSkippedMessagesWhenPaused = true

        controller.pause()

        controller.didReceiveEvent(
            MessageNewEvent(
                user: .unique,
                message: .unique,
                channel: .mock(cid: controller.cid!),
                createdAt: .unique,
                watcherCount: nil,
                unreadCount: nil
            )
        )

        AssertAsync.willBeTrue(delegate.didChangeSkippedMessagesAmountCalled)
    }

    @MainActor func test_delegate_isCalledWhenTypingUsersChange() {
        let (controller, mockHandler) = makeControllerWithMockHandler()
        let delegate = LivestreamChannelControllerDelegate_Mock()
        controller.delegate = delegate

        let typingUser = ChatUser.mock(id: .unique)
        mockHandler.simulateTypingUsersDidChange([typingUser])

        AssertAsync.willBeTrue(delegate.didChangeTypingUsersCalled)
        AssertAsync.willBeEqual(delegate.didChangeTypingUsersCalledWith, [typingUser])
    }
}

// MARK: - Message Limiting Tests

extension LivestreamChannelController_Tests {
    func test_maxMessageLimitOptions_isForwardedToHandler() {
        let (controller, mockHandler) = makeControllerWithMockHandler()

        XCTAssertNil(controller.maxMessageLimitOptions)
        XCTAssertNil(mockHandler.maxMessageLimitOptions)

        let options = MaxMessageLimitOptions(maxLimit: 100, discardAmount: 20)
        controller.maxMessageLimitOptions = options

        XCTAssertEqual(mockHandler.maxMessageLimitOptions?.maxLimit, 100)
        XCTAssertEqual(mockHandler.maxMessageLimitOptions?.discardAmount, 20)
        XCTAssertEqual(controller.maxMessageLimitOptions?.maxLimit, 100)
    }

    func test_maxMessageLimitOptions_recommendedConfiguration() {
        let recommended = MaxMessageLimitOptions.recommended

        XCTAssertEqual(recommended.maxLimit, 200)
        XCTAssertEqual(recommended.discardAmount, 50)
    }
}

// MARK: - Helper Mock Classes

extension LivestreamChannelController_Tests {
    class LivestreamChannelControllerDelegate_Mock: LivestreamChannelControllerDelegate {
        var didUpdateChannelCalled = false
        var didUpdateChannelCalledWith: ChatChannel?

        var didUpdateMessagesCalled = false
        var didUpdateMessagesCalledWith: [ChatMessage]?

        var didChangePauseStateCalled = false
        var didChangePauseStateCalledWith: Bool?

        var didChangeSkippedMessagesAmountCalled = false
        var didChangeSkippedMessagesAmountCalledWith: Int?

        var didChangeTypingUsersCalled = false
        var didChangeTypingUsersCalledWith: Set<ChatUser>?

        func livestreamChannelController(
            _ controller: LivestreamChannelController,
            didUpdateChannel channel: ChatChannel
        ) {
            didUpdateChannelCalled = true
            didUpdateChannelCalledWith = channel
        }

        func livestreamChannelController(
            _ controller: LivestreamChannelController,
            didUpdateMessages messages: [ChatMessage]
        ) {
            didUpdateMessagesCalled = true
            didUpdateMessagesCalledWith = messages
        }

        func livestreamChannelController(
            _ controller: LivestreamChannelController,
            didChangePauseState isPaused: Bool
        ) {
            didChangePauseStateCalled = true
            didChangePauseStateCalledWith = isPaused
        }

        func livestreamChannelController(
            _ controller: LivestreamChannelController,
            didChangeSkippedMessagesAmount skippedMessagesAmount: Int
        ) {
            didChangeSkippedMessagesAmountCalled = true
            didChangeSkippedMessagesAmountCalledWith = skippedMessagesAmount
        }

        func livestreamChannelController(
            _ controller: LivestreamChannelController,
            didChangeTypingUsers typingUsers: Set<ChatUser>
        ) {
            didChangeTypingUsersCalled = true
            didChangeTypingUsersCalledWith = typingUsers
        }
    }
}

// MARK: - Message CRUD Tests

extension LivestreamChannelController_Tests {
    func test_createNewMessage_callsChannelUpdater() {
        let messageText = "Test message"
        let messageId = MessageId.unique
        let mockUpdater = makeMockUpdater()

        controller = LivestreamChannelController(
            channelQuery: channelQuery,
            client: client,
            updater: mockUpdater
        )

        let expectation = self.expectation(description: "Create message completes")
        nonisolated(unsafe) var createResult: Result<MessageId, Error>?

        controller.createNewMessage(
            messageId: messageId,
            text: messageText,
            pinning: .expirationTime(300),
            isSilent: true,
            attachments: [AnyAttachmentPayload.mockImage],
            mentionedUserIds: [.unique],
            quotedMessageId: .unique,
            skipPush: true,
            skipEnrichUrl: false,
            extraData: ["test": .string("value")]
        ) { result in
            createResult = result
            expectation.fulfill()
        }

        let mockMessage = ChatMessage.mock(id: messageId, cid: controller.cid!, text: messageText)
        mockUpdater.createNewMessage_completion?(.success(mockMessage))

        waitForExpectations(timeout: defaultTimeout)

        XCTAssertEqual(mockUpdater.createNewMessage_cid, controller.cid)
        XCTAssertEqual(mockUpdater.createNewMessage_text, messageText)
        XCTAssertEqual(mockUpdater.createNewMessage_isSilent, true)
        XCTAssertEqual(mockUpdater.createNewMessage_skipPush, true)
        XCTAssertEqual(mockUpdater.createNewMessage_skipEnrichUrl, false)
        XCTAssertEqual(mockUpdater.createNewMessage_attachments?.count, 1)
        XCTAssertEqual(mockUpdater.createNewMessage_mentionedUserIds?.count, 1)
        XCTAssertNotNil(mockUpdater.createNewMessage_quotedMessageId)
        XCTAssertNotNil(mockUpdater.createNewMessage_pinning)
        XCTAssertEqual(mockUpdater.createNewMessage_extraData?["test"], .string("value"))

        XCTAssertNotNil(createResult)
        if case .success(let resultMessageId) = createResult {
            XCTAssertEqual(resultMessageId, messageId)
        } else {
            XCTFail("Expected success result")
        }

        mockUpdater.cleanUp()
    }

    func test_createNewMessage_updaterFailure_callsCompletionWithError() {
        let messageText = "Test message"
        let messageId = MessageId.unique
        let mockUpdater = makeMockUpdater()

        controller = LivestreamChannelController(
            channelQuery: channelQuery,
            client: client,
            updater: mockUpdater
        )

        let expectation = self.expectation(description: "Create message completes")
        nonisolated(unsafe) var createResult: Result<MessageId, Error>?
        let testError = TestError()

        controller.createNewMessage(
            messageId: messageId,
            text: messageText
        ) { result in
            createResult = result
            expectation.fulfill()
        }

        mockUpdater.createNewMessage_completion?(.failure(testError))

        waitForExpectations(timeout: defaultTimeout)

        XCTAssertEqual(mockUpdater.createNewMessage_cid, controller.cid)
        XCTAssertEqual(mockUpdater.createNewMessage_text, messageText)

        XCTAssertNotNil(createResult)
        if case .failure(let error) = createResult {
            XCTAssert(error is TestError)
        } else {
            XCTFail("Expected failure result")
        }

        mockUpdater.cleanUp()
    }
}

// MARK: - Event Forwarding & App State Tests

extension LivestreamChannelController_Tests {
    func test_didReceiveEvent_forwardsToHandler() {
        let (controller, mockHandler) = makeControllerWithMockHandler()

        let event = MessageNewEvent(
            user: .mock(id: .unique),
            message: .mock(id: "new", cid: controller.cid!, text: "New"),
            channel: .mock(cid: controller.cid!),
            createdAt: .unique,
            watcherCount: nil,
            unreadCount: nil
        )

        controller.didReceiveEvent(event)

        XCTAssertEqual(mockHandler.didReceiveEvent_callCount, 1)
        XCTAssertTrue(mockHandler.didReceiveEvent_event is MessageNewEvent)
    }

    func test_applicationDidReceiveMemoryWarning_callsLoadFirstPage() {
        let apiClient = client.mockAPIClient

        controller.applicationDidReceiveMemoryWarning()

        let expectedPagination = MessagesPagination(pageSize: 25, parameter: nil)
        var expectedQuery = channelQuery!
        expectedQuery.pagination = expectedPagination
        let expectedEndpoint = Endpoint<ChannelPayload>.updateChannel(query: expectedQuery)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }

    func test_applicationDidMoveToForeground_whenNotConnected_callsLoadFirstPage() {
        let apiClient = client.mockAPIClient
        client.connectionStatus_mock = .disconnected(error: ClientError())

        controller.applicationDidMoveToForeground()

        let expectedPagination = MessagesPagination(pageSize: 25, parameter: nil)
        var expectedQuery = channelQuery!
        expectedQuery.pagination = expectedPagination
        let expectedEndpoint = Endpoint<ChannelPayload>.updateChannel(query: expectedQuery)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }

    func test_applicationDidMoveToForeground_whenConnected_doesNotCallLoadFirstPage() {
        let apiClient = client.mockAPIClient
        client.connectionStatus_mock = .connected

        controller.applicationDidMoveToForeground()

        XCTAssertNil(apiClient.request_endpoint)
    }
}

// MARK: - Message CRUD Tests

extension LivestreamChannelController_Tests {
    func test_deleteMessage_makesCorrectAPICall() {
        let messageId = MessageId.unique
        let apiClient = client.mockAPIClient
        let expectation = self.expectation(description: "Delete message completes")
        nonisolated(unsafe) var deleteError: Error?

        controller.deleteMessage(messageId: messageId, hard: false) { error in
            deleteError = error
            expectation.fulfill()
        }

        client.mockAPIClient.test_simulateResponse(
            Result<MessagePayload.Boxed, Error>.success(.init(message: .dummy()))
        )

        waitForExpectations(timeout: defaultTimeout)

        let expectedEndpoint = Endpoint<EmptyResponse>.deleteMessage(messageId: messageId, hard: false)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
        XCTAssertNil(deleteError)
    }

    func test_deleteMessage_withHardDelete_makesCorrectAPICall() {
        let messageId = MessageId.unique
        let apiClient = client.mockAPIClient

        controller.deleteMessage(messageId: messageId, hard: true) { _ in }

        let expectedEndpoint = Endpoint<EmptyResponse>.deleteMessage(messageId: messageId, hard: true)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }

    func test_deleteMessage_failedResponse_callsCompletionWithError() {
        let messageId = MessageId.unique
        let testError = TestError()
        let expectation = self.expectation(description: "Delete message completes")
        nonisolated(unsafe) var deleteError: Error?

        controller.deleteMessage(messageId: messageId) { error in
            deleteError = error
            expectation.fulfill()
        }

        client.mockAPIClient.test_simulateResponse(Result<MessagePayload.Boxed, Error>.failure(testError))

        waitForExpectations(timeout: defaultTimeout)

        XCTAssert(deleteError is TestError)
    }
}

// MARK: - Reactions Tests

extension LivestreamChannelController_Tests {
    func test_addReaction_makesCorrectAPICall() {
        let messageId = MessageId.unique
        let reactionType = MessageReactionType(rawValue: "like")
        let apiClient = client.mockAPIClient
        let expectation = self.expectation(description: "Add reaction completes")
        nonisolated(unsafe) var reactionError: Error?

        controller.addReaction(
            reactionType,
            to: messageId,
            score: 5,
            enforceUnique: true,
            skipPush: true,
            pushEmojiCode: "👍",
            extraData: ["key": .string("value")]
        ) { error in
            reactionError = error
            expectation.fulfill()
        }

        client.mockAPIClient.test_simulateResponse(Result<EmptyResponse, Error>.success(.init()))

        waitForExpectations(timeout: defaultTimeout)

        let expectedEndpoint = Endpoint<EmptyResponse>.addReaction(
            reactionType,
            score: 5,
            enforceUnique: true,
            extraData: ["key": .string("value")],
            skipPush: true,
            emojiCode: "👍",
            messageId: messageId
        )
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
        XCTAssertNil(reactionError)
    }

    func test_addReaction_withDefaultParameters_makesCorrectAPICall() {
        let messageId = MessageId.unique
        let reactionType = MessageReactionType(rawValue: "heart")
        let apiClient = client.mockAPIClient

        controller.addReaction(reactionType, to: messageId) { _ in }

        let expectedEndpoint = Endpoint<EmptyResponse>.addReaction(
            reactionType,
            score: 1,
            enforceUnique: false,
            extraData: [:],
            skipPush: false,
            emojiCode: nil,
            messageId: messageId
        )
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }

    func test_deleteReaction_makesCorrectAPICall() {
        let messageId = MessageId.unique
        let reactionType = MessageReactionType(rawValue: "like")
        let apiClient = client.mockAPIClient
        let expectation = self.expectation(description: "Delete reaction completes")
        nonisolated(unsafe) var reactionError: Error?

        controller.deleteReaction(reactionType, from: messageId) { error in
            reactionError = error
            expectation.fulfill()
        }

        client.mockAPIClient.test_simulateResponse(Result<EmptyResponse, Error>.success(.init()))

        waitForExpectations(timeout: defaultTimeout)

        let expectedEndpoint = Endpoint<EmptyResponse>.deleteReaction(reactionType, messageId: messageId)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
        XCTAssertNil(reactionError)
    }

    func test_loadReactions_makesCorrectAPICall() {
        let messageId = MessageId.unique
        let apiClient = client.mockAPIClient
        let expectation = self.expectation(description: "Load reactions completes")
        nonisolated(unsafe) var loadResult: Result<[ChatMessageReaction], Error>?

        controller.loadReactions(for: messageId, limit: 50, offset: 10) { result in
            loadResult = result
            expectation.fulfill()
        }

        let mockReactions = [MessageReactionPayload.dummy(
            messageId: messageId,
            user: UserPayload.dummy(userId: .unique)
        )]
        let reactionsPayload = MessageReactionsPayload(reactions: mockReactions)
        client.mockAPIClient.test_simulateResponse(Result<MessageReactionsPayload, Error>.success(reactionsPayload))

        waitForExpectations(timeout: defaultTimeout)

        let expectedPagination = Pagination(pageSize: 50, offset: 10)
        let expectedEndpoint = Endpoint<MessageReactionsPayload>.loadReactions(messageId: messageId, pagination: expectedPagination)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
        XCTAssertNotNil(loadResult)
        if case .success = loadResult {
            // Test passes
        } else {
            XCTFail("Expected success result")
        }
    }

    func test_loadReactions_withDefaultParameters_makesCorrectAPICall() {
        let messageId = MessageId.unique
        let apiClient = client.mockAPIClient

        controller.loadReactions(for: messageId) { _ in }

        let expectedPagination = Pagination(pageSize: 25, offset: 0)
        let expectedEndpoint = Endpoint<MessageReactionsPayload>.loadReactions(messageId: messageId, pagination: expectedPagination)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }

    func test_loadReactions_failedResponse_callsCompletionWithError() {
        let messageId = MessageId.unique
        let testError = TestError()
        let expectation = self.expectation(description: "Load reactions completes")
        nonisolated(unsafe) var loadResult: Result<[ChatMessageReaction], Error>?

        controller.loadReactions(for: messageId) { result in
            loadResult = result
            expectation.fulfill()
        }

        client.mockAPIClient.test_simulateResponse(Result<MessageReactionsPayload, Error>.failure(testError))

        waitForExpectations(timeout: defaultTimeout)

        XCTAssertNotNil(loadResult)
        if case .failure(let error) = loadResult {
            XCTAssert(error is TestError)
        } else {
            XCTFail("Expected failure result")
        }
    }
}

// MARK: - Message Actions Tests

extension LivestreamChannelController_Tests {
    func test_flag_makesCorrectAPICall() {
        let messageId = MessageId.unique
        let reason = "spam"
        let extraData: [String: RawJSON] = ["key": .string("value")]
        let apiClient = client.mockAPIClient
        let expectation = self.expectation(description: "Flag message completes")
        nonisolated(unsafe) var flagError: Error?

        controller.flag(messageId: messageId, reason: reason, extraData: extraData) { error in
            flagError = error
            expectation.fulfill()
        }

        let flagPayload = FlagMessagePayload(
            currentUser: CurrentUserPayload.dummy(userId: .unique, role: .user),
            flaggedMessageId: messageId
        )
        client.mockAPIClient.test_simulateResponse(Result<FlagMessagePayload, Error>.success(flagPayload))

        waitForExpectations(timeout: defaultTimeout)

        let expectedEndpoint = Endpoint<FlagMessagePayload>.flagMessage(
            true,
            with: messageId,
            reason: reason,
            extraData: extraData
        )
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
        XCTAssertNil(flagError)
    }

    func test_flag_withDefaultParameters_makesCorrectAPICall() {
        let messageId = MessageId.unique
        let apiClient = client.mockAPIClient

        controller.flag(messageId: messageId) { _ in }

        let expectedEndpoint = Endpoint<FlagMessagePayload>.flagMessage(
            true,
            with: messageId,
            reason: nil,
            extraData: nil
        )
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }

    func test_unflag_makesCorrectAPICall() {
        let messageId = MessageId.unique
        let apiClient = client.mockAPIClient
        let expectation = self.expectation(description: "Unflag message completes")
        nonisolated(unsafe) var unflagError: Error?

        controller.unflag(messageId: messageId) { error in
            unflagError = error
            expectation.fulfill()
        }

        let flagPayload = FlagMessagePayload(
            currentUser: CurrentUserPayload.dummy(userId: .unique, role: .user),
            flaggedMessageId: messageId
        )
        client.mockAPIClient.test_simulateResponse(Result<FlagMessagePayload, Error>.success(flagPayload))

        waitForExpectations(timeout: defaultTimeout)

        let expectedEndpoint = Endpoint<FlagMessagePayload>.flagMessage(
            false,
            with: messageId,
            reason: nil,
            extraData: nil
        )
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
        XCTAssertNil(unflagError)
    }

    func test_pin_makesCorrectAPICall() {
        let messageId = MessageId.unique
        let apiClient = client.mockAPIClient
        let expectation = self.expectation(description: "Pin message completes")
        nonisolated(unsafe) var pinError: Error?

        controller.pin(messageId: messageId) { error in
            pinError = error
            expectation.fulfill()
        }

        client.mockAPIClient.test_simulateResponse(Result<EmptyResponse, Error>.success(.init()))

        waitForExpectations(timeout: defaultTimeout)

        let expectedEndpoint = Endpoint<EmptyResponse>.pinMessage(
            messageId: messageId,
            request: .init(set: .init(pinned: true))
        )
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
        XCTAssertNil(pinError)
    }

    func test_unpin_makesCorrectAPICall() {
        let messageId = MessageId.unique
        let apiClient = client.mockAPIClient
        let expectation = self.expectation(description: "Unpin message completes")
        nonisolated(unsafe) var unpinError: Error?

        controller.unpin(messageId: messageId) { error in
            unpinError = error
            expectation.fulfill()
        }

        client.mockAPIClient.test_simulateResponse(Result<EmptyResponse, Error>.success(.init()))

        waitForExpectations(timeout: defaultTimeout)

        let expectedEndpoint = Endpoint<EmptyResponse>.pinMessage(
            messageId: messageId,
            request: .init(set: .init(pinned: false))
        )
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
        XCTAssertNil(unpinError)
    }

    func test_loadPinnedMessages_makesCorrectAPICall() {
        let apiClient = client.mockAPIClient
        let expectation = self.expectation(description: "Load pinned messages completes")
        nonisolated(unsafe) var loadResult: Result<[ChatMessage], Error>?
        let sorting: [Sorting<PinnedMessagesSortingKey>] = [.init(key: .pinnedAt, isAscending: false)]
        let pagination = PinnedMessagesPagination.after(.unique, inclusive: false)

        controller.loadPinnedMessages(
            pageSize: 50,
            sorting: sorting,
            pagination: pagination
        ) { result in
            loadResult = result
            expectation.fulfill()
        }

        let pinnedMessagesPayload = PinnedMessagesPayload(messages: [.dummy()])
        client.mockAPIClient.test_simulateResponse(Result<PinnedMessagesPayload, Error>.success(pinnedMessagesPayload))

        waitForExpectations(timeout: defaultTimeout)

        let expectedQuery = PinnedMessagesQuery(
            pageSize: 50,
            sorting: sorting,
            pagination: pagination
        )
        let expectedEndpoint = Endpoint<PinnedMessagesPayload>.pinnedMessages(cid: controller.cid!, query: expectedQuery)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
        XCTAssertNotNil(loadResult)
        if case .success = loadResult {
            // Test passes
        } else {
            XCTFail("Expected success result")
        }
    }

    func test_loadPinnedMessages_withDefaultParameters_makesCorrectAPICall() {
        let apiClient = client.mockAPIClient

        controller.loadPinnedMessages { _ in }

        let expectedQuery = PinnedMessagesQuery(
            pageSize: 25,
            sorting: [],
            pagination: nil
        )
        let expectedEndpoint = Endpoint<PinnedMessagesPayload>.pinnedMessages(cid: controller.cid!, query: expectedQuery)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }
}

// MARK: - Start/Stop Watching Tests

extension LivestreamChannelController_Tests {
    func test_startWatching_makesCorrectAPICall() {
        let expectation = self.expectation(description: "Start watching completes")
        nonisolated(unsafe) var watchError: Error?
        let mockUpdater = makeMockUpdater()

        controller = LivestreamChannelController(
            channelQuery: channelQuery,
            client: client,
            updater: mockUpdater
        )

        controller.startWatching(isInRecoveryMode: false) { error in
            watchError = error
            expectation.fulfill()
        }

        mockUpdater.startWatching_completion?(nil)

        waitForExpectations(timeout: defaultTimeout)

        XCTAssertEqual(mockUpdater.startWatching_cid, controller.cid)
        XCTAssertEqual(mockUpdater.startWatching_isInRecoveryMode, false)
        XCTAssertNil(watchError)

        mockUpdater.cleanUp()
    }

    func test_startWatching_withRecoveryMode_makesCorrectAPICall() {
        let expectation = self.expectation(description: "Start watching completes")
        nonisolated(unsafe) var watchError: Error?
        let mockUpdater = makeMockUpdater()

        controller = LivestreamChannelController(
            channelQuery: channelQuery,
            client: client,
            updater: mockUpdater
        )

        controller.startWatching(isInRecoveryMode: true) { error in
            watchError = error
            expectation.fulfill()
        }

        mockUpdater.startWatching_completion?(nil)

        waitForExpectations(timeout: defaultTimeout)

        XCTAssertEqual(mockUpdater.startWatching_cid, controller.cid)
        XCTAssertEqual(mockUpdater.startWatching_isInRecoveryMode, true)
        XCTAssertNil(watchError)

        mockUpdater.cleanUp()
    }

    func test_startWatching_updaterFailure_callsCompletionWithError() {
        let expectation = self.expectation(description: "Start watching completes")
        nonisolated(unsafe) var watchError: Error?
        let testError = TestError()
        let mockUpdater = makeMockUpdater()

        controller = LivestreamChannelController(
            channelQuery: channelQuery,
            client: client,
            updater: mockUpdater
        )

        controller.startWatching(isInRecoveryMode: false) { error in
            watchError = error
            expectation.fulfill()
        }

        mockUpdater.startWatching_completion?(testError)

        waitForExpectations(timeout: defaultTimeout)

        XCTAssert(watchError is TestError)

        mockUpdater.cleanUp()
    }

    func test_stopWatching_makesCorrectAPICall() {
        let expectation = self.expectation(description: "Stop watching completes")
        nonisolated(unsafe) var watchError: Error?
        let mockUpdater = makeMockUpdater()

        controller = LivestreamChannelController(
            channelQuery: channelQuery,
            client: client,
            updater: mockUpdater
        )

        controller.stopWatching { error in
            watchError = error
            expectation.fulfill()
        }

        mockUpdater.stopWatching_completion?(nil)

        waitForExpectations(timeout: defaultTimeout)

        XCTAssertEqual(mockUpdater.stopWatching_cid, controller.cid)
        XCTAssertNil(watchError)

        mockUpdater.cleanUp()
    }

    func test_stopWatching_updaterFailure_callsCompletionWithError() {
        let expectation = self.expectation(description: "Stop watching completes")
        nonisolated(unsafe) var watchError: Error?
        let testError = TestError()
        let mockUpdater = makeMockUpdater()

        controller = LivestreamChannelController(
            channelQuery: channelQuery,
            client: client,
            updater: mockUpdater
        )

        controller.stopWatching { error in
            watchError = error
            expectation.fulfill()
        }

        mockUpdater.stopWatching_completion?(testError)

        waitForExpectations(timeout: defaultTimeout)

        XCTAssert(watchError is TestError)

        mockUpdater.cleanUp()
    }
}

// MARK: - Sync Repository Integration Tests

extension LivestreamChannelController_Tests {
    func test_synchronize_tracksActiveLivestreamController() {
        let client = ChatClient.mock
        let channelQuery = ChannelQuery(cid: .unique)
        let controller = LivestreamChannelController(
            channelQuery: channelQuery,
            client: client
        )
        XCTAssert(client.syncRepository.activeLivestreamControllers.allObjects.isEmpty)

        controller.synchronize()
        XCTAssert(controller.client === client)
        XCTAssert(client.syncRepository.activeLivestreamControllers.count == 1)
        XCTAssert(client.syncRepository.activeLivestreamControllers.allObjects.first === controller)
    }

    func test_startWatching_tracksActiveLivestreamController() {
        let client = ChatClient.mock
        let channelQuery = ChannelQuery(cid: .unique)
        let controller = LivestreamChannelController(
            channelQuery: channelQuery,
            client: client
        )
        XCTAssert(client.syncRepository.activeLivestreamControllers.allObjects.isEmpty)

        controller.startWatching(isInRecoveryMode: false) { _ in }
        XCTAssert(controller.client === client)
        XCTAssert(client.syncRepository.activeLivestreamControllers.count == 1)
        XCTAssert(client.syncRepository.activeLivestreamControllers.allObjects.first === controller)
    }

    func test_stopWatching_removesActiveLivestreamController() {
        let client = ChatClient.mock
        let channelQuery = ChannelQuery(cid: .unique)
        let controller = LivestreamChannelController(
            channelQuery: channelQuery,
            client: client
        )
        controller.synchronize()
        XCTAssert(client.syncRepository.activeLivestreamControllers.count == 1)

        controller.stopWatching()
        XCTAssert(client.syncRepository.activeLivestreamControllers.allObjects.isEmpty == true)
    }
}

// MARK: - Slow Mode Tests

extension LivestreamChannelController_Tests {
    func test_enableSlowMode_makesCorrectAPICall() {
        let cooldownDuration = 30
        let apiClient = client.mockAPIClient
        let expectation = self.expectation(description: "Enable slow mode completes")
        nonisolated(unsafe) var slowModeError: Error?

        controller.enableSlowMode(cooldownDuration: cooldownDuration) { error in
            slowModeError = error
            expectation.fulfill()
        }

        client.mockAPIClient.test_simulateResponse(Result<EmptyResponse, Error>.success(.init()))

        waitForExpectations(timeout: defaultTimeout)

        let expectedEndpoint = Endpoint<EmptyResponse>.enableSlowMode(cid: controller.cid!, cooldownDuration: cooldownDuration)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
        XCTAssertNil(slowModeError)
    }

    func test_disableSlowMode_makesCorrectCall() {
        let expectation = self.expectation(description: "Disable slow mode completes")
        nonisolated(unsafe) var slowModeError: Error?

        controller.disableSlowMode { error in
            slowModeError = error
            expectation.fulfill()
        }

        client.mockAPIClient.test_simulateResponse(Result<EmptyResponse, Error>.success(.init()))

        waitForExpectations(timeout: defaultTimeout)

        XCTAssertNil(slowModeError)
    }

    func test_currentCooldownTime_returnsValueFromHandler() {
        let (controller, mockHandler) = makeControllerWithMockHandler()

        mockHandler.stubbedCurrentCooldownTime = 12
        XCTAssertEqual(controller.currentCooldownTime(), 12)

        mockHandler.stubbedCurrentCooldownTime = 0
        XCTAssertEqual(controller.currentCooldownTime(), 0)
    }
}

// MARK: - Freeze / Unfreeze Tests

extension LivestreamChannelController_Tests {
    func test_freezeChannel_makesCorrectAPICall() {
        let apiClient = client.mockAPIClient
        let expectation = self.expectation(description: "Freeze channel completes")
        var freezeError: Error?

        controller.freezeChannel { error in
            freezeError = error
            expectation.fulfill()
        }

        client.mockAPIClient.test_simulateResponse(Result<EmptyResponse, Error>.success(.init()))

        waitForExpectations(timeout: defaultTimeout)

        let expectedEndpoint = Endpoint<EmptyResponse>.freezeChannel(true, cid: controller.cid!)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
        XCTAssertNil(freezeError)
    }

    func test_unfreezeChannel_makesCorrectAPICall() {
        let apiClient = client.mockAPIClient
        let expectation = self.expectation(description: "Unfreeze channel completes")
        var unfreezeError: Error?

        controller.unfreezeChannel { error in
            unfreezeError = error
            expectation.fulfill()
        }

        client.mockAPIClient.test_simulateResponse(Result<EmptyResponse, Error>.success(.init()))

        waitForExpectations(timeout: defaultTimeout)

        let expectedEndpoint = Endpoint<EmptyResponse>.freezeChannel(false, cid: controller.cid!)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
        XCTAssertNil(unfreezeError)
    }
}

// MARK: - Sending Typing Events Tests

extension LivestreamChannelController_Tests {
    private func loadChannel(
        cid: ChannelId? = nil,
        ownCapabilities: [ChannelCapability] = [.sendTypingEvents]
    ) {
        let cid = cid ?? controller.cid!
        let exp = expectation(description: "sync completes")
        controller.synchronize { _ in exp.fulfill() }
        let channelPayload = ChannelPayload.dummy(
            channel: .dummy(cid: cid, ownCapabilities: ownCapabilities.map(\.rawValue))
        )
        client.mockAPIClient.test_simulateResponse(.success(channelPayload))
        waitForExpectations(timeout: defaultTimeout)
    }

    func test_sendKeystrokeEvent_callsCorrectEndpoint() {
        loadChannel()
        let apiClient = client.mockAPIClient

        controller.sendKeystrokeEvent()

        let expectedEndpoint = Endpoint<EmptyResponse>.startTypingEvent(cid: controller.cid!, parentMessageId: nil)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }

    func test_sendKeystrokeEvent_withParentMessageId_callsCorrectEndpoint() {
        loadChannel()
        let apiClient = client.mockAPIClient
        let parentMessageId = MessageId.unique

        controller.sendKeystrokeEvent(parentMessageId: parentMessageId)

        let expectedEndpoint = Endpoint<EmptyResponse>.startTypingEvent(
            cid: controller.cid!,
            parentMessageId: parentMessageId
        )
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }

    func test_sendStartTypingEvent_callsCorrectEndpoint() {
        loadChannel()
        let apiClient = client.mockAPIClient

        controller.sendStartTypingEvent()

        let expectedEndpoint = Endpoint<EmptyResponse>.startTypingEvent(cid: controller.cid!, parentMessageId: nil)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }

    func test_sendStopTypingEvent_callsCorrectEndpoint() {
        loadChannel()
        let apiClient = client.mockAPIClient

        controller.sendStopTypingEvent()

        let expectedEndpoint = Endpoint<EmptyResponse>.stopTypingEvent(cid: controller.cid!, parentMessageId: nil)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }

    func test_sendKeystrokeEvent_whenTypingEventsAreDisabled_doesNothing() {
        loadChannel(ownCapabilities: [])
        let apiClient = client.mockAPIClient
        apiClient.cleanUp()
        let exp = expectation(description: "completion called")
        nonisolated(unsafe) var receivedError: Error?

        controller.sendKeystrokeEvent { error in
            receivedError = error
            exp.fulfill()
        }

        waitForExpectations(timeout: defaultTimeout)
        XCTAssertNil(receivedError)
        XCTAssertNil(apiClient.request_endpoint)
    }

    func test_sendStartTypingEvent_whenTypingEventsAreDisabled_errors() {
        loadChannel(ownCapabilities: [])
        let exp = expectation(description: "completion called")
        nonisolated(unsafe) var receivedError: Error?

        controller.sendStartTypingEvent { error in
            receivedError = error
            exp.fulfill()
        }

        waitForExpectations(timeout: defaultTimeout)
        XCTAssertTrue(receivedError is ClientError.ChannelFeatureDisabled)
    }

    func test_sendTypingEvents_whenChannelIsNotLoaded_doesNotHitTypingEventsSender() {
        let apiClient = client.mockAPIClient
        XCTAssertNil(controller.channel)

        let keystrokeExp = expectation(description: "keystroke completion called")
        let startExp = expectation(description: "start typing completion called")
        let stopExp = expectation(description: "stop typing completion called")
        nonisolated(unsafe) var keystrokeError: Error?
        nonisolated(unsafe) var startError: Error?
        nonisolated(unsafe) var stopError: Error?

        controller.sendKeystrokeEvent { error in
            keystrokeError = error
            keystrokeExp.fulfill()
        }
        controller.sendStartTypingEvent { error in
            startError = error
            startExp.fulfill()
        }
        controller.sendStopTypingEvent { error in
            stopError = error
            stopExp.fulfill()
        }

        waitForExpectations(timeout: defaultTimeout)
        XCTAssertNil(apiClient.request_endpoint)
        XCTAssertNil(keystrokeError)
        XCTAssertTrue(startError is ClientError.ChannelFeatureDisabled)
        XCTAssertTrue(stopError is ClientError.ChannelFeatureDisabled)
    }
}

// MARK: - Helpers

private extension LivestreamChannelController_Tests {
    func makeMockUpdater() -> ChannelUpdater_Mock {
        ChannelUpdater_Mock(
            channelRepository: client.channelRepository,
            messageRepository: client.messageRepository,
            paginationStateHandler: client.makeMessagesPaginationStateHandler(),
            database: client.databaseContainer,
            apiClient: client.apiClient
        )
    }

    /// Builds a `LivestreamChannelController` whose underlying handler is the returned
    /// mock. Used for wiring tests that verify forwarding to the handler and that
    /// handler callbacks fire the delegate / update controller state.
    func makeControllerWithMockHandler() -> (LivestreamChannelController, LivestreamChannelHandler_Mock) {
        let mockHandler = LivestreamChannelHandler_Mock(
            channelQuery: channelQuery,
            client: client,
            paginationStateHandler: MessagesPaginationStateHandler()
        )
        let controller = LivestreamChannelController(
            channelQuery: channelQuery,
            client: client,
            handler: mockHandler
        )
        // Replace the instance-level controller so tearDown can release it.
        self.controller = controller
        return (controller, mockHandler)
    }
}

class MockPaginationStateHandler: MessagesPaginationStateHandling, @unchecked Sendable {
    init() {
        state = .initial
    }

    var state: MessagesPaginationState

    var beginCallCount = 0
    var endCallCount = 0

    func begin(pagination: MessagesPagination?) {
        beginCallCount += 1
    }

    func end(pagination: MessagesPagination?, with result: Result<[MessagePayload], any Error>) {
        endCallCount += 1
    }
}
