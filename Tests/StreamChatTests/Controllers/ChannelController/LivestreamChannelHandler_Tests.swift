//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

/// Tests that exercise `LivestreamChannelHandler` in isolation. These cover the shared
/// in-memory state, event handling, pause/resume bookkeeping, message limit application,
/// cooldown calculation and typing cleanup that both `LivestreamChannelController` and
/// `LivestreamChat` rely on.
///
/// Wrappers are tested separately and only verify wiring/forwarding — they use a mock
/// handler so the same handler behavior is not re-exercised through the wrapper.
final class LivestreamChannelHandler_Tests: XCTestCase {
    private var client: ChatClient_Mock!
    private var cid: ChannelId!
    private var handler: LivestreamChannelHandler!

    override func setUp() {
        super.setUp()
        client = ChatClient.mock(config: ChatClient_Mock.defaultMockedConfig)
        cid = .unique
        handler = LivestreamChannelHandler(channelQuery: ChannelQuery(cid: cid), client: client)
    }

    override func tearDown() {
        handler = nil
        cid = nil
        client?.cleanUp()
        client = nil
        super.tearDown()
    }
}

// MARK: - Initial State & Configuration

extension LivestreamChannelHandler_Tests {
    func test_initialState_isEmpty() {
        XCTAssertEqual(handler.cid, cid)
        XCTAssertNil(handler.channel)
        XCTAssertTrue(handler.messages.isEmpty)
        XCTAssertFalse(handler.isPaused)
        XCTAssertEqual(handler.skippedMessagesAmount, 0)
    }

    func test_configurationDefaults() {
        XCTAssertNil(handler.maxMessageLimitOptions)
        XCTAssertFalse(handler.countSkippedMessagesWhenPaused)
        XCTAssertTrue(handler.loadInitialMessagesFromCache)
        XCTAssertTrue(handler.timerType == DefaultTimer.self)
    }

    func test_paginationFlags_initialValues() {
        // `hasLoadedAllNextMessages` is true when there are no messages, by design.
        XCTAssertTrue(handler.hasLoadedAllNextMessages)
        XCTAssertFalse(handler.hasLoadedAllPreviousMessages)
        XCTAssertFalse(handler.isLoadingPreviousMessages)
        XCTAssertFalse(handler.isLoadingNextMessages)
        XCTAssertFalse(handler.isLoadingMiddleMessages)
        XCTAssertFalse(handler.isJumpingToMessage)
    }

    func test_setChannelQuery_updatesQuery() {
        let newCid = ChannelId.unique
        handler.setChannelQuery(ChannelQuery(cid: newCid))
        XCTAssertEqual(handler.cid, newCid)
    }
}

// MARK: - populateFromCacheIfEnabled

extension LivestreamChannelHandler_Tests {
    func test_populateFromCacheIfEnabled_loadsChannelAndMessagesFromDataStore() throws {
        let cachedMessage = MessagePayload.dummy(messageId: "cached", text: "Cached")
        let payload = ChannelPayload.dummy(channel: .dummy(cid: cid), messages: [cachedMessage])
        try client.databaseContainer.writeSynchronously { session in
            try session.saveChannel(payload: payload)
        }

        handler.populateFromCacheIfEnabled()

        XCTAssertEqual(handler.channel?.cid, cid)
        XCTAssertEqual(handler.messages.map(\.id), ["cached"])
    }

    func test_populateFromCacheIfEnabled_whenDisabled_doesNotLoadFromDataStore() throws {
        let payload = ChannelPayload.dummy(
            channel: .dummy(cid: cid),
            messages: [.dummy(messageId: "cached", text: "Cached")]
        )
        try client.databaseContainer.writeSynchronously { session in
            try session.saveChannel(payload: payload)
        }

        handler.loadInitialMessagesFromCache = false
        handler.populateFromCacheIfEnabled()

        XCTAssertNil(handler.channel)
        XCTAssertTrue(handler.messages.isEmpty)
    }
}

// MARK: - handleChannelPayload

extension LivestreamChannelHandler_Tests {
    func test_handleChannelPayload_replacesStateWhenNoPagination() {
        let payload = ChannelPayload.dummy(
            channel: .dummy(cid: cid),
            messages: [
                .dummy(messageId: "m1", text: "1"),
                .dummy(messageId: "m2", text: "2")
            ]
        )

        handler.handleChannelPayload(payload, channelQuery: ChannelQuery(cid: cid))

        XCTAssertEqual(handler.channel?.cid, cid)
        XCTAssertEqual(handler.messages.map(\.id), ["m2", "m1"])
    }

    func test_handleChannelPayload_appendsForOlderPagination() {
        // Seed initial state with one message.
        handler.handleChannelPayload(
            .dummy(channel: .dummy(cid: cid), messages: [.dummy(messageId: "newer", text: "Newer")]),
            channelQuery: ChannelQuery(cid: cid)
        )

        var query = ChannelQuery(cid: cid)
        query.pagination = MessagesPagination(pageSize: 25, parameter: .lessThan("newer"))
        handler.handleChannelPayload(
            .dummy(channel: .dummy(cid: cid), messages: [.dummy(messageId: "older", text: "Older")]),
            channelQuery: query
        )

        XCTAssertEqual(handler.messages.map(\.id), ["newer", "older"])
    }

    func test_handleChannelPayload_prependsForNewerPagination() {
        handler.handleChannelPayload(
            .dummy(channel: .dummy(cid: cid), messages: [.dummy(messageId: "older", text: "Older")]),
            channelQuery: ChannelQuery(cid: cid)
        )

        var query = ChannelQuery(cid: cid)
        query.pagination = MessagesPagination(pageSize: 25, parameter: .greaterThan("older"))
        handler.handleChannelPayload(
            .dummy(channel: .dummy(cid: cid), messages: [.dummy(messageId: "newer", text: "Newer")]),
            channelQuery: query
        )

        XCTAssertEqual(handler.messages.map(\.id), ["newer", "older"])
    }

    func test_handlePaginationFailure_marksPaginationEnded() {
        let mockPagination = MockPaginationStateHandler()
        handler = LivestreamChannelHandler(
            channelQuery: ChannelQuery(cid: cid),
            client: client,
            paginationStateHandler: mockPagination
        )

        handler.handlePaginationFailure(channelQuery: ChannelQuery(cid: cid), error: TestError())

        XCTAssertEqual(mockPagination.endCallCount, 1)
    }

    func test_beginPagination_invokesUnderlyingStateHandler() {
        let mockPagination = MockPaginationStateHandler()
        handler = LivestreamChannelHandler(
            channelQuery: ChannelQuery(cid: cid),
            client: client,
            paginationStateHandler: mockPagination
        )

        handler.beginPagination(for: ChannelQuery(cid: cid))

        XCTAssertEqual(mockPagination.beginCallCount, 1)
    }
}

// MARK: - Pause / Resume / Counters

extension LivestreamChannelHandler_Tests {
    func test_pause_setsIsPausedToTrue() {
        handler.pause()
        XCTAssertTrue(handler.isPaused)
    }

    func test_pause_whenAlreadyPaused_doesNotFireCallbackAgain() {
        let exp = expectation(description: "pause callback fires once")
        exp.expectedFulfillmentCount = 1
        exp.assertForOverFulfill = true
        handler.setHandlers(.init(
            pauseDidChange: { _ in exp.fulfill() }
        ))

        handler.pause()
        handler.pause()
        wait(for: [exp], timeout: defaultTimeout)
    }

    func test_resume_setsIsPausedToFalse() {
        handler.pause()
        handler.resume()
        XCTAssertFalse(handler.isPaused)
    }

    func test_resume_resetsSkippedMessagesAmount_whenCountingEnabled() {
        handler.countSkippedMessagesWhenPaused = true
        handler.pause()
        handler.skippedMessagesAmount = 5

        handler.resume()

        XCTAssertEqual(handler.skippedMessagesAmount, 0)
    }

    func test_resetSkippedMessagesCountIfNeeded_resetsOnlyWhenCountingEnabled() {
        handler.skippedMessagesAmount = 5

        handler.resetSkippedMessagesCountIfNeeded()
        XCTAssertEqual(handler.skippedMessagesAmount, 5)

        handler.countSkippedMessagesWhenPaused = true
        handler.resetSkippedMessagesCountIfNeeded()
        XCTAssertEqual(handler.skippedMessagesAmount, 0)
    }

    func test_clearMessages_emptiesMessagesArray() {
        handler.messages = [.mock(id: "m1"), .mock(id: "m2")]
        handler.clearMessages()
        XCTAssertTrue(handler.messages.isEmpty)
    }
}

// MARK: - Message Limit

extension LivestreamChannelHandler_Tests {
    func test_maxMessageLimitOptions_whenSet_appliesLimitOnNewMessage() {
        handler.maxMessageLimitOptions = .init(maxLimit: 3, discardAmount: 2)
        let preloaded: [ChatMessage] = (0..<3).map { .mock(id: "m\($0)", cid: cid, text: "msg") }
        handler.messages = preloaded

        // Adding one more pushes us over `maxLimit` and triggers `applyMessageLimit`,
        // which prunes the array down to `maxLimit - discardAmount` newest messages.
        handler.didReceiveEvent(
            MessageNewEvent(
                user: .mock(id: .unique),
                message: .mock(id: "new", cid: cid, text: "New"),
                channel: .mock(cid: cid),
                createdAt: .unique,
                watcherCount: nil,
                unreadCount: nil
            )
        )

        XCTAssertEqual(handler.messages.count, 1)
        XCTAssertEqual(handler.messages.first?.id, "new")
    }

    func test_maxMessageLimitOptions_whenNil_doesNotPruneMessages() {
        let preloaded: [ChatMessage] = (0..<10).map { .mock(id: "m\($0)", cid: cid, text: "msg") }
        handler.messages = preloaded

        handler.didReceiveEvent(
            MessageNewEvent(
                user: .mock(id: .unique),
                message: .mock(id: "new", cid: cid, text: "New"),
                channel: .mock(cid: cid),
                createdAt: .unique,
                watcherCount: nil,
                unreadCount: nil
            )
        )

        XCTAssertEqual(handler.messages.count, 11)
    }

    func test_maxMessageLimitOptions_whenPaused_doesNotPruneMessages() {
        handler.maxMessageLimitOptions = .init(maxLimit: 3, discardAmount: 2)
        let preloaded: [ChatMessage] = (0..<3).map { .mock(id: "m\($0)", cid: cid, text: "msg") }
        handler.messages = preloaded
        handler.pause()

        handler.didReceiveEvent(
            MessageNewEvent(
                user: .mock(id: .unique),
                message: .mock(id: "new", cid: cid, text: "New"),
                channel: .mock(cid: cid),
                createdAt: .unique,
                watcherCount: nil,
                unreadCount: nil
            )
        )

        // Limit is only applied while not paused, so the array stays at full size.
        XCTAssertEqual(handler.messages.count, 4)
    }
}

// MARK: - Event Handling: Messages

extension LivestreamChannelHandler_Tests {
    func test_didReceiveEvent_messageNewEvent_addsMessageToArray() {
        handler.didReceiveEvent(makeNewMessageEvent(id: "new"))
        XCTAssertEqual(handler.messages.map(\.id), ["new"])
    }

    func test_didReceiveEvent_messageNewEvent_whenLatestNotLoaded_isIgnored() throws {
        // Move pagination state to a mid-page by simulating a `loadMessages(around:)`
        // response so `hasLoadedAllNextMessages` reports `false`.
        var midPageQuery = ChannelQuery(cid: cid)
        midPageQuery.pagination = MessagesPagination(pageSize: 2, parameter: .around("older"))
        handler.beginPagination(for: midPageQuery)
        handler.handleChannelPayload(
            .dummy(
                channel: .dummy(cid: cid),
                messages: [
                    .dummy(messageId: "older", text: "Older"),
                    .dummy(messageId: "newer", text: "Newer")
                ]
            ),
            channelQuery: midPageQuery
        )
        XCTAssertFalse(handler.hasLoadedAllNextMessages)

        handler.didReceiveEvent(makeNewMessageEvent(id: "new"))

        // The new live event is dropped because the latest page is not loaded.
        XCTAssertFalse(handler.messages.map(\.id).contains("new"))
    }

    func test_didReceiveEvent_newMessagePendingEvent_addsMessage() {
        handler.didReceiveEvent(NewMessagePendingEvent(message: .mock(id: "pending"), cid: cid))
        XCTAssertEqual(handler.messages.map(\.id), ["pending"])
    }

    func test_didReceiveEvent_newMessagePendingEvent_whenPaused_isIgnored() {
        handler.pause()
        handler.didReceiveEvent(NewMessagePendingEvent(message: .mock(id: "pending"), cid: cid))
        XCTAssertTrue(handler.messages.isEmpty)
    }

    func test_didReceiveEvent_messageUpdatedEvent_updatesExistingMessage() {
        handler.didReceiveEvent(makeNewMessageEvent(id: "msg-1", text: "Original"))

        handler.didReceiveEvent(MessageUpdatedEvent(
            user: .mock(id: .unique),
            channel: .mock(cid: cid),
            message: .mock(id: "msg-1", cid: cid, text: "Updated"),
            createdAt: .unique
        ))

        XCTAssertEqual(handler.messages.first?.text, "Updated")
    }

    func test_didReceiveEvent_messageUpdatedEvent_pinTransitions() {
        seedChannel()
        XCTAssertNotNil(handler.channel)
        handler.didReceiveEvent(makeNewMessageEvent(id: "msg", pinned: false))
        XCTAssertEqual(handler.channel?.pinnedMessages.count ?? -1, 0)

        // Pin it.
        handler.didReceiveEvent(MessageUpdatedEvent(
            user: .mock(id: .unique),
            channel: .mock(cid: cid),
            message: .mock(
                id: "msg",
                cid: cid,
                text: "msg",
                pinDetails: .init(pinnedAt: .unique, pinnedBy: .unique, expiresAt: nil)
            ),
            createdAt: .unique
        ))
        XCTAssertEqual(handler.channel?.pinnedMessages.map(\.id) ?? [], ["msg"])

        // Unpin it.
        handler.didReceiveEvent(MessageUpdatedEvent(
            user: .mock(id: .unique),
            channel: .mock(cid: cid),
            message: .mock(id: "msg", cid: cid, text: "msg", pinDetails: nil),
            createdAt: .unique
        ))
        XCTAssertEqual(handler.channel?.pinnedMessages.count ?? -1, 0)
    }

    func test_didReceiveEvent_messageUpdatedEvent_messageNotInLocalList_pinAddsToPinnedMessages() {
        seedChannel()
        XCTAssertEqual(handler.channel?.pinnedMessages.count ?? -1, 0)

        handler.didReceiveEvent(MessageUpdatedEvent(
            user: .mock(id: .unique),
            channel: .mock(cid: cid),
            message: .mock(
                id: "remote",
                cid: cid,
                text: "old",
                pinDetails: .init(pinnedAt: .unique, pinnedBy: .unique, expiresAt: nil)
            ),
            createdAt: .unique
        ))

        // Pinned messages can be updated even when the message is not in our local list.
        XCTAssertEqual(handler.channel?.pinnedMessages.map(\.id) ?? [], ["remote"])
    }

    func test_didReceiveEvent_messageDeletedEvent_hardDelete_removesMessage() {
        handler.didReceiveEvent(makeNewMessageEvent(id: "delete-me"))

        handler.didReceiveEvent(MessageDeletedEvent(
            user: .mock(id: .unique),
            channel: .mock(cid: cid),
            message: .mock(id: "delete-me", cid: cid, text: ""),
            createdAt: .unique,
            isHardDelete: true,
            deletedForMe: false
        ))

        XCTAssertTrue(handler.messages.isEmpty)
    }

    func test_didReceiveEvent_messageDeletedEvent_softDelete_marksMessageAsDeleted() {
        handler.didReceiveEvent(makeNewMessageEvent(id: "delete-me"))

        handler.didReceiveEvent(MessageDeletedEvent(
            user: .mock(id: .unique),
            channel: .mock(cid: cid),
            message: .mock(id: "delete-me", cid: cid, text: ""),
            createdAt: .unique,
            isHardDelete: false,
            deletedForMe: false
        ))

        XCTAssertEqual(handler.messages.count, 1)
        XCTAssertNotNil(handler.messages.first?.deletedAt)
    }

    func test_didReceiveEvent_newMessageErrorEvent_marksMessageAsFailed() {
        handler.didReceiveEvent(makeNewMessageEvent(id: "fail"))

        handler.didReceiveEvent(NewMessageErrorEvent(
            messageId: "fail",
            cid: cid,
            error: ClientError.Unknown()
        ))

        XCTAssertEqual(handler.messages.first?.localState, .sendingFailed)
    }

    func test_didReceiveEvent_reactionEvents_updateMessageInPlace() {
        let originalMessage = ChatMessage.mock(id: "msg", cid: cid, text: "msg", reactionScores: [:])
        handler.didReceiveEvent(makeNewMessageEvent(message: originalMessage))

        let messageWithReaction = ChatMessage.mock(id: "msg", cid: cid, text: "msg", reactionScores: ["like": 1])

        handler.didReceiveEvent(ReactionNewEvent(
            user: .mock(id: .unique),
            cid: cid,
            message: messageWithReaction,
            reaction: .mock(id: "msg", type: .init(rawValue: "like")),
            createdAt: .unique
        ))
        XCTAssertEqual(handler.messages.first?.reactionScores["like"], 1)

        let messageWithUpdatedReaction = ChatMessage.mock(id: "msg", cid: cid, text: "msg", reactionScores: ["like": 2])
        handler.didReceiveEvent(ReactionUpdatedEvent(
            user: .mock(id: .unique),
            cid: cid,
            message: messageWithUpdatedReaction,
            reaction: .mock(id: "msg", type: .init(rawValue: "like")),
            createdAt: .unique
        ))
        XCTAssertEqual(handler.messages.first?.reactionScores["like"], 2)

        let messageWithoutReaction = ChatMessage.mock(id: "msg", cid: cid, text: "msg", reactionScores: [:])
        handler.didReceiveEvent(ReactionDeletedEvent(
            user: .mock(id: .unique),
            cid: cid,
            message: messageWithoutReaction,
            reaction: .mock(id: "msg", type: .init(rawValue: "like")),
            createdAt: .unique
        ))
        XCTAssertEqual(handler.messages.first?.reactionScores["like"], nil)
    }

    func test_didReceiveEvent_whenPaused_andCountingEnabled_incrementsSkippedCount() {
        handler.countSkippedMessagesWhenPaused = true
        handler.pause()

        handler.didReceiveEvent(makeNewMessageEvent(id: "skipped"))

        XCTAssertEqual(handler.skippedMessagesAmount, 1)
        XCTAssertTrue(handler.messages.isEmpty)
    }

    func test_didReceiveEvent_userMessagesDeletedEvent_softDelete_marksUserMessages() {
        let bannedUserId = UserId.unique
        handler.didReceiveEvent(makeNewMessageEvent(id: "bad1", author: .mock(id: bannedUserId)))
        handler.didReceiveEvent(makeNewMessageEvent(id: "ok", author: .mock(id: .unique)))
        let deletedAt = Date()

        handler.didReceiveEvent(UserMessagesDeletedEvent(
            user: .mock(id: bannedUserId),
            hardDelete: false,
            createdAt: deletedAt
        ))

        XCTAssertEqual(handler.messages.count, 2)
        XCTAssertNotNil(handler.messages.first(where: { $0.id == "bad1" })?.deletedAt)
        XCTAssertNil(handler.messages.first(where: { $0.id == "ok" })?.deletedAt)
    }

    func test_didReceiveEvent_userMessagesDeletedEvent_hardDelete_removesUserMessages() {
        let bannedUserId = UserId.unique
        handler.didReceiveEvent(makeNewMessageEvent(id: "bad1", author: .mock(id: bannedUserId)))
        handler.didReceiveEvent(makeNewMessageEvent(id: "ok", author: .mock(id: .unique)))

        handler.didReceiveEvent(UserMessagesDeletedEvent(
            user: .mock(id: bannedUserId),
            hardDelete: true,
            createdAt: .unique
        ))

        XCTAssertEqual(handler.messages.map(\.id), ["ok"])
    }

    func test_didReceiveEvent_differentChannelEvent_isIgnored() {
        let otherChannelId = ChannelId.unique
        handler.didReceiveEvent(MessageNewEvent(
            user: .mock(id: .unique),
            message: .mock(id: "other", cid: otherChannelId, text: ""),
            channel: .mock(cid: otherChannelId),
            createdAt: .unique,
            watcherCount: nil,
            unreadCount: nil
        ))

        XCTAssertTrue(handler.messages.isEmpty)
    }
}

// MARK: - Event Handling: Channel & Membership

extension LivestreamChannelHandler_Tests {
    func test_didReceiveEvent_channelUpdatedEvent_updatesChannel() {
        seedChannel(name: "Original")

        handler.didReceiveEvent(ChannelUpdatedEvent(
            channel: .mock(cid: cid, name: "Updated"),
            user: .mock(id: .unique),
            message: nil,
            createdAt: .unique
        ))

        XCTAssertEqual(handler.channel?.name, "Updated")
    }

    func test_didReceiveEvent_channelTruncatedEvent_withMessage_replacesMessages() {
        seedChannel()
        handler.messages = [.mock(id: "m1"), .mock(id: "m2")]
        let truncationMessage = ChatMessage.mock(id: "truncation", cid: cid, text: "Channel was truncated")

        handler.didReceiveEvent(ChannelTruncatedEvent(
            channel: .mock(cid: cid, name: "Truncated"),
            user: .mock(id: .unique),
            message: truncationMessage,
            createdAt: .unique
        ))

        XCTAssertEqual(handler.channel?.name, "Truncated")
        XCTAssertEqual(handler.messages.map(\.id), ["truncation"])
    }

    func test_didReceiveEvent_channelTruncatedEvent_withoutMessage_clearsMessages() {
        seedChannel()
        handler.messages = [.mock(id: "m1")]

        handler.didReceiveEvent(ChannelTruncatedEvent(
            channel: .mock(cid: cid, name: "Truncated"),
            user: .mock(id: .unique),
            message: nil,
            createdAt: .unique
        ))

        XCTAssertTrue(handler.messages.isEmpty)
    }

    func test_didReceiveEvent_memberAddedEvent_addsMember() {
        seedChannel()
        let newMember = ChatChannelMember.dummy(id: .unique)

        handler.didReceiveEvent(MemberAddedEvent(
            user: newMember,
            cid: cid,
            member: newMember,
            createdAt: .unique
        ))

        XCTAssertTrue(handler.channel?.lastActiveMembers.contains(where: { $0.id == newMember.id }) ?? false)
    }

    func test_didReceiveEvent_memberRemovedEvent_removesMember() {
        let memberId = UserId.unique
        seedChannel(members: [.dummy(id: memberId)])

        handler.didReceiveEvent(MemberRemovedEvent(
            user: .mock(id: memberId),
            cid: cid,
            createdAt: .unique
        ))

        XCTAssertFalse(handler.channel?.lastActiveMembers.contains(where: { $0.id == memberId }) ?? false)
    }

    func test_didReceiveEvent_notificationAddedToChannelEvent_addsMembership() {
        seedChannel()
        let newMember = ChatChannelMember.dummy(id: .unique)

        handler.didReceiveEvent(NotificationAddedToChannelEvent(
            channel: .mock(cid: cid),
            unreadCount: nil,
            member: newMember,
            createdAt: .unique
        ))

        XCTAssertEqual(handler.channel?.membership?.id, newMember.id)
    }

    func test_didReceiveEvent_notificationRemovedFromChannelEvent_clearsMembership() {
        let memberId = UserId.unique
        let member = ChatChannelMember.dummy(id: memberId)
        seedChannel(members: [member], membership: member)
        XCTAssertNotNil(handler.channel?.membership)

        handler.didReceiveEvent(NotificationRemovedFromChannelEvent(
            user: .mock(id: memberId),
            cid: cid,
            member: member,
            createdAt: .unique
        ))

        XCTAssertNil(handler.channel?.membership)
    }

    func test_didReceiveEvent_userWatchingEvent_started_addsWatcher() {
        seedChannel()
        let watcher = ChatUser.mock(id: .unique)

        handler.didReceiveEvent(UserWatchingEvent(
            cid: cid,
            createdAt: .unique,
            user: watcher,
            watcherCount: 1,
            isStarted: true
        ))

        XCTAssertTrue(handler.channel?.lastActiveWatchers.contains(where: { $0.id == watcher.id }) ?? false)
        XCTAssertEqual(handler.channel?.watcherCount, 1)
    }

    func test_didReceiveEvent_userWatchingEvent_stopped_removesWatcher() {
        let watcher = ChatUser.mock(id: .unique)
        seedChannel(watchers: [watcher])

        handler.didReceiveEvent(UserWatchingEvent(
            cid: cid,
            createdAt: .unique,
            user: watcher,
            watcherCount: 0,
            isStarted: false
        ))

        XCTAssertFalse(handler.channel?.lastActiveWatchers.contains(where: { $0.id == watcher.id }) ?? false)
    }
}

// MARK: - Event Handling: Typing

extension LivestreamChannelHandler_Tests {
    func test_didReceiveEvent_typingStart_addsUserToTypingUsers() {
        seedChannel()
        let typingUser = ChatUser.mock(id: .unique)

        handler.didReceiveEvent(typingEvent(user: typingUser, isTyping: true))

        XCTAssertEqual(handler.channel?.currentlyTypingUsers, [typingUser])
    }

    func test_didReceiveEvent_typingStop_removesUserFromTypingUsers() {
        seedChannel()
        let typingUser = ChatUser.mock(id: .unique)
        handler.didReceiveEvent(typingEvent(user: typingUser, isTyping: true))

        handler.didReceiveEvent(typingEvent(user: typingUser, isTyping: false))

        XCTAssertTrue(handler.channel?.currentlyTypingUsers.isEmpty ?? false)
    }

    func test_didReceiveEvent_typingStop_removesUserEvenWhenMetadataChanged() {
        seedChannel()
        let userId = UserId.unique
        handler.didReceiveEvent(typingEvent(
            user: .mock(id: userId, name: "Alice", lastActiveAt: .init(timeIntervalSince1970: 100)),
            isTyping: true
        ))

        handler.didReceiveEvent(typingEvent(
            user: .mock(id: userId, name: "Alice", lastActiveAt: .init(timeIntervalSince1970: 200)),
            isTyping: false
        ))

        XCTAssertTrue(handler.channel?.currentlyTypingUsers.isEmpty ?? false)
    }

    func test_didReceiveEvent_duplicateTypingStart_doesNotFireCallbackAgain() {
        seedChannel()
        let typingUser = ChatUser.mock(id: .unique)

        let exp = expectation(description: "typingUsers callback fires once")
        exp.expectedFulfillmentCount = 1
        exp.assertForOverFulfill = true
        handler.setHandlers(.init(typingUsersDidChange: { _ in
            exp.fulfill()
        }))

        handler.didReceiveEvent(typingEvent(user: typingUser, isTyping: true))
        handler.didReceiveEvent(typingEvent(user: typingUser, isTyping: true))

        wait(for: [exp], timeout: defaultTimeout)
    }

    func test_didReceiveEvent_typingEvent_fromCurrentUser_isIgnored() {
        let currentUserId = UserId.unique
        client.mockAuthenticationRepository.mockedCurrentUserId = currentUserId
        seedChannel()

        handler.didReceiveEvent(typingEvent(user: .mock(id: currentUserId), isTyping: true))

        XCTAssertTrue(handler.channel?.currentlyTypingUsers.isEmpty ?? false)
    }

    func test_didReceiveEvent_typingEvent_inThread_doesNotAffectChannelTyping() {
        seedChannel()

        handler.didReceiveEvent(TypingEvent(
            isTyping: true,
            cid: cid,
            user: .mock(id: .unique),
            parentId: .unique,
            createdAt: .unique
        ))

        XCTAssertTrue(handler.channel?.currentlyTypingUsers.isEmpty ?? false)
    }

    func test_didReceiveEvent_typingStart_autoCleansUp_afterTimeout() {
        let virtualTime = VirtualTime()
        VirtualTimeTimer.time = virtualTime
        handler.timerType = VirtualTimeTimer.self
        seedChannel()

        let typingUser = ChatUser.mock(id: .unique)
        handler.didReceiveEvent(typingEvent(user: typingUser, isTyping: true))
        XCTAssertEqual(handler.channel?.currentlyTypingUsers, [typingUser])

        virtualTime.run(numberOfSeconds: .incomingTypingStartEventTimeout + 1)

        XCTAssertTrue(handler.channel?.currentlyTypingUsers.isEmpty ?? false)

        VirtualTimeTimer.invalidate()
    }

    func test_didReceiveEvent_typingStop_cancelsAutoCleanup() {
        let virtualTime = VirtualTime()
        VirtualTimeTimer.time = virtualTime
        handler.timerType = VirtualTimeTimer.self
        seedChannel()

        let typingUser = ChatUser.mock(id: .unique)
        handler.didReceiveEvent(typingEvent(user: typingUser, isTyping: true))
        handler.didReceiveEvent(typingEvent(user: typingUser, isTyping: false))

        virtualTime.run(numberOfSeconds: .incomingTypingStartEventTimeout + 1)

        XCTAssertTrue(handler.channel?.currentlyTypingUsers.isEmpty ?? false)

        VirtualTimeTimer.invalidate()
    }
}

// MARK: - Cooldown

extension LivestreamChannelHandler_Tests {
    func test_currentCooldownTime_withNoChannel_returnsZero() {
        XCTAssertEqual(handler.currentCooldownTime(), 0)
    }

    func test_currentCooldownTime_withNoCooldown_returnsZero() {
        seedChannel(cooldownDuration: 0)
        XCTAssertEqual(handler.currentCooldownTime(), 0)
    }

    func test_currentCooldownTime_withSkipSlowModeCapability_returnsZero() {
        let currentUserId = UserId.unique
        client.mockAuthenticationRepository.mockedCurrentUserId = currentUserId
        seedChannel(cooldownDuration: 30, ownCapabilities: [.skipSlowMode])
        handler.messages = [.mock(
            id: "m",
            cid: cid,
            text: "msg",
            author: .mock(id: currentUserId),
            createdAt: Date()
        )]

        XCTAssertEqual(handler.currentCooldownTime(), 0)
    }

    func test_currentCooldownTime_withActiveSlowMode_returnsRemainingSeconds() {
        let currentUserId = UserId.unique
        client.mockAuthenticationRepository.mockedCurrentUserId = currentUserId
        seedChannel(cooldownDuration: 10)
        // Most recent current-user message was sent ~3s ago.
        handler.messages = [.mock(
            id: "m",
            cid: cid,
            text: "msg",
            author: .mock(id: currentUserId),
            createdAt: Date().addingTimeInterval(-3)
        )]

        let remaining = handler.currentCooldownTime()
        XCTAssertTrue((6...10).contains(remaining), "expected ~7s remaining, got \(remaining)")
    }
}

// MARK: - Callbacks

extension LivestreamChannelHandler_Tests {
    func test_settingChannel_invokesChannelDidChangeCallback() {
        let exp = expectation(description: "channelDidChange fires")
        handler.setHandlers(.init(channelDidChange: { channel in
            XCTAssertEqual(channel.cid, self.cid)
            exp.fulfill()
        }))

        handler.channel = .mock(cid: cid, name: "X")
        wait(for: [exp], timeout: defaultTimeout)
    }

    func test_settingMessages_invokesMessagesDidChangeCallback() {
        let exp = expectation(description: "messagesDidChange fires")
        handler.setHandlers(.init(messagesDidChange: { messages in
            XCTAssertEqual(messages.map(\.id), ["m"])
            exp.fulfill()
        }))

        handler.messages = [.mock(id: "m", cid: cid, text: "")]
        wait(for: [exp], timeout: defaultTimeout)
    }

    func test_settingIsPaused_invokesPauseDidChangeCallback() {
        let exp = expectation(description: "pauseDidChange fires")
        handler.setHandlers(.init(pauseDidChange: { isPaused in
            XCTAssertTrue(isPaused)
            exp.fulfill()
        }))

        handler.pause()
        wait(for: [exp], timeout: defaultTimeout)
    }

    func test_skippedMessagesAmount_invokesSkippedCallback() {
        let exp = expectation(description: "skippedMessagesAmountDidChange fires")
        handler.setHandlers(.init(skippedMessagesAmountDidChange: { amount in
            XCTAssertEqual(amount, 7)
            exp.fulfill()
        }))

        handler.skippedMessagesAmount = 7
        wait(for: [exp], timeout: defaultTimeout)
    }
}

// MARK: - Helpers

private extension LivestreamChannelHandler_Tests {
    func makeNewMessageEvent(id: MessageId, text: String = "msg", author: ChatUser? = nil, pinned: Bool = false) -> MessageNewEvent {
        let pinDetails: MessagePinDetails? = pinned
            ? .init(pinnedAt: .unique, pinnedBy: .unique, expiresAt: nil)
            : nil
        let message = ChatMessage.mock(
            id: id,
            cid: cid,
            text: text,
            author: author ?? .mock(id: .unique),
            pinDetails: pinDetails
        )
        return MessageNewEvent(
            user: .mock(id: .unique),
            message: message,
            channel: .mock(cid: cid),
            createdAt: .unique,
            watcherCount: nil,
            unreadCount: nil
        )
    }

    func makeNewMessageEvent(message: ChatMessage) -> MessageNewEvent {
        MessageNewEvent(
            user: .mock(id: .unique),
            message: message,
            channel: .mock(cid: cid),
            createdAt: .unique,
            watcherCount: nil,
            unreadCount: nil
        )
    }

    func typingEvent(user: ChatUser, isTyping: Bool) -> TypingEvent {
        TypingEvent(
            isTyping: isTyping,
            cid: cid,
            user: user,
            parentId: nil,
            createdAt: .unique
        )
    }

    func seedChannel(
        name: String = "Channel",
        members: [ChatChannelMember] = [],
        membership: ChatChannelMember? = nil,
        watchers: [ChatUser] = [],
        cooldownDuration: Int = 0,
        ownCapabilities: Set<ChannelCapability> = []
    ) {
        handler.channel = .mock(
            cid: cid,
            name: name,
            ownCapabilities: ownCapabilities,
            lastActiveMembers: members,
            membership: membership,
            lastActiveWatchers: watchers,
            watcherCount: watchers.count,
            memberCount: members.count,
            cooldownDuration: cooldownDuration
        )
    }
}
