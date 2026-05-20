//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

/// Tests for `LivestreamChat` focused on wrapper-specific behaviour:
/// API wiring, sync repository tracking, manual event registration, and
/// forwarding to the underlying `LivestreamChannelHandler`.
///
/// Handler-internal behaviour (event handling, pagination state, message
/// pruning, typing aggregation, cooldown, etc.) is exercised in
/// `LivestreamChannelHandler_Tests`.
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
        let state = livestreamChat.state
        XCTAssertEqual(state.cid, channelQuery.cid)
        XCTAssertEqual(state.channelQuery.cid, channelQuery.cid)
        XCTAssertNil(state.channel)
        XCTAssertTrue(state.messages.isEmpty)
        XCTAssertFalse(state.isPaused)
        XCTAssertEqual(state.skippedMessagesAmount, 0)
        XCTAssertTrue(state.typingUsers.isEmpty)
        XCTAssertEqual(state.remainingCooldownDuration, 0)
        XCTAssertTrue(state.client === client)

        XCTAssertTrue(state.hasLoadedAllNewestMessages)
        XCTAssertFalse(state.hasLoadedAllOldestMessages)
        XCTAssertFalse(state.isLoadingNewerMessages)
        XCTAssertFalse(state.isLoadingOlderMessages)
        XCTAssertFalse(state.isLoadingMiddleMessages)
        XCTAssertFalse(state.isJumpingToMessage)
    }

    func test_init_withoutCid_doesNotRegisterManualEventHandling() async {
        let client = ChatClient_Mock.mock()
        let eventNotificationCenter = EventNotificationCenter_Mock(
            database: DatabaseContainer_Spy()
        )
        client.mockedEventNotificationCenter = eventNotificationCenter

        let livestreamChat = LivestreamChat(channelQuery: makeChannelQueryWithoutCid(), client: client)
        _ = livestreamChat.state

        XCTAssertEqual(eventNotificationCenter.registerManualEventHandling_callCount, 0)
    }

    // MARK: - Configuration Forwarding

    func test_configurationProperties_areForwardedToHandler() {
        let (livestreamChat, mockHandler) = makeLivestreamChatWithMockHandler()
        _ = livestreamChat.state

        XCTAssertTrue(livestreamChat.loadInitialMessagesFromCache)
        XCTAssertFalse(livestreamChat.countSkippedMessagesWhenPaused)
        XCTAssertNil(livestreamChat.maxMessageLimitOptions)

        livestreamChat.loadInitialMessagesFromCache = false
        livestreamChat.countSkippedMessagesWhenPaused = true
        livestreamChat.maxMessageLimitOptions = .recommended

        XCTAssertFalse(mockHandler.loadInitialMessagesFromCache)
        XCTAssertTrue(mockHandler.countSkippedMessagesWhenPaused)
        XCTAssertEqual(mockHandler.maxMessageLimitOptions?.maxLimit, 200)
        XCTAssertEqual(mockHandler.maxMessageLimitOptions?.discardAmount, 50)

        XCTAssertFalse(livestreamChat.loadInitialMessagesFromCache)
        XCTAssertTrue(livestreamChat.countSkippedMessagesWhenPaused)
        XCTAssertNotNil(livestreamChat.maxMessageLimitOptions)
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

    func test_get_callsCorrectAPIEndpoint() async throws {
        client.mockAPIClient.test_mockResponseResult(
            .success(ChannelPayload.dummy(channel: .dummy(cid: channelQuery.cid!)))
        )

        try await livestreamChat.get()

        let expectedEndpoint = Endpoint<ChannelPayload>.updateChannel(query: channelQuery)
        XCTAssertEqual(client.mockAPIClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }

    func test_get_callsPopulateFromCacheOnHandler() async throws {
        let (livestreamChat, mockHandler) = makeLivestreamChatWithMockHandler()
        _ = livestreamChat.state

        client.mockAPIClient.test_mockResponseResult(
            .success(ChannelPayload.dummy(channel: .dummy(cid: channelQuery.cid!)))
        )
        try await livestreamChat.get()

        XCTAssertEqual(mockHandler.populateFromCacheIfEnabled_callCount, 1)
        XCTAssertEqual(mockHandler.beginPagination_callCount, 1)
        XCTAssertEqual(mockHandler.handleChannelPayload_callCount, 1)
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

    func test_watch_withoutCid_throwsChannelNotCreatedYet() async {
        let livestreamChat = makeLivestreamChatWithoutCid()

        do {
            try await livestreamChat.watch()
            XCTFail("Expected ChannelNotCreatedYet error")
        } catch {
            XCTAssertTrue(error is ClientError.ChannelNotCreatedYet)
        }
    }

    func test_stopWatching_withoutCid_throwsChannelNotCreatedYet() async {
        let livestreamChat = makeLivestreamChatWithoutCid()

        do {
            try await livestreamChat.stopWatching()
            XCTFail("Expected ChannelNotCreatedYet error")
        } catch {
            XCTAssertTrue(error is ClientError.ChannelNotCreatedYet)
        }
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

    func test_loadOlderMessages_withoutMessageId_usesOldestLoadedMessageId() async throws {
        try await jumpToMidPageAndClear()
        client.mockAPIClient.test_mockResponseResult(
            .success(ChannelPayload.dummy(channel: .dummy(cid: channelQuery.cid!)))
        )

        try await livestreamChat.loadOlderMessages()

        var expectedQuery = channelQuery!
        expectedQuery.pagination = MessagesPagination(pageSize: 25, parameter: .lessThan("older"))
        let expectedEndpoint = Endpoint<ChannelPayload>.updateChannel(query: expectedQuery)
        XCTAssertEqual(client.mockAPIClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }

    func test_loadNewerMessages_withMessageId_callsCorrectAPI() async throws {
        try await jumpToMidPageAndClear()
        client.mockAPIClient.test_mockResponseResult(
            .success(ChannelPayload.dummy(channel: .dummy(cid: channelQuery.cid!)))
        )

        try await livestreamChat.loadNewerMessages(after: "newer-message-id", limit: 30)

        var expectedQuery = channelQuery!
        expectedQuery.pagination = MessagesPagination(pageSize: 30, parameter: .greaterThan("newer-message-id"))
        let expectedEndpoint = Endpoint<ChannelPayload>.updateChannel(query: expectedQuery)
        XCTAssertEqual(client.mockAPIClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }

    func test_loadNewerMessages_withoutMessageId_usesNewestLoadedMessageId() async throws {
        try await jumpToMidPageAndClear()
        client.mockAPIClient.test_mockResponseResult(
            .success(ChannelPayload.dummy(channel: .dummy(cid: channelQuery.cid!)))
        )

        try await livestreamChat.loadNewerMessages()

        var expectedQuery = channelQuery!
        expectedQuery.pagination = MessagesPagination(pageSize: 25, parameter: .greaterThan("newer"))
        let expectedEndpoint = Endpoint<ChannelPayload>.updateChannel(query: expectedQuery)
        XCTAssertEqual(client.mockAPIClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }

    // MARK: - Pause / Resume

    func test_pause_forwardsToHandler() {
        let (livestreamChat, mockHandler) = makeLivestreamChatWithMockHandler()
        _ = livestreamChat.state

        livestreamChat.pause()

        XCTAssertEqual(mockHandler.pause_callCount, 1)
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

    // MARK: - Event Forwarding

    func test_didReceiveEvent_forwardsToHandler() async {
        let (livestreamChat, mockHandler) = makeLivestreamChatWithMockHandler()
        _ = livestreamChat.state

        let event = MessageNewEvent(
            user: .mock(id: .unique),
            message: .mock(id: "new", cid: channelQuery.cid!, text: "New"),
            channel: .mock(cid: channelQuery.cid!),
            createdAt: .unique,
            watcherCount: nil,
            unreadCount: nil
        )
        livestreamChat.didReceiveEvent(event)

        XCTAssertEqual(mockHandler.didReceiveEvent_callCount, 1)
        XCTAssertTrue(mockHandler.didReceiveEvent_event is MessageNewEvent)
    }

    func test_didReceiveEvent_notificationAddedToChannelEvent_callsWatch() async throws {
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

        try await waitForRequest()
        let expectedQuery = ChannelQuery(cid: channelQuery.cid!)
        let expectedEndpoint = Endpoint<ChannelPayload>.updateChannel(query: expectedQuery)
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), client.mockAPIClient.request_endpoint)
    }

    // MARK: - State Forwarding via Mock Handler

    func test_handlerCallbacks_updateStateProperties() async {
        let (livestreamChat, mockHandler) = makeLivestreamChatWithMockHandler()
        let state = livestreamChat.state

        let channel = ChatChannel.mock(cid: channelQuery.cid!, name: "Live")
        mockHandler.simulateChannelDidChange(channel)
        XCTAssertEqual(state.channel?.name, "Live")

        let messages = [ChatMessage.mock(id: "m1"), ChatMessage.mock(id: "m2")]
        mockHandler.simulateMessagesDidChange(messages)
        XCTAssertEqual(state.messages.map(\.id), ["m1", "m2"])

        mockHandler.simulatePauseDidChange(true)
        XCTAssertTrue(state.isPaused)

        mockHandler.simulateSkippedMessagesAmountDidChange(7)
        XCTAssertEqual(state.skippedMessagesAmount, 7)

        let typingUser = ChatUser.mock(id: "user-1")
        mockHandler.simulateTypingUsersDidChange([typingUser])
        XCTAssertEqual(state.typingUsers.map(\.id), [typingUser.id])
    }

    func test_remainingCooldownDuration_returnsValueFromHandler() {
        let (livestreamChat, mockHandler) = makeLivestreamChatWithMockHandler()
        let state = livestreamChat.state

        mockHandler.stubbedCurrentCooldownTime = 5
        XCTAssertEqual(state.remainingCooldownDuration, 5)

        mockHandler.stubbedCurrentCooldownTime = 0
        XCTAssertEqual(state.remainingCooldownDuration, 0)
    }

    // MARK: - Message Actions

    func test_deleteMessage_callsCorrectAPI() async throws {
        client.mockAPIClient.test_mockResponseResult(
            Result<MessagePayload.Boxed, Error>.success(MessagePayload.Boxed(message: .dummy(messageId: "msg-1")))
        )

        try await livestreamChat.deleteMessage("msg-1")

        let expectedEndpoint = Endpoint<MessagePayload.Boxed>.deleteMessage(messageId: "msg-1", hard: false)
        XCTAssertEqual(client.mockAPIClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }

    func test_deleteMessage_withHardTrue_callsCorrectAPI() async throws {
        client.mockAPIClient.test_mockResponseResult(
            Result<MessagePayload.Boxed, Error>.success(MessagePayload.Boxed(message: .dummy(messageId: "msg-1")))
        )

        try await livestreamChat.deleteMessage("msg-1", hard: true)

        let expectedEndpoint = Endpoint<MessagePayload.Boxed>.deleteMessage(messageId: "msg-1", hard: true)
        XCTAssertEqual(client.mockAPIClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }

    func test_deleteMessage_propagatesAPIErrors() async {
        let testError = TestError()
        client.mockAPIClient.test_mockResponseResult(Result<MessagePayload.Boxed, Error>.failure(testError))

        do {
            try await livestreamChat.deleteMessage("msg-1")
            XCTFail("Expected failure")
        } catch {
            XCTAssertTrue(error is TestError)
        }
    }

    func test_flagMessage_callsCorrectAPI() async throws {
        client.mockAPIClient.test_mockResponseResult(
            Result<FlagMessagePayload, Error>.success(.init(currentUser: .dummy(userId: .unique), flaggedMessageId: "msg-1"))
        )

        try await livestreamChat.flagMessage("msg-1", reason: "spam", extraData: ["k": .string("v")])

        let expectedEndpoint = Endpoint<FlagMessagePayload>.flagMessage(
            true,
            with: "msg-1",
            reason: "spam",
            extraData: ["k": .string("v")]
        )
        XCTAssertEqual(client.mockAPIClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }

    func test_unflagMessage_callsCorrectAPI() async throws {
        client.mockAPIClient.test_mockResponseResult(
            Result<FlagMessagePayload, Error>.success(.init(currentUser: .dummy(userId: .unique), flaggedMessageId: "msg-1"))
        )

        try await livestreamChat.unflagMessage("msg-1")

        let expectedEndpoint = Endpoint<FlagMessagePayload>.flagMessage(
            false,
            with: "msg-1",
            reason: nil,
            extraData: nil
        )
        XCTAssertEqual(client.mockAPIClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }

    // MARK: - Message Reactions

    func test_sendReaction_callsCorrectAPI() async throws {
        client.mockAPIClient.test_mockResponseResult(Result<EmptyResponse, Error>.success(EmptyResponse()))

        let reactionType = MessageReactionType(rawValue: "like")
        try await livestreamChat.sendReaction(
            to: "msg-1",
            with: reactionType,
            score: 2,
            enforceUnique: true,
            skipPush: true,
            pushEmojiCode: "👍",
            extraData: ["k": .string("v")]
        )

        let expectedEndpoint = Endpoint<EmptyResponse>.addReaction(
            reactionType,
            score: 2,
            enforceUnique: true,
            extraData: ["k": .string("v")],
            skipPush: true,
            emojiCode: "👍",
            messageId: "msg-1"
        )
        XCTAssertEqual(client.mockAPIClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }

    func test_deleteReaction_callsCorrectAPI() async throws {
        client.mockAPIClient.test_mockResponseResult(Result<EmptyResponse, Error>.success(EmptyResponse()))

        let reactionType = MessageReactionType(rawValue: "like")
        try await livestreamChat.deleteReaction(from: "msg-1", with: reactionType)

        let expectedEndpoint = Endpoint<EmptyResponse>.deleteReaction(reactionType, messageId: "msg-1")
        XCTAssertEqual(client.mockAPIClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }

    func test_loadReactions_callsCorrectAPIAndReturnsReactions() async throws {
        let messageId = MessageId.unique
        let reactionType = MessageReactionType(rawValue: "like")
        let reactionPayload = MessageReactionPayload.dummy(
            type: reactionType,
            messageId: messageId,
            user: .dummy(userId: .unique)
        )
        let payload = MessageReactionsPayload(reactions: [reactionPayload])
        client.mockAPIClient.test_mockResponseResult(Result<MessageReactionsPayload, Error>.success(payload))

        let reactions = try await livestreamChat.loadReactions(for: messageId, limit: 10, offset: 5)

        let expectedEndpoint = Endpoint<MessageReactionsPayload>.loadReactions(
            messageId: messageId,
            pagination: .init(pageSize: 10, offset: 5)
        )
        XCTAssertEqual(client.mockAPIClient.request_endpoint, AnyEndpoint(expectedEndpoint))
        XCTAssertEqual(reactions.count, 1)
        XCTAssertEqual(reactions.first?.type, reactionType)
    }

    // MARK: - Message Pinning

    func test_pinMessage_callsCorrectAPI() async throws {
        client.mockAPIClient.test_mockResponseResult(Result<EmptyResponse, Error>.success(EmptyResponse()))

        try await livestreamChat.pinMessage("msg-1")

        let expectedEndpoint = Endpoint<EmptyResponse>.pinMessage(
            messageId: "msg-1",
            request: .init(set: .init(pinned: true))
        )
        XCTAssertEqual(client.mockAPIClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }

    func test_unpinMessage_callsCorrectAPI() async throws {
        client.mockAPIClient.test_mockResponseResult(Result<EmptyResponse, Error>.success(EmptyResponse()))

        try await livestreamChat.unpinMessage("msg-1")

        let expectedEndpoint = Endpoint<EmptyResponse>.pinMessage(
            messageId: "msg-1",
            request: .init(set: .init(pinned: false))
        )
        XCTAssertEqual(client.mockAPIClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }

    func test_loadPinnedMessages_callsCorrectAPI() async throws {
        client.mockAPIClient.test_mockResponseResult(
            Result<PinnedMessagesPayload, Error>.success(.init(messages: []))
        )

        _ = try await livestreamChat.loadPinnedMessages(pageSize: 15)

        let expectedQuery = PinnedMessagesQuery(pageSize: 15, sorting: [], pagination: nil)
        let expectedEndpoint = Endpoint<PinnedMessagesPayload>.pinnedMessages(
            cid: channelQuery.cid!,
            query: expectedQuery
        )
        XCTAssertEqual(client.mockAPIClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }

    // MARK: - Slow Mode

    func test_enableSlowMode_callsCorrectAPI() async throws {
        client.mockAPIClient.test_mockResponseResult(Result<EmptyResponse, Error>.success(EmptyResponse()))

        try await livestreamChat.enableSlowMode(cooldownDuration: 7)

        let expectedEndpoint = Endpoint<EmptyResponse>.enableSlowMode(
            cid: channelQuery.cid!,
            cooldownDuration: 7
        )
        XCTAssertEqual(client.mockAPIClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }

    func test_disableSlowMode_callsAPIWithZeroCooldown() async throws {
        client.mockAPIClient.test_mockResponseResult(Result<EmptyResponse, Error>.success(EmptyResponse()))

        try await livestreamChat.disableSlowMode()

        let expectedEndpoint = Endpoint<EmptyResponse>.enableSlowMode(
            cid: channelQuery.cid!,
            cooldownDuration: 0
        )
        XCTAssertEqual(client.mockAPIClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }

    // MARK: - Channel Freezing

    func test_freeze_callsCorrectAPI() async throws {
        client.mockAPIClient.test_mockResponseResult(Result<EmptyResponse, Error>.success(EmptyResponse()))

        try await livestreamChat.freeze()

        let expectedEndpoint = Endpoint<EmptyResponse>.freezeChannel(true, cid: channelQuery.cid!)
        XCTAssertEqual(client.mockAPIClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }

    func test_unfreeze_callsCorrectAPI() async throws {
        client.mockAPIClient.test_mockResponseResult(Result<EmptyResponse, Error>.success(EmptyResponse()))

        try await livestreamChat.unfreeze()

        let expectedEndpoint = Endpoint<EmptyResponse>.freezeChannel(false, cid: channelQuery.cid!)
        XCTAssertEqual(client.mockAPIClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }

    // MARK: - Typing Indicators

    func test_keystroke_whenChannelIsNotLoaded_doesNotMakeAPIRequest() async throws {
        try await livestreamChat.keystroke()

        XCTAssertNil(client.mockAPIClient.request_endpoint)
    }

    func test_stopTyping_whenChannelIsNotLoaded_doesNotMakeAPIRequest() async throws {
        try await livestreamChat.stopTyping()

        XCTAssertNil(client.mockAPIClient.request_endpoint)
    }

    func test_keystroke_whenChannelCannotSendTypingEvents_doesNotMakeAPIRequest() async throws {
        client.mockAPIClient.test_mockResponseResult(
            .success(ChannelPayload.dummy(channel: .dummy(cid: channelQuery.cid!, ownCapabilities: [])))
        )
        try await livestreamChat.get()
        client.mockAPIClient.cleanUp()

        try await livestreamChat.keystroke()

        XCTAssertNil(client.mockAPIClient.request_endpoint)
    }

    func test_keystroke_withoutCid_throwsChannelNotCreatedYet() async {
        let livestreamChat = makeLivestreamChatWithoutCid()

        do {
            try await livestreamChat.keystroke()
            XCTFail("Expected ChannelNotCreatedYet error")
        } catch {
            XCTAssertTrue(error is ClientError.ChannelNotCreatedYet)
        }
    }

    // MARK: - App State

    func test_applicationDidReceiveMemoryWarning_triggersLoadFirstPage() async throws {
        client.mockAPIClient.test_mockResponseResult(
            .success(ChannelPayload.dummy(channel: .dummy(cid: channelQuery.cid!)))
        )

        livestreamChat.applicationDidReceiveMemoryWarning()

        try await waitForRequest()
        var expectedQuery = channelQuery!
        expectedQuery.pagination = MessagesPagination(pageSize: 25, parameter: nil)
        let expectedEndpoint = Endpoint<ChannelPayload>.updateChannel(query: expectedQuery)
        XCTAssertEqual(client.mockAPIClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }

    func test_applicationDidMoveToForeground_whenDisconnected_triggersLoadFirstPage() async throws {
        client.mockAPIClient.test_mockResponseResult(
            .success(ChannelPayload.dummy(channel: .dummy(cid: channelQuery.cid!)))
        )

        livestreamChat.applicationDidMoveToForeground()

        try await waitForRequest()
        var expectedQuery = channelQuery!
        expectedQuery.pagination = MessagesPagination(pageSize: 25, parameter: nil)
        let expectedEndpoint = Endpoint<ChannelPayload>.updateChannel(query: expectedQuery)
        XCTAssertEqual(client.mockAPIClient.request_endpoint, AnyEndpoint(expectedEndpoint))
    }
}

// MARK: - Helpers

private extension LivestreamChat_Tests {
    func waitForMainQueue() async {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async { continuation.resume() }
        }
    }

    /// Polls until a request is recorded on the spy or a timeout is reached.
    func waitForRequest(timeoutMilliseconds: Int = 500) async throws {
        let pollIntervalMs = 50
        let maxIterations = max(1, timeoutMilliseconds / pollIntervalMs)
        for _ in 0..<maxIterations {
            if client.mockAPIClient.request_endpoint != nil { return }
            await waitForMainQueue()
            try await Task.sleep(nanoseconds: UInt64(pollIntervalMs) * 1_000_000)
        }
    }

    /// Loads a 2-message page around the older message so the pagination state ends up with both
    /// `hasLoadedAllNextMessages` and `hasLoadedAllPreviousMessages` set to `false`. This avoids the
    /// short-circuits in `loadOlderMessages` / `loadNewerMessages` for tests that only care about
    /// the resulting endpoint.
    func jumpToMidPageAndClear() async throws {
        let cid = channelQuery.cid!
        let payload = ChannelPayload.dummy(
            channel: .dummy(cid: cid),
            messages: [
                .dummy(messageId: "older", text: "Older"),
                .dummy(messageId: "newer", text: "Newer")
            ]
        )
        client.mockAPIClient.test_mockResponseResult(.success(payload))
        try await livestreamChat.loadMessages(around: "older", limit: 2)
        client.mockAPIClient.cleanUp()
    }

    func makeChannelQueryWithoutCid() -> ChannelQuery {
        let payload = ChannelEditDetailPayload(
            type: .messaging,
            name: nil,
            imageURL: nil,
            team: nil,
            members: [],
            invites: [],
            filterTags: [],
            extraData: [:]
        )
        return ChannelQuery(channelPayload: payload)
    }

    func makeLivestreamChatWithoutCid() -> LivestreamChat {
        let livestreamChat = LivestreamChat(channelQuery: makeChannelQueryWithoutCid(), client: client)
        _ = livestreamChat.state
        return livestreamChat
    }

    /// Builds a `LivestreamChat` whose underlying `LivestreamChannelHandler` is the returned
    /// mock. Used for wiring tests that verify `LivestreamChat` forwards calls and that
    /// handler callbacks update the published state.
    func makeLivestreamChatWithMockHandler() -> (LivestreamChat, LivestreamChannelHandler_Mock) {
        let mockHandler = LivestreamChannelHandler_Mock(
            channelQuery: channelQuery,
            client: client,
            paginationStateHandler: MessagesPaginationStateHandler()
        )
        var environment = LivestreamChat.Environment()
        environment.handlerBuilder = { _, _, _ in mockHandler }
        let livestreamChat = LivestreamChat(
            channelQuery: channelQuery,
            client: client,
            environment: environment
        )
        return (livestreamChat, mockHandler)
    }
}
