//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

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
        // Given
        let channelQuery = ChannelQuery(cid: .unique)
        let client = ChatClient.mock()
        
        // When
        let controller = LivestreamChannelController(
            channelQuery: channelQuery,
            client: client
        )
        
        // Then
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
        // Given
        let cid = ChannelId.unique
        let channelQuery = ChannelQuery(cid: cid)
        let client = ChatClient_Mock.mock()
        let eventNotificationCenter = EventNotificationCenter_Mock(
            database: DatabaseContainer_Spy()
        )
        client.mockedEventNotificationCenter = eventNotificationCenter

        // When
        _ = LivestreamChannelController(
            channelQuery: channelQuery,
            client: client
        )
        
        // Then
        XCTAssertEqual(eventNotificationCenter.registerManualEventHandling_callCount, 1)
        XCTAssertEqual(eventNotificationCenter.registerManualEventHandling_calledWith, cid)
    }
    
    func test_deinit_unregistersEventHandling() {
        // Given
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
        
        // When
        controller = nil
        
        // Then
        XCTAssertEqual(eventNotificationCenter.unregisterManualEventHandling_callCount, 1)
        XCTAssertEqual(eventNotificationCenter.unregisterManualEventHandling_calledWith, cid)
    }
}

// MARK: - Pagination Properties Tests

extension LivestreamChannelController_Tests {
    func test_hasLoadedAllNextMessages_whenMessagesArrayIsEmpty_thenReturnsTrue() {
        // Given - messages array is empty by default
        
        // When
        let result = controller.hasLoadedAllNextMessages
        
        // Then
        XCTAssertTrue(result)
    }
}

// MARK: - Synchronize Tests

extension LivestreamChannelController_Tests {
    func test_synchronize_makesCorrectAPICall() {
        // Given
        let apiClient = client.mockAPIClient
        
        // When
        controller.synchronize()
        
        // Then
        let expectedEndpoint = Endpoint<ChannelPayload>.updateChannel(query: channelQuery)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }
    
    func test_synchronize_withCache_loadsInitialDataFromCache() {
        // Given
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
        
        // Save channel to cache
        try! client.databaseContainer.writeSynchronously { session in
            try session.saveChannel(payload: channelPayload)
        }
        
        // When
        controller.synchronize()
        
        // Then
        XCTAssertNotNil(controller.channel)
        XCTAssertEqual(controller.channel?.cid, cid)
        XCTAssertEqual(controller.messages.count, 2)
    }
    
    func test_synchronize_withoutCache_doesNotLoadFromCache() {
        // Given
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
        
        // Save channel to cache
        try! client.databaseContainer.writeSynchronously { session in
            try session.saveChannel(payload: channelPayload)
        }
        
        // When
        controller.synchronize()
        
        // Then
        XCTAssertNil(controller.channel)
        XCTAssertTrue(controller.messages.isEmpty)
    }
    
    func test_synchronize_successfulResponse_updatesChannelAndMessages() {
        // Given
        let expectation = self.expectation(description: "Synchronize completes")
        var synchronizeError: Error?
        
        // When
        controller.synchronize { error in
            synchronizeError = error
            expectation.fulfill()
        }
        
        // Simulate successful API response
        let cid = ChannelId.unique
        let channelPayload = ChannelPayload.dummy(
            channel: .dummy(cid: cid),
            messages: [
                .dummy(messageId: "1", text: "Message 1"),
                .dummy(messageId: "2", text: "Message 2")
            ]
        )
        client.mockAPIClient.test_simulateResponse(.success(channelPayload))
        
        waitForExpectations(timeout: defaultTimeout)
        
        // Then
        XCTAssertNil(synchronizeError)
        XCTAssertNotNil(controller.channel)
        XCTAssertEqual(controller.channel?.cid, cid)
        XCTAssertEqual(controller.messages.count, 2)
        XCTAssertEqual(controller.messages.map(\.id), ["2", "1"]) // Reversed order
    }
    
    func test_synchronize_failedResponse_callsCompletionWithError() {
        // Given
        let expectation = self.expectation(description: "Synchronize completes")
        var synchronizeError: Error?
        let testError = TestError()
        
        // When
        controller.synchronize { error in
            synchronizeError = error
            expectation.fulfill()
        }
        
        // Simulate failed API response
        client.mockAPIClient.test_simulateResponse(Result<ChannelPayload, Error>.failure(testError))

        waitForExpectations(timeout: defaultTimeout)
        
        // Then
        XCTAssertEqual(synchronizeError as? TestError, testError)
        XCTAssertNil(controller.channel)
        XCTAssertTrue(controller.messages.isEmpty)
    }
}

// MARK: - Message Loading Tests

extension LivestreamChannelController_Tests {
    func test_loadPreviousMessages_withNoMessages_callsCompletionWithError() {
        // Given
        let expectation = self.expectation(description: "Load previous messages completes")
        var loadError: Error?
        
        // When
        controller.loadPreviousMessages { error in
            loadError = error
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout)
        
        // Then
        XCTAssert(loadError is ClientError.ChannelEmptyMessages)
    }
    
    func test_loadPreviousMessages_makesCorrectAPICall() throws {
        // Given
        // First load some messages so we have something to paginate from
        controller.synchronize()
        let channelPayload = ChannelPayload.dummy(messages: [.dummy(messageId: "message1")])
        client.mockAPIClient.test_simulateResponse(.success(channelPayload))
        
        let apiClient = client.mockAPIClient
        
        // When
        controller.loadPreviousMessages(before: "specific-message-id", limit: 50)
        
        // Then
        let expectedPagination = MessagesPagination(pageSize: 50, parameter: .lessThan("specific-message-id"))
        var expectedQuery = try XCTUnwrap(channelQuery)
        expectedQuery.pagination = expectedPagination
        let expectedEndpoint = Endpoint<ChannelPayload>.updateChannel(query: expectedQuery)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }
    
    func test_loadPreviousMessages_usesDefaultLimit() throws {
        // Given
        // First load some messages so we have something to paginate from
        controller.synchronize()
        let channelPayload = ChannelPayload.dummy(messages: [.dummy(messageId: "message1")])
        client.mockAPIClient.test_simulateResponse(.success(channelPayload))
        
        let apiClient = client.mockAPIClient
        
        // When
        controller.loadPreviousMessages(before: "specific-message-id")
        
        // Then
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

        // Save initial messages to the DB
        let initialChannelPayload = ChannelPayload.dummy(
            channel: .dummy(cid: channelQuery.cid!),
            messages: [
                .dummy(messageId: "old1"),
                .dummy(messageId: "old2")
            ]
        )
        // Save channel to cache
        try! client.databaseContainer.writeSynchronously { session in
            try session.saveChannel(payload: initialChannelPayload)
        }
        controller.synchronize()

        let expectation = self.expectation(description: "Load next messages completes")
        var loadError: Error?

        // When
        controller.loadNextMessages(after: "old1") { error in
            loadError = error
            expectation.fulfill()
        }

        // Simulate successful API response for next messages
        let channelPayload = ChannelPayload.dummy(
            messages: [
                .dummy(messageId: "new1", text: "New Message 1"),
                .dummy(messageId: "new2", text: "New Message 2")
            ]
        )
        client.mockAPIClient.test_simulateResponse(.success(channelPayload))

        waitForExpectations(timeout: defaultTimeout)

        // Then
        XCTAssertNil(loadError)
        XCTAssertEqual(controller.messages.count, 4)
        XCTAssertEqual(Set(controller.messages.map(\.id)), Set(["new2", "new1", "old2", "old1"])) // Next messages prepended
    }

    func test_loadPageAroundMessageId_makesCorrectAPICall() throws {
        // Given
        let apiClient = client.mockAPIClient
        
        // When
        controller.loadPageAroundMessageId("target-message-id", limit: 40)
        
        // Then
        let expectedPagination = MessagesPagination(pageSize: 40, parameter: .around("target-message-id"))
        var expectedQuery = try XCTUnwrap(channelQuery)
        expectedQuery.pagination = expectedPagination
        let expectedEndpoint = Endpoint<ChannelPayload>.updateChannel(query: expectedQuery)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }
    
    func test_loadFirstPage_makesCorrectAPICall() throws {
        // Given
        let apiClient = client.mockAPIClient
        
        // When
        controller.loadFirstPage()
        
        // Then
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
        var loadError: Error?
        
        // When
        controller.loadPreviousMessages(before: "new2") { error in
            loadError = error
            expectation.fulfill()
        }
        
        // Simulate successful API response for previous messages
        let channelPayload = ChannelPayload.dummy(
            messages: [
                .dummy(messageId: "old1", text: "Old Message 1"),
                .dummy(messageId: "old2", text: "Old Message 2")
            ]
        )
        client.mockAPIClient.test_simulateResponse(.success(channelPayload))
        
        waitForExpectations(timeout: defaultTimeout)
        
        // Then
        XCTAssertNil(loadError)
        XCTAssertEqual(controller.messages.count, 4)
        XCTAssertEqual(controller.messages.map(\.id), ["new2", "new1", "old2", "old1"]) // Previous messages appended
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
        var loadError: Error?
        
        // When
        controller.loadPageAroundMessageId("target-message-id") { error in
            loadError = error
            expectation.fulfill()
        }
        
        // Simulate successful API response for page around message
        let channelPayload = ChannelPayload.dummy(
            messages: [
                .dummy(messageId: "around1", text: "Around Message 1"),
                .dummy(messageId: "around2", text: "Around Message 2")
            ]
        )
        client.mockAPIClient.test_simulateResponse(.success(channelPayload))
        
        waitForExpectations(timeout: defaultTimeout)
        
        // Then
        XCTAssertNil(loadError)
        XCTAssertEqual(controller.messages.count, 2)
        XCTAssertEqual(controller.messages.map(\.id), ["around2", "around1"]) // Replaced all messages
    }
}

// MARK: - Pause/Resume Tests

extension LivestreamChannelController_Tests {
    func test_pause_setsIsPausedToTrue() {
        // Given
        XCTAssertFalse(controller.isPaused)
        
        // When
        controller.pause()
        
        // Then
        XCTAssertTrue(controller.isPaused)
    }
    
    func test_resume_setsIsPausedToFalse() {
        // Given
        controller.pause()
        XCTAssertTrue(controller.isPaused)
        
        // When
        let exp = expectation(description: "resume completes")
        controller.resume { error in
            XCTAssertNil(error)
            exp.fulfill()
        }

        let channelPayload = ChannelPayload.dummy(
            channel: .dummy(cid: .unique)
        )
        client.mockAPIClient.test_simulateResponse(.success(channelPayload))

        // Then
        waitForExpectations(timeout: defaultTimeout)
        XCTAssertFalse(controller.isPaused)
    }
    
    func test_resume_resetsSkippedMessagesAmount() {
        controller.countSkippedMessagesWhenPaused = true

        controller.pause()

        controller.eventsController(
            EventsController(
                notificationCenter: EventNotificationCenter_Mock(
                    database: DatabaseContainer_Spy()
                )
            ),
            didReceiveEvent: MessageNewEvent(
                user: .unique,
                message: .unique,
                channel: .mock(cid: controller.cid!),
                createdAt: .unique,
                watcherCount: nil,
                unreadCount: nil
            )
        )
        XCTAssertEqual(controller.skippedMessagesAmount, 1)

        // When
        controller.resume()
        
        // Then
        XCTAssertEqual(controller.skippedMessagesAmount, 0)
    }
    
    func test_resume_callsLoadFirstPage() throws {
        // Given
        let apiClient = client.mockAPIClient
        controller.pause()
        
        // When
        controller.resume()
        
        // Then
        let expectedPagination = MessagesPagination(pageSize: 25, parameter: nil)
        var expectedQuery = try XCTUnwrap(channelQuery)
        expectedQuery.pagination = expectedPagination
        let expectedEndpoint = Endpoint<ChannelPayload>.updateChannel(query: expectedQuery)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }
    
    func test_resume_whenNotPaused_doesNothing() {
        // Given
        XCTAssertFalse(controller.isPaused)
        let apiClient = client.mockAPIClient
        
        // When
        controller.resume()
        
        // Then
        XCTAssertNil(apiClient.request_endpoint)
    }
    
    func test_resume_whenAlreadyResuming_doesNothing() {
        // Given
        controller.pause()
        XCTAssertTrue(controller.isPaused)
        
        // Trigger first resume
        controller.resume()
        
        let apiClient = client.mockAPIClient
        let firstCallCount = apiClient.request_allRecordedCalls.count
        
        // When - call resume again while already resuming
        controller.resume()
        
        // Then - no additional API call should be made
        let secondCallCount = apiClient.request_allRecordedCalls.count
        XCTAssertEqual(firstCallCount, secondCallCount, "No additional loadFirstPage call should be made when already resuming")
    }
}

// MARK: - Delegate Tests

extension LivestreamChannelController_Tests {
    @MainActor func test_delegate_isCalledWhenChannelUpdates() {
        // Given
        let delegate = LivestreamChannelControllerDelegate_Mock()
        controller.delegate = delegate
        
        let channelPayload = ChannelPayload.dummy(
            channel: .dummy(cid: .unique)
        )
        
        // When
        controller.synchronize()
        client.mockAPIClient.test_simulateResponse(.success(channelPayload))
        
        // Then
        AssertAsync.willBeTrue(delegate.didUpdateChannelCalled)
        AssertAsync.willBeEqual(delegate.didUpdateChannelCalledWith?.cid, channelPayload.channel.cid)
    }
    
    @MainActor func test_delegate_isCalledWhenMessagesUpdate() {
        // Given
        let delegate = LivestreamChannelControllerDelegate_Mock()
        controller.delegate = delegate
        
        let channelPayload = ChannelPayload.dummy(
            messages: [.dummy(), .dummy()]
        )
        
        // When
        controller.synchronize()
        client.mockAPIClient.test_simulateResponse(.success(channelPayload))
        
        // Then
        AssertAsync.willBeTrue(delegate.didUpdateMessagesCalled)
        AssertAsync.willBeEqual(delegate.didUpdateMessagesCalledWith?.count, 2)
    }
    
    @MainActor func test_delegate_isCalledWhenPauseStateChanges() {
        // Given
        let delegate = LivestreamChannelControllerDelegate_Mock()
        controller.delegate = delegate
        
        // When
        controller.pause()
        
        // Then
        AssertAsync.willBeTrue(delegate.didChangePauseStateCalled)
        AssertAsync.willBeTrue(delegate.didChangePauseStateCalledWith ?? false)
    }
    
    @MainActor func test_delegate_isCalledWhenSkippedMessagesAmountChanges() {
        // Given
        let delegate = LivestreamChannelControllerDelegate_Mock()
        controller.delegate = delegate
        controller.countSkippedMessagesWhenPaused = true

        controller.pause()

        controller.eventsController(
            EventsController(
                notificationCenter: EventNotificationCenter_Mock(
                    database: DatabaseContainer_Spy()
                )
            ),
            didReceiveEvent: MessageNewEvent(
                user: .unique,
                message: .unique,
                channel: .mock(cid: controller.cid!),
                createdAt: .unique,
                watcherCount: nil,
                unreadCount: nil
            )
        )

        // When/Then
        AssertAsync.willBeTrue(delegate.didChangeSkippedMessagesAmountCalled)
    }
}

// MARK: - Message Limiting Tests

extension LivestreamChannelController_Tests {
    func test_maxMessageLimitOptions_whenNil_doesNotLimitMessages() {
        // Given
        controller.maxMessageLimitOptions = nil
        
        // When/Then
        XCTAssertNil(controller.maxMessageLimitOptions)
    }
    
    func test_maxMessageLimitOptions_whenSet_configuresLimits() {
        // Given
        let options = MaxMessageLimitOptions(maxLimit: 100, discardAmount: 20)
        
        // When
        controller.maxMessageLimitOptions = options
        
        // Then
        XCTAssertEqual(controller.maxMessageLimitOptions?.maxLimit, 100)
        XCTAssertEqual(controller.maxMessageLimitOptions?.discardAmount, 20)
    }
    
    func test_maxMessageLimitOptions_recommendedConfiguration() {
        // Given/When
        let recommended = MaxMessageLimitOptions.recommended
        
        // Then
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
    }
}

// MARK: - Message CRUD Tests

extension LivestreamChannelController_Tests {
    func test_createNewMessage_callsChannelUpdater() {
        // Given
        let messageText = "Test message"
        let messageId = MessageId.unique
        let mockUpdater = ChannelUpdater_Mock(
            channelRepository: client.channelRepository,
            messageRepository: client.messageRepository,
            paginationStateHandler: client.makeMessagesPaginationStateHandler(),
            database: client.databaseContainer,
            apiClient: client.apiClient
        )
        
        // Create controller with mock updater
        controller = LivestreamChannelController(
            channelQuery: channelQuery,
            client: client,
            updater: mockUpdater
        )
        
        let expectation = self.expectation(description: "Create message completes")
        var createResult: Result<MessageId, Error>?
        
        // When
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
        
        // Simulate successful updater response
        let mockMessage = ChatMessage.mock(id: messageId, cid: controller.cid!, text: messageText)
        mockUpdater.createNewMessage_completion?(.success(mockMessage))
        
        waitForExpectations(timeout: defaultTimeout)
        
        // Then - Verify the updater was called with correct parameters
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
        
        // Verify completion was called with correct result
        XCTAssertNotNil(createResult)
        if case .success(let resultMessageId) = createResult {
            XCTAssertEqual(resultMessageId, messageId)
        } else {
            XCTFail("Expected success result")
        }

        mockUpdater.cleanUp()
    }
    
    func test_createNewMessage_updaterFailure_callsCompletionWithError() {
        // Given
        let messageText = "Test message"
        let messageId = MessageId.unique
        let mockUpdater = ChannelUpdater_Mock(
            channelRepository: client.channelRepository,
            messageRepository: client.messageRepository,
            paginationStateHandler: client.makeMessagesPaginationStateHandler(),
            database: client.databaseContainer,
            apiClient: client.apiClient
        )
        
        // Create controller with mock updater
        controller = LivestreamChannelController(
            channelQuery: channelQuery,
            client: client,
            updater: mockUpdater
        )
        
        let expectation = self.expectation(description: "Create message completes")
        var createResult: Result<MessageId, Error>?
        let testError = TestError()
        
        // When
        controller.createNewMessage(
            messageId: messageId,
            text: messageText
        ) { result in
            createResult = result
            expectation.fulfill()
        }
        
        // Simulate updater failure
        mockUpdater.createNewMessage_completion?(.failure(testError))
        
        waitForExpectations(timeout: defaultTimeout)
        
        // Then - Verify the updater was called
        XCTAssertEqual(mockUpdater.createNewMessage_cid, controller.cid)
        XCTAssertEqual(mockUpdater.createNewMessage_text, messageText)
        
        // Verify completion was called with error
        XCTAssertNotNil(createResult)
        if case .failure(let error) = createResult {
            XCTAssert(error is TestError)
        } else {
            XCTFail("Expected failure result")
        }

        mockUpdater.cleanUp()
    }
}

// MARK: - Event Handling Tests

extension LivestreamChannelController_Tests {
    func test_applicationDidReceiveMemoryWarning_callsLoadFirstPage() {
        // Given
        let apiClient = client.mockAPIClient
        
        // When
        controller.applicationDidReceiveMemoryWarning()
        
        // Then
        let expectedPagination = MessagesPagination(pageSize: 25, parameter: nil)
        var expectedQuery = channelQuery!
        expectedQuery.pagination = expectedPagination
        let expectedEndpoint = Endpoint<ChannelPayload>.updateChannel(query: expectedQuery)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }

    func test_applicationDidMoveToForeground_whenNotConnected_callsLoadFirstPage() {
        // Given
        let apiClient = client.mockAPIClient
        client.connectionStatus_mock = .disconnected(error: ClientError())

        // When
        controller.applicationDidMoveToForeground()

        // Then
        let expectedPagination = MessagesPagination(pageSize: 25, parameter: nil)
        var expectedQuery = channelQuery!
        expectedQuery.pagination = expectedPagination
        let expectedEndpoint = Endpoint<ChannelPayload>.updateChannel(query: expectedQuery)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }

    func test_applicationDidMoveToForeground_whenConnected_doesNotCallLoadFirstPage() {
        // Given
        let apiClient = client.mockAPIClient
        client.connectionStatus_mock = .connected

        // When
        controller.applicationDidMoveToForeground()

        // Then
        XCTAssertNil(apiClient.request_endpoint)
    }

    func test_didReceiveEvent_messageNewEvent_addsMessageToArray() {
        let newMessage = ChatMessage.mock(id: "new", cid: controller.cid!, text: "New message")
        let event = MessageNewEvent(
            user: .mock(id: .unique),
            message: newMessage,
            channel: .mock(cid: controller.cid!),
            createdAt: .unique,
            watcherCount: nil,
            unreadCount: nil
        )
        
        // When
        controller.eventsController(
            EventsController(
                notificationCenter: client.eventNotificationCenter
            ),
            didReceiveEvent: event
        )
        
        // Then
        XCTAssertEqual(controller.messages.count, 1)
        XCTAssertEqual(controller.messages.first?.id, "new")
    }

    func test_didReceiveEvent_messageNewEvent_whenLimited_shouldCapMessagesArray() {
        controller.maxMessageLimitOptions = .init(
            maxLimit: 100,
            discardAmount: 50
        )

        let exp = expectation(description: "sync completes")
        controller.synchronize { _ in
            exp.fulfill()
        }

        let channelPayload = dummyPayload(with: controller.cid!, numberOfMessages: 100)
        client.mockAPIClient.test_simulateResponse(.success(channelPayload))

        waitForExpectations(timeout: defaultTimeout)

        // When
        let newMessage = ChatMessage.mock(id: "new", cid: controller.cid!, text: "New message")
        let event = MessageNewEvent(
            user: .mock(id: .unique),
            message: newMessage,
            channel: .mock(cid: controller.cid!),
            createdAt: .unique,
            watcherCount: nil,
            unreadCount: nil
        )
        controller.eventsController(
            EventsController(
                notificationCenter: client.eventNotificationCenter
            ),
            didReceiveEvent: event
        )

        // Then
        XCTAssertEqual(controller.messages.count, 50)
        XCTAssertEqual(controller.messages.first?.id, "new")
    }

    func test_didReceiveEvent_newMessagePendingEvent_addsMessageToArray() {
        let pendingMessage = ChatMessage.mock(id: "pending", cid: controller.cid!, text: "Pending message")
        let event = NewMessagePendingEvent(
            message: pendingMessage,
            cid: controller.cid!
        )
        
        // When
        controller.eventsController(
            EventsController(
                notificationCenter: client.eventNotificationCenter
            ),
            didReceiveEvent: event
        )
        
        // Then
        XCTAssertEqual(controller.messages.count, 1)
        XCTAssertEqual(controller.messages.first?.id, "pending")
    }
    
    func test_didReceiveEvent_newMessagePendingEvent_whenPaused_isIgnored() {
        // Given
        controller.pause()
        let pendingMessage = ChatMessage.mock(id: "pending", cid: controller.cid!, text: "Pending message")
        let event = NewMessagePendingEvent(
            message: pendingMessage,
            cid: controller.cid!
        )
        
        // When
        controller.eventsController(
            EventsController(
                notificationCenter: client.eventNotificationCenter
            ),
            didReceiveEvent: event
        )
        
        // Then
        XCTAssertEqual(controller.messages.count, 0) // Message not added when paused
    }
    
    func test_didReceiveEvent_messageUpdatedEvent_updatesExistingMessage() {
        // Add a message
        controller.eventsController(
            EventsController(
                notificationCenter: client.eventNotificationCenter
            ),
            didReceiveEvent: MessageNewEvent(
                user: .mock(id: .unique),
                message: .mock(id: "update-me"),
                channel: .mock(cid: controller.cid!),
                createdAt: .unique,
                watcherCount: nil,
                unreadCount: nil
            )
        )

        let updatedMessage = ChatMessage.mock(id: "update-me", cid: controller.cid!, text: "Updated text")
        let event = MessageUpdatedEvent(
            user: .mock(id: .unique),
            channel: .mock(cid: controller.cid!),
            message: updatedMessage,
            createdAt: .unique
        )
        
        // When
        controller.eventsController(
            EventsController(
                notificationCenter: client.eventNotificationCenter
            ),
            didReceiveEvent: event
        )
        
        // Then
        XCTAssertEqual(controller.messages.count, 1)
        XCTAssertEqual(controller.messages.first?.id, "update-me")
        XCTAssertEqual(controller.messages.first?.text, "Updated text")
    }
    
    func test_didReceiveEvent_messageDeletedEvent_hardDelete_removesMessage() {
        // Add a message
        controller.eventsController(
            EventsController(
                notificationCenter: client.eventNotificationCenter
            ),
            didReceiveEvent: MessageNewEvent(
                user: .mock(id: .unique),
                message: .mock(id: "delete-me"),
                channel: .mock(cid: controller.cid!),
                createdAt: .unique,
                watcherCount: nil,
                unreadCount: nil
            )
        )
        XCTAssertEqual(controller.messages.count, 1)

        let messageToDelete = ChatMessage.mock(id: "delete-me", cid: controller.cid!, text: "Delete me")
        let event = MessageDeletedEvent(
            user: .mock(id: .unique),
            channel: .mock(cid: controller.cid!),
            message: messageToDelete,
            createdAt: .unique,
            isHardDelete: true
        )
        
        // When
        controller.eventsController(EventsController(notificationCenter: client.eventNotificationCenter), didReceiveEvent: event)
        
        // Then
        XCTAssertEqual(controller.messages.count, 0)
    }
    
    func test_didReceiveEvent_messageDeletedEvent_softDelete_updatesMessage() {
        // Add a message
        controller.eventsController(
            EventsController(
                notificationCenter: client.eventNotificationCenter
            ),
            didReceiveEvent: MessageNewEvent(
                user: .mock(id: .unique),
                message: .mock(id: "delete-me"),
                channel: .mock(cid: controller.cid!),
                createdAt: .unique,
                watcherCount: nil,
                unreadCount: nil
            )
        )
        XCTAssertEqual(controller.messages.count, 1)

        let deletedMessage = ChatMessage.mock(
            id: "delete-me",
            cid: controller.cid!,
            text: "Delete me",
            deletedAt: .unique
        )
        let event = MessageDeletedEvent(
            user: .mock(id: .unique),
            channel: .mock(cid: controller.cid!),
            message: deletedMessage,
            createdAt: .unique,
            isHardDelete: false
        )
        
        // When
        controller.eventsController(EventsController(notificationCenter: client.eventNotificationCenter), didReceiveEvent: event)
        
        // Then
        XCTAssertEqual(controller.messages.count, 1)
        XCTAssertEqual(controller.messages.first?.id, "delete-me")
        XCTAssertNotNil(controller.messages.first?.deletedAt)
    }
    
    func test_didReceiveEvent_newMessageErrorEvent_updatesMessageState() {
        // Add a message
        controller.eventsController(
            EventsController(
                notificationCenter: client.eventNotificationCenter
            ),
            didReceiveEvent: MessageNewEvent(
                user: .mock(id: .unique),
                message: .mock(id: "failed-message"),
                channel: .mock(cid: controller.cid!),
                createdAt: .unique,
                watcherCount: nil,
                unreadCount: nil
            )
        )

        // When
        let event = NewMessageErrorEvent(
            messageId: "failed-message",
            cid: controller.cid!,
            error: ClientError.Unknown()
        )
        controller.eventsController(
            EventsController(
                notificationCenter: client.eventNotificationCenter
            ),
            didReceiveEvent: event
        )
        
        // Then
        XCTAssertEqual(controller.messages.count, 1)
        XCTAssertEqual(controller.messages.first?.id, "failed-message")
        XCTAssertEqual(controller.messages.first?.localState, .sendingFailed)
    }
    
    func test_didReceiveEvent_reactionNewEvent_updatesMessage() {
        let message = ChatMessage.mock(
            id: "message-with-reaction",
            cid: controller.cid!,
            text: "React to me",
            reactionScores: [:]
        )
        let messageWithReaction = ChatMessage.mock(
            id: "message-with-reaction",
            cid: controller.cid!,
            text: "React to me",
            reactionScores: ["like": 1]
        )
        let event = ReactionNewEvent(
            user: .mock(id: .unique),
            cid: controller.cid!,
            message: messageWithReaction,
            reaction: .mock(
                id: "message-with-reaction",
                type: .init(rawValue: "like")
            ),
            createdAt: .unique
        )

        controller.eventsController(
            EventsController(
                notificationCenter: client.eventNotificationCenter
            ),
            didReceiveEvent: MessageNewEvent(
                user: .mock(id: .unique),
                message: message,
                channel: .mock(cid: controller.cid!),
                createdAt: .unique,
                watcherCount: nil,
                unreadCount: nil
            )
        )
        XCTAssertEqual(controller.messages.first?.id, "message-with-reaction")
        XCTAssertEqual(controller.messages.first?.reactionScores["like"], nil)

        // When
        controller.eventsController(
            EventsController(
                notificationCenter: client.eventNotificationCenter
            ),
            didReceiveEvent: event
        )
        
        // Then
        XCTAssertEqual(controller.messages.count, 1)
        XCTAssertEqual(controller.messages.first?.id, "message-with-reaction")
        XCTAssertEqual(controller.messages.first?.reactionScores["like"], 1)
    }
    
    func test_didReceiveEvent_channelUpdatedEvent_updatesChannel() {
        let updatedChannel = ChatChannel.mock(cid: controller.cid!, name: "Updated Name")
        let event = ChannelUpdatedEvent(
            channel: updatedChannel,
            user: .mock(id: .unique),
            message: nil,
            createdAt: .unique
        )
        
        // When
        controller.eventsController(
            EventsController(
                notificationCenter: client.eventNotificationCenter
            ),
            didReceiveEvent: event
        )

        // Then
        XCTAssertEqual(controller.channel?.name, "Updated Name")
    }

    // MARK: - Member Update Events Tests

    func test_didReceiveEvent_memberRelatedEvents_updateChannelFromDataStore() {
        let cid = controller.cid!

        // Test data for all member-related events
        let memberEvents: [(event: Event, description: String)] = [
            (
                MemberAddedEvent(
                    user: .mock(id: .unique),
                    cid: cid,
                    member: .mock(id: .unique),
                    createdAt: .unique
                ),
                "MemberAddedEvent"
            ),
            (
                MemberRemovedEvent(
                    user: .mock(id: .unique),
                    cid: cid,
                    createdAt: .unique
                ),
                "MemberRemovedEvent"
            ),
            (
                MemberUpdatedEvent(
                    user: .mock(id: .unique),
                    cid: cid,
                    member: .mock(id: .unique),
                    createdAt: .unique
                ),
                "MemberUpdatedEvent"
            ),
            (
                NotificationAddedToChannelEvent(
                    channel: .mock(cid: cid),
                    unreadCount: nil,
                    member: .mock(id: .unique),
                    createdAt: .unique
                ),
                "NotificationAddedToChannelEvent"
            ),
            (
                NotificationRemovedFromChannelEvent(
                    user: .mock(id: .unique),
                    cid: cid,
                    member: .mock(id: .unique),
                    createdAt: .unique
                ),
                "NotificationRemovedFromChannelEvent"
            ),
            (
                NotificationInvitedEvent(
                    user: .mock(id: .unique),
                    cid: cid,
                    member: .mock(id: .unique),
                    createdAt: .unique
                ),
                "NotificationInvitedEvent"
            ),
            (
                NotificationInviteAcceptedEvent(
                    user: .mock(id: .unique),
                    channel: .mock(cid: cid),
                    member: .mock(id: .unique),
                    createdAt: .unique
                ),
                "NotificationInviteAcceptedEvent"
            ),
            (
                NotificationInviteRejectedEvent(
                    user: .mock(id: .unique),
                    channel: .mock(cid: cid),
                    member: .mock(id: .unique),
                    createdAt: .unique
                ),
                "NotificationInviteRejectedEvent"
            )
        ]

        // Test each member-related event
        for (index, (event, description)) in memberEvents.enumerated() {
            let initialMemberCount = 10 + index
            let updatedMemberCount = 20 + index

            // Given - Set up initial channel in database
            let initialChannelPayload = ChannelPayload.dummy(
                channel: .dummy(cid: cid, memberCount: initialMemberCount)
            )
            try! client.databaseContainer.writeSynchronously { session in
                try session.saveChannel(payload: initialChannelPayload)
            }

            // Load initial data
            let exp = expectation(description: "sync completes")
            controller.synchronize { _ in
                exp.fulfill()
            }
            client.mockAPIClient.test_simulateResponse(.success(initialChannelPayload))

            waitForExpectations(timeout: defaultTimeout)
            XCTAssertEqual(controller.channel?.memberCount, initialMemberCount, "Initial setup failed for \(description)")

            // Update channel in database with new member count
            let updatedChannelPayload = ChannelPayload.dummy(
                channel: .dummy(cid: cid, memberCount: updatedMemberCount)
            )
            try! client.databaseContainer.writeSynchronously { session in
                try session.saveChannel(payload: updatedChannelPayload)
            }

            // When
            controller.eventsController(
                EventsController(notificationCenter: client.eventNotificationCenter),
                didReceiveEvent: event
            )

            // Then
            XCTAssertEqual(
                controller.channel?.memberCount,
                updatedMemberCount,
                "\(description) should update channel from data store"
            )
        }
    }
    
    func test_didReceiveEvent_channelTruncatedEvent_updatesChannelAndMessages() {
        // Given - Set up initial channel with messages
        let cid = controller.cid!
        let initialMessage1 = ChatMessage.mock(id: "message1", cid: cid, text: "Message 1")
        let initialMessage2 = ChatMessage.mock(id: "message2", cid: cid, text: "Message 2")
        
        // Load initial messages
        controller.eventsController(
            EventsController(notificationCenter: client.eventNotificationCenter),
            didReceiveEvent: MessageNewEvent(
                user: .mock(id: .unique),
                message: initialMessage1,
                channel: .mock(cid: cid),
                createdAt: .unique,
                watcherCount: nil,
                unreadCount: nil
            )
        )
        controller.eventsController(
            EventsController(notificationCenter: client.eventNotificationCenter),
            didReceiveEvent: MessageNewEvent(
                user: .mock(id: .unique),
                message: initialMessage2,
                channel: .mock(cid: cid),
                createdAt: .unique,
                watcherCount: nil,
                unreadCount: nil
            )
        )
        XCTAssertEqual(controller.messages.count, 2)
        
        // Create truncated channel and truncation message
        let truncatedChannel = ChatChannel.mock(cid: cid, name: "Truncated Channel")
        let truncationMessage = ChatMessage.mock(id: "truncation", cid: cid, text: "Channel was truncated")
        
        let event = ChannelTruncatedEvent(
            channel: truncatedChannel,
            user: .mock(id: .unique),
            message: truncationMessage,
            createdAt: .unique
        )
        
        // When
        controller.eventsController(
            EventsController(notificationCenter: client.eventNotificationCenter),
            didReceiveEvent: event
        )
        
        // Then
        XCTAssertEqual(controller.channel?.name, "Truncated Channel")
        XCTAssertEqual(controller.messages.count, 1)
        XCTAssertEqual(controller.messages.first?.id, "truncation")
        XCTAssertEqual(controller.messages.first?.text, "Channel was truncated")
    }
    
    func test_didReceiveEvent_channelTruncatedEventWithoutMessage_clearsMessages() {
        // Given - Set up initial channel with messages
        let cid = controller.cid!
        let initialMessage = ChatMessage.mock(id: "message1", cid: cid, text: "Message 1")
        
        // Load initial message
        controller.eventsController(
            EventsController(notificationCenter: client.eventNotificationCenter),
            didReceiveEvent: MessageNewEvent(
                user: .mock(id: .unique),
                message: initialMessage,
                channel: .mock(cid: cid),
                createdAt: .unique,
                watcherCount: nil,
                unreadCount: nil
            )
        )
        XCTAssertEqual(controller.messages.count, 1)
        
        // Create truncated channel without truncation message
        let truncatedChannel = ChatChannel.mock(cid: cid, name: "Truncated Channel")
        
        let event = ChannelTruncatedEvent(
            channel: truncatedChannel,
            user: .mock(id: .unique),
            message: nil, // No truncation message
            createdAt: .unique
        )
        
        // When
        controller.eventsController(
            EventsController(notificationCenter: client.eventNotificationCenter),
            didReceiveEvent: event
        )
        
        // Then
        XCTAssertEqual(controller.channel?.name, "Truncated Channel")
        XCTAssertTrue(controller.messages.isEmpty)
    }
    
    func test_didReceiveEvent_differentChannelEvent_isIgnored() {
        let otherChannelId = ChannelId.unique
        let messageFromOtherChannel = ChatMessage.mock(id: "other", cid: otherChannelId, text: "Other message")
        let event = MessageNewEvent(
            user: .mock(id: .unique),
            message: messageFromOtherChannel,
            channel: .mock(cid: otherChannelId),
            createdAt: .unique,
            watcherCount: nil,
            unreadCount: nil
        )
        
        // When
        controller.eventsController(
            EventsController(
                notificationCenter: client.eventNotificationCenter
            ),
            didReceiveEvent: event
        )
        
        // Then - Message array should not change
        XCTAssertEqual(controller.messages.count, 0)
    }
    
    func test_didReceiveEvent_whenPaused_newMessageFromOtherUser_incrementsSkippedCount() {
        // Given
        controller.countSkippedMessagesWhenPaused = true
        controller.pause()
        XCTAssertEqual(controller.skippedMessagesAmount, 0)
        
        let otherUserId = UserId.unique
        let newMessage = ChatMessage.mock(
            id: "new",
            cid: controller.cid!,
            text: "New message",
            author: .unique
        )
        let event = MessageNewEvent(
            user: .mock(id: otherUserId),
            message: newMessage,
            channel: .mock(cid: controller.cid!),
            createdAt: .unique,
            watcherCount: nil,
            unreadCount: nil
        )
        
        // When
        controller.eventsController(EventsController(notificationCenter: client.eventNotificationCenter), didReceiveEvent: event)
        
        // Then
        XCTAssertEqual(controller.skippedMessagesAmount, 1)
        XCTAssertTrue(controller.messages.isEmpty) // Message not added when paused
    }
}

// MARK: - Message CRUD Tests

extension LivestreamChannelController_Tests {
    func test_deleteMessage_makesCorrectAPICall() {
        // Given
        let messageId = MessageId.unique
        let apiClient = client.mockAPIClient
        let expectation = self.expectation(description: "Delete message completes")
        var deleteError: Error?
        
        // When
        controller.deleteMessage(messageId: messageId, hard: false) { error in
            deleteError = error
            expectation.fulfill()
        }
        
        // Simulate successful response
        client.mockAPIClient.test_simulateResponse(
            Result<MessagePayload.Boxed, Error>.success(.init(message: .dummy()))
        )

        waitForExpectations(timeout: defaultTimeout)
        
        // Then
        let expectedEndpoint = Endpoint<EmptyResponse>.deleteMessage(messageId: messageId, hard: false)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
        XCTAssertNil(deleteError)
    }
    
    func test_deleteMessage_withHardDelete_makesCorrectAPICall() {
        // Given
        let messageId = MessageId.unique
        let apiClient = client.mockAPIClient
        
        // When
        controller.deleteMessage(messageId: messageId, hard: true) { _ in }
        
        // Then
        let expectedEndpoint = Endpoint<EmptyResponse>.deleteMessage(messageId: messageId, hard: true)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }
    
    func test_deleteMessage_failedResponse_callsCompletionWithError() {
        // Given
        let messageId = MessageId.unique
        let testError = TestError()
        let expectation = self.expectation(description: "Delete message completes")
        var deleteError: Error?
        
        // When
        controller.deleteMessage(messageId: messageId) { error in
            deleteError = error
            expectation.fulfill()
        }
        
        // Simulate failed response
        client.mockAPIClient.test_simulateResponse(Result<MessagePayload.Boxed, Error>.failure(testError))

        waitForExpectations(timeout: defaultTimeout)
        
        // Then
        XCTAssert(deleteError is TestError)
    }
}

// MARK: - Reactions Tests

extension LivestreamChannelController_Tests {
    func test_addReaction_makesCorrectAPICall() {
        // Given
        let messageId = MessageId.unique
        let reactionType = MessageReactionType(rawValue: "like")
        let apiClient = client.mockAPIClient
        let expectation = self.expectation(description: "Add reaction completes")
        var reactionError: Error?
        
        // When
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
        
        // Simulate successful response
        client.mockAPIClient.test_simulateResponse(Result<EmptyResponse, Error>.success(.init()))
        
        waitForExpectations(timeout: defaultTimeout)
        
        // Then
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
        // Given
        let messageId = MessageId.unique
        let reactionType = MessageReactionType(rawValue: "heart")
        let apiClient = client.mockAPIClient
        
        // When
        controller.addReaction(reactionType, to: messageId) { _ in }
        
        // Then
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
        // Given
        let messageId = MessageId.unique
        let reactionType = MessageReactionType(rawValue: "like")
        let apiClient = client.mockAPIClient
        let expectation = self.expectation(description: "Delete reaction completes")
        var reactionError: Error?
        
        // When
        controller.deleteReaction(reactionType, from: messageId) { error in
            reactionError = error
            expectation.fulfill()
        }
        
        // Simulate successful response
        client.mockAPIClient.test_simulateResponse(Result<EmptyResponse, Error>.success(.init()))
        
        waitForExpectations(timeout: defaultTimeout)
        
        // Then
        let expectedEndpoint = Endpoint<EmptyResponse>.deleteReaction(reactionType, messageId: messageId)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
        XCTAssertNil(reactionError)
    }
    
    func test_loadReactions_makesCorrectAPICall() {
        // Given
        let messageId = MessageId.unique
        let apiClient = client.mockAPIClient
        let expectation = self.expectation(description: "Load reactions completes")
        var loadResult: Result<[ChatMessageReaction], Error>?
        
        // When
        controller.loadReactions(for: messageId, limit: 50, offset: 10) { result in
            loadResult = result
            expectation.fulfill()
        }
        
        // Simulate successful response
        let mockReactions = [MessageReactionPayload.dummy(
            messageId: messageId,
            user: UserPayload.dummy(userId: .unique)
        )]
        let reactionsPayload = MessageReactionsPayload(reactions: mockReactions)
        client.mockAPIClient.test_simulateResponse(Result<MessageReactionsPayload, Error>.success(reactionsPayload))
        
        waitForExpectations(timeout: defaultTimeout)
        
        // Then
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
        // Given
        let messageId = MessageId.unique
        let apiClient = client.mockAPIClient
        
        // When
        controller.loadReactions(for: messageId) { _ in }
        
        // Then
        let expectedPagination = Pagination(pageSize: 25, offset: 0)
        let expectedEndpoint = Endpoint<MessageReactionsPayload>.loadReactions(messageId: messageId, pagination: expectedPagination)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }
    
    func test_loadReactions_failedResponse_callsCompletionWithError() {
        // Given
        let messageId = MessageId.unique
        let testError = TestError()
        let expectation = self.expectation(description: "Load reactions completes")
        var loadResult: Result<[ChatMessageReaction], Error>?
        
        // When
        controller.loadReactions(for: messageId) { result in
            loadResult = result
            expectation.fulfill()
        }
        
        // Simulate failed response
        client.mockAPIClient.test_simulateResponse(Result<MessageReactionsPayload, Error>.failure(testError))
        
        waitForExpectations(timeout: defaultTimeout)
        
        // Then
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
        // Given
        let messageId = MessageId.unique
        let reason = "spam"
        let extraData: [String: RawJSON] = ["key": .string("value")]
        let apiClient = client.mockAPIClient
        let expectation = self.expectation(description: "Flag message completes")
        var flagError: Error?
        
        // When
        controller.flag(messageId: messageId, reason: reason, extraData: extraData) { error in
            flagError = error
            expectation.fulfill()
        }
        
        // Simulate successful response
        let flagPayload = FlagMessagePayload(
            currentUser: CurrentUserPayload.dummy(userId: .unique, role: .user),
            flaggedMessageId: messageId
        )
        client.mockAPIClient.test_simulateResponse(Result<FlagMessagePayload, Error>.success(flagPayload))
        
        waitForExpectations(timeout: defaultTimeout)
        
        // Then
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
        // Given
        let messageId = MessageId.unique
        let apiClient = client.mockAPIClient
        
        // When
        controller.flag(messageId: messageId) { _ in }
        
        // Then
        let expectedEndpoint = Endpoint<FlagMessagePayload>.flagMessage(
            true,
            with: messageId,
            reason: nil,
            extraData: nil
        )
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }
    
    func test_unflag_makesCorrectAPICall() {
        // Given
        let messageId = MessageId.unique
        let apiClient = client.mockAPIClient
        let expectation = self.expectation(description: "Unflag message completes")
        var unflagError: Error?
        
        // When
        controller.unflag(messageId: messageId) { error in
            unflagError = error
            expectation.fulfill()
        }
        
        // Simulate successful response
        let flagPayload = FlagMessagePayload(
            currentUser: CurrentUserPayload.dummy(userId: .unique, role: .user),
            flaggedMessageId: messageId
        )
        client.mockAPIClient.test_simulateResponse(Result<FlagMessagePayload, Error>.success(flagPayload))
        
        waitForExpectations(timeout: defaultTimeout)
        
        // Then
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
        // Given
        let messageId = MessageId.unique
        let pinning = MessagePinning.expirationTime(20)
        let apiClient = client.mockAPIClient
        let expectation = self.expectation(description: "Pin message completes")
        var pinError: Error?
        
        // When
        controller.pin(messageId: messageId, pinning: pinning) { error in
            pinError = error
            expectation.fulfill()
        }
        
        // Simulate successful response
        client.mockAPIClient.test_simulateResponse(Result<EmptyResponse, Error>.success(.init()))
        
        waitForExpectations(timeout: defaultTimeout)
        
        // Then
        let expectedEndpoint = Endpoint<EmptyResponse>.pinMessage(
            messageId: messageId,
            request: .init(set: .init(pinned: true))
        )
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
        XCTAssertNil(pinError)
    }
    
    func test_pin_withDefaultPinning_makesCorrectAPICall() {
        // Given
        let messageId = MessageId.unique
        let apiClient = client.mockAPIClient
        
        // When
        controller.pin(messageId: messageId) { _ in }
        
        // Then
        let expectedEndpoint = Endpoint<EmptyResponse>.pinMessage(
            messageId: messageId,
            request: .init(set: .init(pinned: true))
        )
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }
    
    func test_unpin_makesCorrectAPICall() {
        // Given
        let messageId = MessageId.unique
        let apiClient = client.mockAPIClient
        let expectation = self.expectation(description: "Unpin message completes")
        var unpinError: Error?
        
        // When
        controller.unpin(messageId: messageId) { error in
            unpinError = error
            expectation.fulfill()
        }
        
        // Simulate successful response
        client.mockAPIClient.test_simulateResponse(Result<EmptyResponse, Error>.success(.init()))
        
        waitForExpectations(timeout: defaultTimeout)
        
        // Then
        let expectedEndpoint = Endpoint<EmptyResponse>.pinMessage(
            messageId: messageId,
            request: .init(set: .init(pinned: false))
        )
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
        XCTAssertNil(unpinError)
    }
    
    func test_loadPinnedMessages_makesCorrectAPICall() {
        // Given
        let apiClient = client.mockAPIClient
        let expectation = self.expectation(description: "Load pinned messages completes")
        var loadResult: Result<[ChatMessage], Error>?
        let sorting: [Sorting<PinnedMessagesSortingKey>] = [.init(key: .pinnedAt, isAscending: false)]
        let pagination = PinnedMessagesPagination.after(.unique, inclusive: false)
        
        // When
        controller.loadPinnedMessages(
            pageSize: 50,
            sorting: sorting,
            pagination: pagination
        ) { result in
            loadResult = result
            expectation.fulfill()
        }
        
        // Simulate successful response
        let pinnedMessagesPayload = PinnedMessagesPayload(messages: [.dummy()])
        client.mockAPIClient.test_simulateResponse(Result<PinnedMessagesPayload, Error>.success(pinnedMessagesPayload))
        
        waitForExpectations(timeout: defaultTimeout)
        
        // Then
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
        // Given
        let apiClient = client.mockAPIClient
        
        // When
        controller.loadPinnedMessages { _ in }
        
        // Then
        let expectedQuery = PinnedMessagesQuery(
            pageSize: 25,
            sorting: [],
            pagination: nil
        )
        let expectedEndpoint = Endpoint<PinnedMessagesPayload>.pinnedMessages(cid: controller.cid!, query: expectedQuery)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }
}

// MARK: - Slow Mode Tests

extension LivestreamChannelController_Tests {
    func test_enableSlowMode_makesCorrectAPICall() {
        // Given
        let cooldownDuration = 30
        let apiClient = client.mockAPIClient
        let expectation = self.expectation(description: "Enable slow mode completes")
        var slowModeError: Error?
        
        // When
        controller.enableSlowMode(cooldownDuration: cooldownDuration) { error in
            slowModeError = error
            expectation.fulfill()
        }
        
        // Simulate successful response
        client.mockAPIClient.test_simulateResponse(Result<EmptyResponse, Error>.success(.init()))
        
        waitForExpectations(timeout: defaultTimeout)
        
        // Then
        let expectedEndpoint = Endpoint<EmptyResponse>.enableSlowMode(cid: controller.cid!, cooldownDuration: cooldownDuration)
        XCTAssertEqual(apiClient.request_endpoint, AnyEndpoint(expectedEndpoint))
        XCTAssertNil(slowModeError)
    }
    
    func test_disableSlowMode_makesCorrectCall() {
        // Given
        let expectation = self.expectation(description: "Disable slow mode completes")
        var slowModeError: Error?
        
        // When
        controller.disableSlowMode { error in
            slowModeError = error
            expectation.fulfill()
        }
        
        // Simulate successful response - this goes through the updater
        client.mockAPIClient.test_simulateResponse(Result<EmptyResponse, Error>.success(.init()))
        
        waitForExpectations(timeout: defaultTimeout)
        
        // Then
        XCTAssertNil(slowModeError)
    }

    func test_currentCooldownTime_withNoCooldown_returnsZero() {
        // Given
        let channelPayload = ChannelPayload.dummy(
            channel: .dummy(cid: controller.cid!, cooldownDuration: 0)
        )
        controller.synchronize()
        client.mockAPIClient.test_simulateResponse(.success(channelPayload))
        
        // When
        let cooldownTime = controller.currentCooldownTime()
        
        // Then
        XCTAssertEqual(cooldownTime, 0)
    }
    
    func test_currentCooldownTime_withNoChannel_returnsZero() {
        // Given
        // Use a fresh controller with no channel data loaded
        let freshController = LivestreamChannelController(
            channelQuery: ChannelQuery(cid: .unique),
            client: client
        )
        
        // When
        let cooldownTime = freshController.currentCooldownTime()
        
        // Then
        XCTAssertEqual(cooldownTime, 0)
    }
    
    func test_currentCooldownTime_withActiveSlowMode_returnsCorrectTime() {
        // Given
        let currentUserId = UserId.unique
        client.mockAuthenticationRepository.mockedCurrentUserId = currentUserId
        let currentDate = Date()
        let messageDate = currentDate.addingTimeInterval(-10) // 10 seconds ago
        let cooldownDuration = 30
        
        // Create a mock channel payload with cooldown
        let channelPayload = ChannelPayload.dummy(
            channel: .dummy(
                cid: controller.cid!,
                ownCapabilities: [],
                cooldownDuration: cooldownDuration
            ),
            messages: [
                .dummy(
                    messageId: .unique,
                    authorUserId: currentUserId,
                    createdAt: messageDate
                )
            ]
        )
        
        // Load the channel data through normal API flow
        let exp = expectation(description: "sync completion")
        controller.synchronize { _ in
            exp.fulfill()
        }
        client.mockAPIClient.test_simulateResponse(.success(channelPayload))

        waitForExpectations(timeout: defaultTimeout)

        // When
        let cooldownTime = controller.currentCooldownTime()
        
        // Then
        // Should be approximately 20 seconds (30 - 10)
        XCTAssertGreaterThan(cooldownTime, 18)
        XCTAssertLessThan(cooldownTime, 22)
    }
    
    func test_currentCooldownTime_withSkipSlowModeCapability_returnsZero() {
        // Given
        let currentUserId = UserId.unique
        client.setToken(token: .unique(userId: currentUserId))
        let currentDate = Date()
        let messageDate = currentDate.addingTimeInterval(-10)
        
        // Create a mock channel payload with skip slow mode capability
        let channelPayload = ChannelPayload.dummy(
            channel: .dummy(
                cid: controller.cid!,
                ownCapabilities: [ChannelCapability.skipSlowMode.rawValue],
                cooldownDuration: 30
            ),
            messages: [
                .dummy(
                    messageId: .unique,
                    authorUserId: currentUserId,
                    createdAt: messageDate
                )
            ]
        )
        
        // Load the channel data through normal API flow
        controller.synchronize()
        client.mockAPIClient.test_simulateResponse(.success(channelPayload))
        
        // When
        let cooldownTime = controller.currentCooldownTime()
        
        // Then
        XCTAssertEqual(cooldownTime, 0)
    }
}

class MockPaginationStateHandler: MessagesPaginationStateHandling {
    init() {
        state = .initial
    }

    var state: MessagesPaginationState

    var beginCallCount = 0
    var endCallCount = 0

    func begin(pagination: MessagesPagination) {
        beginCallCount += 1
    }
    
    func end(pagination: MessagesPagination, with result: Result<[MessagePayload], any Error>) {
        endCallCount += 1
    }
}
