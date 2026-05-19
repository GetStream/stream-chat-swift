//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

@MainActor
final class LivestreamChat_Tests: XCTestCase {
    private var client: ChatClient_Mock!
    private var channelQuery: ChannelQuery!
    private var livestreamChat: LivestreamChat!

    override func setUp() async throws {
        try await super.setUp()
        client = ChatClient.mock(config: ChatClient_Mock.defaultMockedConfig)
        channelQuery = ChannelQuery(cid: .unique)
        livestreamChat = LivestreamChat(channelQuery: channelQuery, client: client)
        _ = livestreamChat.state
    }

    override func tearDown() async throws {
        livestreamChat = nil
        channelQuery = nil
        client.cleanUp()
        client = nil
        try await super.tearDown()
    }

    // MARK: - Initialization

    func test_init_registersForManualEventHandling() async {
        let cid = ChannelId.unique
        let client = ChatClient_Mock.mock()
        let eventNotificationCenter = EventNotificationCenter_Mock(
            database: DatabaseContainer_Spy()
        )
        client.mockedEventNotificationCenter = eventNotificationCenter
        let livestreamChat = LivestreamChat(channelQuery: ChannelQuery(cid: cid), client: client)
        _ = livestreamChat.state

        XCTAssertEqual(eventNotificationCenter.registerManualEventHandling_callCount, 1)
        XCTAssertEqual(eventNotificationCenter.registerManualEventHandling_calledWith, cid)
    }

    func test_deinit_unregistersFromManualEventHandling() async {
        let cid = ChannelId.unique
        let client = ChatClient_Mock.mock()
        let eventNotificationCenter = EventNotificationCenter_Mock(
            database: DatabaseContainer_Spy()
        )
        client.mockedEventNotificationCenter = eventNotificationCenter

        var livestreamChat: LivestreamChat? = LivestreamChat(channelQuery: ChannelQuery(cid: cid), client: client)
        _ = livestreamChat?.state
        livestreamChat = nil

        XCTAssertEqual(eventNotificationCenter.unregisterManualEventHandling_callCount, 1)
        XCTAssertEqual(eventNotificationCenter.unregisterManualEventHandling_calledWith, cid)
    }

    func test_init_stateInitiallyEmpty() {
        XCTAssertEqual(livestreamChat.state.cid, channelQuery.cid)
        XCTAssertNil(livestreamChat.state.channel)
        XCTAssertTrue(livestreamChat.state.messages.isEmpty)
        XCTAssertFalse(livestreamChat.state.isPaused)
        XCTAssertEqual(livestreamChat.state.skippedMessagesAmount, 0)
        XCTAssertTrue(livestreamChat.state.typingUsers.isEmpty)
    }

    // MARK: - Get

    func test_get_whenAPISucceeds_thenStateIsUpdated() async throws {
        let cid = channelQuery.cid!
        let channelPayload = ChannelPayload.dummy(
            channel: .dummy(cid: cid),
            messages: [
                .dummy(messageId: "1", text: "Message 1"),
                .dummy(messageId: "2", text: "Message 2")
            ]
        )

        client.mockAPIClient.test_mockResponseResult(.success(channelPayload))

        try await livestreamChat.get()

        XCTAssertEqual(livestreamChat.state.channel?.cid, cid)
        XCTAssertEqual(livestreamChat.state.messages.map(\.id), ["2", "1"])
    }

    func test_get_whenAPIFails_thenErrorIsThrown() async {
        let testError = TestError()
        client.mockAPIClient.test_mockResponseResult(Result<ChannelPayload, Error>.failure(testError))

        do {
            try await livestreamChat.get()
            XCTFail("Expected failure")
        } catch {
            XCTAssertTrue(error is TestError)
        }

        XCTAssertNil(livestreamChat.state.channel)
        XCTAssertTrue(livestreamChat.state.messages.isEmpty)
    }

    func test_get_tracksLivestreamChatInSyncRepository() async throws {
        let channelPayload = ChannelPayload.dummy(
            channel: .dummy(cid: channelQuery.cid!)
        )
        client.mockAPIClient.test_mockResponseResult(.success(channelPayload))

        try await livestreamChat.get()

        XCTAssertEqual(client.syncRepository.activeLivestreamChats.count, 1)
    }

    // MARK: - Watching

    func test_watch_callsCorrectAPI() async throws {
        client.mockAPIClient.test_mockResponseResult(
            .success(ChannelPayload.dummy(channel: .dummy(cid: channelQuery.cid!)))
        )

        try await livestreamChat.watch()

        let expectedQuery = ChannelQuery(cid: channelQuery.cid!)
        let expectedEndpoint = Endpoint<ChannelPayload>.updateChannel(query: expectedQuery)
        XCTAssertEqual(client.mockAPIClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }

    func test_watch_tracksLivestreamChatInSyncRepository() async throws {
        client.mockAPIClient.test_mockResponseResult(
            .success(ChannelPayload.dummy(channel: .dummy(cid: channelQuery.cid!)))
        )

        try await livestreamChat.watch()

        XCTAssertEqual(client.syncRepository.activeLivestreamChats.count, 1)
    }

    func test_stopWatching_callsCorrectAPI() async throws {
        client.mockAPIClient.test_mockResponseResult(Result<EmptyResponse, Error>.success(EmptyResponse()))

        try await livestreamChat.stopWatching()

        let expectedEndpoint = Endpoint<EmptyResponse>.stopWatching(cid: channelQuery.cid!)
        XCTAssertEqual(client.mockAPIClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }

    func test_stopWatching_removesActiveLivestreamChat() async throws {
        client.mockAPIClient.test_mockResponseResult(
            .success(ChannelPayload.dummy(channel: .dummy(cid: channelQuery.cid!)))
        )
        try await livestreamChat.watch()
        XCTAssertEqual(client.syncRepository.activeLivestreamChats.count, 1)

        client.mockAPIClient.test_mockResponseResult(Result<EmptyResponse, Error>.success(EmptyResponse()))
        try await livestreamChat.stopWatching()

        XCTAssertEqual(client.syncRepository.activeLivestreamChats.count, 0)
    }

    // MARK: - Pagination

    func test_loadFirstPage_callsCorrectAPI() async throws {
        client.mockAPIClient.test_mockResponseResult(
            .success(ChannelPayload.dummy(channel: .dummy(cid: channelQuery.cid!)))
        )

        try await livestreamChat.loadFirstPage()

        var expectedQuery = channelQuery!
        expectedQuery.pagination = MessagesPagination(pageSize: 25, parameter: nil)
        let expectedEndpoint = Endpoint<ChannelPayload>.updateChannel(query: expectedQuery)
        XCTAssertEqual(client.mockAPIClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }

    func test_loadOlderMessages_withMessageId_callsCorrectAPI() async throws {
        client.mockAPIClient.test_mockResponseResult(
            .success(ChannelPayload.dummy(channel: .dummy(cid: channelQuery.cid!)))
        )

        try await livestreamChat.loadOlderMessages(before: "specific-message-id", limit: 50)

        var expectedQuery = channelQuery!
        expectedQuery.pagination = MessagesPagination(pageSize: 50, parameter: .lessThan("specific-message-id"))
        let expectedEndpoint = Endpoint<ChannelPayload>.updateChannel(query: expectedQuery)
        XCTAssertEqual(client.mockAPIClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }

    func test_loadOlderMessages_withoutMessages_throwsChannelEmptyMessages() async {
        do {
            try await livestreamChat.loadOlderMessages()
            XCTFail("Expected ChannelEmptyMessages error")
        } catch {
            XCTAssertTrue(error is ClientError.ChannelEmptyMessages)
        }
    }

    func test_loadMessagesAround_callsCorrectAPI() async throws {
        client.mockAPIClient.test_mockResponseResult(
            .success(ChannelPayload.dummy(channel: .dummy(cid: channelQuery.cid!)))
        )

        try await livestreamChat.loadMessages(around: "target", limit: 40)

        var expectedQuery = channelQuery!
        expectedQuery.pagination = MessagesPagination(pageSize: 40, parameter: .around("target"))
        let expectedEndpoint = Endpoint<ChannelPayload>.updateChannel(query: expectedQuery)
        XCTAssertEqual(client.mockAPIClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }

    // MARK: - Pause / Resume

    func test_pause_setsIsPausedToTrue() async {
        XCTAssertFalse(livestreamChat.state.isPaused)
        livestreamChat.pause()

        // The pause handler dispatches asynchronously to main, so spin the run loop.
        await waitForMainQueue()
        XCTAssertTrue(livestreamChat.state.isPaused)
    }

    func test_resume_loadsFirstPageAndSetsIsPausedToFalse() async throws {
        livestreamChat.pause()
        await waitForMainQueue()
        XCTAssertTrue(livestreamChat.state.isPaused)

        client.mockAPIClient.test_mockResponseResult(
            .success(ChannelPayload.dummy(channel: .dummy(cid: channelQuery.cid!)))
        )

        try await livestreamChat.resume()
        await waitForMainQueue()

        XCTAssertFalse(livestreamChat.state.isPaused)
        var expectedQuery = channelQuery!
        expectedQuery.pagination = MessagesPagination(pageSize: 25, parameter: nil)
        let expectedEndpoint = Endpoint<ChannelPayload>.updateChannel(query: expectedQuery)
        XCTAssertEqual(client.mockAPIClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }

    func test_resume_whenNotPaused_doesNothing() async throws {
        XCTAssertFalse(livestreamChat.state.isPaused)

        try await livestreamChat.resume()

        XCTAssertNil(client.mockAPIClient.request_endpoint)
    }

    // MARK: - Event Handling

    func test_didReceiveEvent_messageNewEvent_addsMessageToState() async throws {
        // Load the first page so the engine considers the channel loaded.
        client.mockAPIClient.test_mockResponseResult(
            .success(ChannelPayload.dummy(channel: .dummy(cid: channelQuery.cid!)))
        )
        try await livestreamChat.get()
        await waitForMainQueue()

        let newMessage = ChatMessage.mock(id: "new", cid: channelQuery.cid!, text: "New message")
        let event = MessageNewEvent(
            user: .mock(id: .unique),
            message: newMessage,
            channel: .mock(cid: channelQuery.cid!),
            createdAt: .unique,
            watcherCount: nil,
            unreadCount: nil
        )

        livestreamChat.didReceiveEvent(event)
        await waitForMainQueue()

        XCTAssertEqual(["new"], livestreamChat.state.messages.map(\.id))
    }

    func test_didReceiveEvent_notificationAddedToChannelEvent_callsWatch() async throws {
        // Load initial channel data first.
        client.mockAPIClient.test_mockResponseResult(
            .success(ChannelPayload.dummy(channel: .dummy(cid: channelQuery.cid!)))
        )
        try await livestreamChat.get()
        client.mockAPIClient.cleanUp()

        client.mockAPIClient.test_mockResponseResult(
            .success(ChannelPayload.dummy(channel: .dummy(cid: channelQuery.cid!)))
        )

        let event = NotificationAddedToChannelEvent(
            channel: .mock(cid: channelQuery.cid!),
            unreadCount: nil,
            member: .dummy,
            createdAt: .unique
        )
        livestreamChat.didReceiveEvent(event)

        // The watch() call is dispatched on a Task so we wait briefly.
        for _ in 0..<10 {
            if client.mockAPIClient.request_endpoint != nil { break }
            await waitForMainQueue()
            try await Task.sleep(nanoseconds: 50_000_000)
        }

        let expectedQuery = ChannelQuery(cid: channelQuery.cid!)
        let expectedEndpoint = Endpoint<ChannelPayload>.updateChannel(query: expectedQuery)
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), client.mockAPIClient.request_endpoint)
    }
}

// MARK: - Helpers

private extension LivestreamChat_Tests {
    func waitForMainQueue() async {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async { continuation.resume() }
        }
    }
}
