//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ThreadUpdaterMiddleware_Tests: XCTestCase {
    var middleware: ThreadUpdaterMiddleware!
    var center: EventNotificationCenter_Mock!
    var database: DatabaseContainer_Spy!

    override func setUp() {
        super.setUp()
        database = DatabaseContainer_Spy()
        center = EventNotificationCenter_Mock(database: database)
        middleware = ThreadUpdaterMiddleware()
    }

    override func tearDown() {
        database = nil
        AssertAsync.canBeReleased(&database)

        super.tearDown()
    }

    func test_messageReadEvent_marksThreadRead() throws {
        let mockSession = DatabaseSession_Mock(underlyingSession: database.viewContext)

        let eventPayload = EventPayload(
            eventType: .messageRead,
            cid: .unique,
            user: .dummy(userId: .unique),
            channel: .dummy(),
            unreadCount: .init(channels: 0, messages: 0, threads: 0),
            createdAt: .unique,
            threadDetails: .success(.dummy(parentMessageId: .unique))
        )

        let event = try MessageReadEventDTO(from: eventPayload)

        _ = middleware.handle(event: event, session: mockSession)

        XCTAssertEqual(mockSession.markThreadAsReadCallCount, 1)
    }

    func test_messageMarkUnreadEvent_marksThreadAsUnread() throws {
        let mockSession = DatabaseSession_Mock(underlyingSession: database.viewContext)

        let eventPayload = EventPayload(
            eventType: .notificationMarkUnread,
            cid: .unique,
            user: .dummy(userId: .unique),
            unreadCount: .init(channels: .unique, messages: .unique, threads: .unique),
            createdAt: .unique,
            firstUnreadMessageId: "Hello",
            lastReadAt: .unique,
            lastReadMessageId: nil, // This must be nil to be considered thread event
            unreadMessagesCount: 6
        )

        let event = try NotificationMarkUnreadEventDTO(from: eventPayload)

        _ = middleware.handle(event: event, session: mockSession)

        XCTAssertEqual(mockSession.markThreadAsUnreadCallCount, 1)
    }

    func test_threadMessageNewEvent_addsMessageToThreadReplies_increasesUnreadCount() throws {
        let parentMessageId = MessageId.unique
        let cid = ChannelId.unique
        let eventPayload = EventPayload(
            eventType: .threadMessageNew,
            cid: cid,
            channel: .dummy(cid: cid),
            message: .dummy(messageId: .unique, parentId: parentMessageId, cid: cid),
            createdAt: .unique
        )

        let event = try ThreadMessageNewEventDTO(from: eventPayload)

        try database.writeSynchronously { session in
            let currentUserId = UserId.unique
            try session.saveCurrentUser(payload: .dummy(userId: currentUserId, role: .user))
            try session.saveChannel(payload: .dummy(channel: .dummy(cid: cid)))
            try session.saveThread(
                payload: .dummy(
                    parentMessageId: parentMessageId,
                    latestReplies: [.dummy(), .dummy()]
                ),
                cache: nil
            )
            try session.saveThreadRead(
                payload: .init(
                    user: .dummy(userId: currentUserId),
                    lastReadAt: .unique,
                    unreadMessagesCount: 1
                ),
                parentMessageId: parentMessageId,
                cache: nil
            )

            _ = self.middleware.handle(event: event, session: session)
        }

        let thread = database.viewContext.thread(parentMessageId: parentMessageId, cache: nil)
        XCTAssertEqual(thread?.latestReplies.count, 3)
        XCTAssertEqual(thread?.read.first?.unreadMessagesCount, 2)
    }

    func test_threadMessageNewEvent_whenThreadReadDoesNotExist_stillIncreasesUnreadCount() throws {
        let parentMessageId = MessageId.unique
        let cid = ChannelId.unique
        let eventPayload = EventPayload(
            eventType: .threadMessageNew,
            cid: cid,
            channel: .dummy(cid: cid),
            message: .dummy(messageId: .unique, parentId: parentMessageId, cid: cid),
            createdAt: .unique
        )

        let event = try ThreadMessageNewEventDTO(from: eventPayload)

        try database.writeSynchronously { session in
            let currentUserId = UserId.unique
            try session.saveCurrentUser(payload: .dummy(userId: currentUserId, role: .user))
            try session.saveChannel(payload: .dummy(channel: .dummy(cid: cid)))
            try session.saveThread(
                payload: .dummy(
                    parentMessageId: parentMessageId,
                    latestReplies: [.dummy(), .dummy()]
                ),
                cache: nil
            )

            _ = self.middleware.handle(event: event, session: session)
        }

        let thread = database.viewContext.thread(parentMessageId: parentMessageId, cache: nil)
        XCTAssertEqual(thread?.latestReplies.count, 3)
        XCTAssertEqual(thread?.read.first?.unreadMessagesCount, 1)
    }

    func test_threadMessageNewEvent_whenCurrentUserReply_doesNotIncreaseUnreadCount() throws {
        let currentUserId = UserId.unique
        let parentMessageId = MessageId.unique
        let cid = ChannelId.unique
        let eventPayload = EventPayload(
            eventType: .threadMessageNew,
            cid: cid,
            channel: .dummy(cid: cid),
            message: .dummy(messageId: .unique, parentId: parentMessageId, authorUserId: currentUserId, cid: cid),
            createdAt: .unique
        )

        let event = try ThreadMessageNewEventDTO(from: eventPayload)

        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: .dummy(userId: currentUserId, role: .user))
            try session.saveChannel(payload: .dummy(channel: .dummy(cid: cid)))
            try session.saveThread(
                payload: .dummy(
                    parentMessageId: parentMessageId,
                    latestReplies: [.dummy(), .dummy()]
                ),
                cache: nil
            )
            try session.saveThreadRead(
                payload: .init(
                    user: .dummy(userId: currentUserId),
                    lastReadAt: .unique,
                    unreadMessagesCount: 1
                ),
                parentMessageId: parentMessageId,
                cache: nil
            )

            _ = self.middleware.handle(event: event, session: session)
        }

        let thread = database.viewContext.thread(parentMessageId: parentMessageId, cache: nil)
        XCTAssertEqual(thread?.latestReplies.count, 3)
        XCTAssertEqual(thread?.read.first?.unreadMessagesCount, 1)
    }

    func test_threadMessageNewEvent_whenMutedUser_doesNotIncreaseUnreadCount() throws {
        let currentUserId = UserId.unique
        let mutedUserId = UserId.unique
        let parentMessageId = MessageId.unique
        let cid = ChannelId.unique
        let eventPayload = EventPayload(
            eventType: .threadMessageNew,
            cid: cid,
            channel: .dummy(cid: cid),
            message: .dummy(messageId: .unique, parentId: parentMessageId, authorUserId: mutedUserId, cid: cid),
            createdAt: .unique
        )

        let event = try ThreadMessageNewEventDTO(from: eventPayload)

        try database.writeSynchronously { session in
            try session.saveCurrentUser(
                payload: .dummy(
                    userId: currentUserId,
                    role: .user,
                    mutedUsers: [.dummy(userId: mutedUserId)]
                )
            )
            try session.saveChannel(payload: .dummy(channel: .dummy(cid: cid)))
            try session.saveThread(
                payload: .dummy(
                    parentMessageId: parentMessageId,
                    latestReplies: [.dummy(), .dummy()]
                ),
                cache: nil
            )
            try session.saveThreadRead(
                payload: .init(
                    user: .dummy(userId: currentUserId),
                    lastReadAt: .unique,
                    unreadMessagesCount: 1
                ),
                parentMessageId: parentMessageId,
                cache: nil
            )

            _ = self.middleware.handle(event: event, session: session)
        }

        let thread = database.viewContext.thread(parentMessageId: parentMessageId, cache: nil)
        XCTAssertEqual(thread?.latestReplies.count, 3)
        XCTAssertEqual(thread?.read.first?.unreadMessagesCount, 1)
    }

    func test_channelDeletedEvent_shouldDeleteAllThreadsBelongingToTheDeletedChannel() throws {
        let currentUserId = UserId.unique
        let cid = ChannelId.unique
        let eventPayload = EventPayload(
            eventType: .channelDeleted,
            cid: cid,
            user: .dummy(userId: .unique),
            channel: .dummy(cid: cid),
            createdAt: .unique
        )

        let event = try ChannelDeletedEventDTO(from: eventPayload)

        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: .dummy(userId: currentUserId, role: .user))
            let channelDTO = try session.saveChannel(payload: .dummy(channel: .dummy(cid: cid)))
            try session.saveThread(
                payload: .dummy(
                    parentMessageId: .unique,
                    channel: .dummy(cid: cid),
                    latestReplies: [.dummy(), .dummy()]
                ),
                cache: nil
            )
            try session.saveThread(
                payload: .dummy(
                    parentMessageId: .unique,
                    channel: .dummy(cid: cid),
                    latestReplies: [.dummy(), .dummy()]
                ),
                cache: nil
            )

            XCTAssertEqual(channelDTO.threads.count, 2)

            _ = self.middleware.handle(event: event, session: session)
        }

        let channel = database.viewContext.channel(cid: cid)
        XCTAssertEqual(channel?.threads.count, 0)
    }

    func test_channelTruncatedEvent_shouldDeleteAllThreadsBelongingToTheTruncatedChannel() throws {
        let currentUserId = UserId.unique
        let cid = ChannelId.unique
        let eventPayload = EventPayload(
            eventType: .channelTruncated,
            cid: cid,
            user: .dummy(userId: .unique),
            channel: .dummy(cid: cid),
            createdAt: .unique
        )

        let event = try ChannelTruncatedEventDTO(from: eventPayload)

        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: .dummy(userId: currentUserId, role: .user))
            let channelDTO = try session.saveChannel(payload: .dummy(channel: .dummy(cid: cid)))
            try session.saveThread(
                payload: .dummy(
                    parentMessageId: .unique,
                    channel: .dummy(cid: cid),
                    latestReplies: [.dummy(), .dummy()]
                ),
                cache: nil
            )
            try session.saveThread(
                payload: .dummy(
                    parentMessageId: .unique,
                    channel: .dummy(cid: cid),
                    latestReplies: [.dummy(), .dummy()]
                ),
                cache: nil
            )

            XCTAssertEqual(channelDTO.threads.count, 2)

            _ = self.middleware.handle(event: event, session: session)
        }

        let channel = database.viewContext.channel(cid: cid)
        XCTAssertEqual(channel?.threads.count, 0)
    }

    func test_messageDeletedEvent_whenIsReplyOfThread_shouldTriggerThreadUpdate() throws {
        let currentUserId = UserId.unique
        let parentMessageId = MessageId.unique
        let cid = ChannelId.unique
        let eventPayload = EventPayload(
            eventType: .messageDeleted,
            cid: cid,
            user: .dummy(userId: .unique),
            message: .dummy(messageId: .unique, parentId: parentMessageId),
            createdAt: .unique,
            hardDelete: false
        )

        let event = try MessageDeletedEventDTO(from: eventPayload)

        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: .dummy(userId: currentUserId, role: .user))
            try session.saveChannel(payload: .dummy(channel: .dummy(cid: cid)))
            try session.saveThread(
                payload: .dummy(
                    parentMessageId: parentMessageId,
                    channel: .dummy(cid: cid),
                    latestReplies: [.dummy(), .dummy()]
                ),
                cache: nil
            )
        }

        try database.writeSynchronously { session in
            _ = self.middleware.handle(event: event, session: session)

            let thread = session.thread(parentMessageId: parentMessageId, cache: nil)
            XCTAssertEqual(thread?.hasChanges, true)
        }
    }

    func test_messageDeletedEvent_whenIsParentMessage_whenSoftDeleted_shouldTriggerThreadUpdate() throws {
        let currentUserId = UserId.unique
        let parentMessageId = MessageId.unique
        let cid = ChannelId.unique
        let eventPayload = EventPayload(
            eventType: .messageDeleted,
            cid: cid,
            user: .dummy(userId: .unique),
            message: .dummy(messageId: parentMessageId),
            createdAt: .unique,
            hardDelete: false
        )

        let event = try MessageDeletedEventDTO(from: eventPayload)

        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: .dummy(userId: currentUserId, role: .user))
            try session.saveChannel(payload: .dummy(channel: .dummy(cid: cid)))
            try session.saveThread(
                payload: .dummy(
                    parentMessageId: parentMessageId,
                    channel: .dummy(cid: cid),
                    latestReplies: [.dummy(), .dummy()]
                ),
                cache: nil
            )
        }

        try database.writeSynchronously { session in
            _ = self.middleware.handle(event: event, session: session)

            let thread = session.thread(parentMessageId: parentMessageId, cache: nil)
            XCTAssertEqual(thread?.hasChanges, true)
        }
    }

    func test_messageDeletedEvent_whenIsParentMessage_whenHardDeleted_shouldDeleteThread() throws {
        let currentUserId = UserId.unique
        let parentMessageId = MessageId.unique
        let cid = ChannelId.unique
        let eventPayload = EventPayload(
            eventType: .messageDeleted,
            cid: cid,
            user: .dummy(userId: .unique),
            message: .dummy(messageId: parentMessageId),
            createdAt: .unique,
            hardDelete: true
        )

        let event = try MessageDeletedEventDTO(from: eventPayload)

        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: .dummy(userId: currentUserId, role: .user))
            try session.saveChannel(payload: .dummy(channel: .dummy(cid: cid)))
            try session.saveThread(
                payload: .dummy(
                    parentMessageId: parentMessageId,
                    channel: .dummy(cid: cid),
                    latestReplies: [.dummy(), .dummy()]
                ),
                cache: nil
            )

            XCTAssertNotNil(session.thread(parentMessageId: parentMessageId, cache: nil))

            _ = self.middleware.handle(event: event, session: session)
        }

        let deletedThread = database.viewContext.thread(parentMessageId: parentMessageId, cache: nil)
        XCTAssertNil(deletedThread)
    }

    func test_messageUpdatedEvent_whenIsReplyOfThread_whenTextChanged_shouldTriggerThreadUpdate() throws {
        let currentUserId = UserId.unique
        let parentMessageId = MessageId.unique
        let cid = ChannelId.unique
        let eventPayload = EventPayload(
            eventType: .messageUpdated,
            cid: cid,
            user: .dummy(userId: .unique),
            message: .dummy(messageId: .unique, parentId: parentMessageId, messageTextUpdatedAt: .unique),
            createdAt: .unique,
            hardDelete: false
        )

        let event = try MessageUpdatedEventDTO(from: eventPayload)

        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: .dummy(userId: currentUserId, role: .user))
            try session.saveChannel(payload: .dummy(channel: .dummy(cid: cid)))
            try session.saveThread(
                payload: .dummy(
                    parentMessageId: parentMessageId,
                    channel: .dummy(cid: cid),
                    latestReplies: [.dummy(), .dummy()]
                ),
                cache: nil
            )
        }

        try database.writeSynchronously { session in
            _ = self.middleware.handle(event: event, session: session)

            let thread = session.thread(parentMessageId: parentMessageId, cache: nil)
            XCTAssertEqual(thread?.hasChanges, true)
        }
    }

    func test_messageUpdatedEvent_whenIsReplyOfThread_whenTextNotChanged_shouldNotTriggerThreadUpdate() throws {
        let currentUserId = UserId.unique
        let parentMessageId = MessageId.unique
        let cid = ChannelId.unique
        let eventPayload = EventPayload(
            eventType: .messageUpdated,
            cid: cid,
            user: .dummy(userId: .unique),
            message: .dummy(messageId: .unique, parentId: parentMessageId, messageTextUpdatedAt: nil),
            createdAt: .unique,
            hardDelete: false
        )

        let event = try MessageUpdatedEventDTO(from: eventPayload)

        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: .dummy(userId: currentUserId, role: .user))
            try session.saveChannel(payload: .dummy(channel: .dummy(cid: cid)))
            try session.saveThread(
                payload: .dummy(
                    parentMessageId: parentMessageId,
                    channel: .dummy(cid: cid),
                    latestReplies: [.dummy(), .dummy()]
                ),
                cache: nil
            )
        }

        try database.writeSynchronously { session in
            _ = self.middleware.handle(event: event, session: session)

            let thread = session.thread(parentMessageId: parentMessageId, cache: nil)
            XCTAssertEqual(thread?.hasChanges, false)
        }
    }
}
