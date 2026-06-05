//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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

        let event = MessageReadEventDTO(
            channel: .dummy(),
            cid: ChannelId.unique.rawValue,
            createdAt: .unique,
            custom: [:],
            thread: .dummy(parentMessageId: .unique),
            user: UserResponseCommonFields(.dummy(userId: .unique))
        )

        _ = middleware.handle(event: event, session: mockSession)

        XCTAssertEqual(mockSession.markThreadAsReadCallCount, 1)
    }

    func test_messageMarkUnreadEvent_marksThreadAsUnread() throws {
        let mockSession = DatabaseSession_Mock(underlyingSession: database.viewContext)

        let event = NotificationMarkUnreadEventDTO(
            cid: ChannelId.unique.rawValue,
            createdAt: .unique,
            custom: [:],
            firstUnreadMessageId: "Hello",
            lastReadAt: .unique,
            lastReadMessageId: nil, // This must be nil to be considered thread event
            totalUnreadCount: .unique,
            unreadChannels: .unique,
            unreadCount: .unique,
            unreadMessages: 6,
            user: UserResponseCommonFields(.dummy(userId: .unique))
        )

        _ = middleware.handle(event: event, session: mockSession)

        XCTAssertEqual(mockSession.markThreadAsUnreadCallCount, 1)
    }

    func test_threadMessageNewEvent_addsMessageToThreadReplies_increasesUnreadCount() throws {
        let parentMessageId = MessageId.unique
        let cid = ChannelId.unique
        let messagePayload: MessageResponse = .dummy(messageId: .unique, parentId: parentMessageId, cid: cid)
        let event = NotificationThreadMessageNewEventDTO(
            channel: .dummy(cid: cid),
            cid: cid.rawValue,
            createdAt: .unique,
            custom: [:],
            message: messagePayload,
            messageId: messagePayload.id,
            threadId: parentMessageId,
            watcherCount: 0
        )

        try database.writeSynchronously { session in
            let currentUserId = UserId.unique
            try session.saveCurrentUser(payload: .dummy(userId: currentUserId, role: .user))
            try session.saveChannel(payload: .dummy(channel: .dummy(cid: cid)))
            try session.saveThread(
                payload: .dummy(
                    channel: .dummy(cid: cid),
                    latestReplies: [.dummy(), .dummy()],
                    parentMessage: .dummy(messageId: parentMessageId),
                    parentMessageId: parentMessageId
                ),
                cache: nil
            )
            try session.saveThreadRead(
                payload: .dummy(
                    lastRead: .unique,
                    unreadMessages: 1,
                    user: .dummy(userId: currentUserId)
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
        let messagePayload: MessageResponse = .dummy(messageId: .unique, parentId: parentMessageId, cid: cid)
        let event = NotificationThreadMessageNewEventDTO(
            channel: .dummy(cid: cid),
            cid: cid.rawValue,
            createdAt: .unique,
            custom: [:],
            message: messagePayload,
            messageId: messagePayload.id,
            threadId: parentMessageId,
            watcherCount: 0
        )

        try database.writeSynchronously { session in
            let currentUserId = UserId.unique
            try session.saveCurrentUser(payload: .dummy(userId: currentUserId, role: .user))
            try session.saveChannel(payload: .dummy(channel: .dummy(cid: cid)))
            try session.saveThread(
                payload: .dummy(
                    channel: .dummy(cid: cid),
                    latestReplies: [.dummy(), .dummy()],
                    parentMessage: .dummy(messageId: parentMessageId),
                    parentMessageId: parentMessageId
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
        let messagePayload: MessageResponse = .dummy(messageId: .unique, parentId: parentMessageId, authorUserId: currentUserId, cid: cid)
        let event = NotificationThreadMessageNewEventDTO(
            channel: .dummy(cid: cid),
            cid: cid.rawValue,
            createdAt: .unique,
            custom: [:],
            message: messagePayload,
            messageId: messagePayload.id,
            threadId: parentMessageId,
            watcherCount: 0
        )

        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: .dummy(userId: currentUserId, role: .user))
            try session.saveChannel(payload: .dummy(channel: .dummy(cid: cid)))
            try session.saveThread(
                payload: .dummy(
                    channel: .dummy(cid: cid),
                    latestReplies: [.dummy(), .dummy()],
                    parentMessage: .dummy(messageId: parentMessageId),
                    parentMessageId: parentMessageId
                ),
                cache: nil
            )
            try session.saveThreadRead(
                payload: .dummy(
                    lastRead: .unique,
                    unreadMessages: 1,
                    user: .dummy(userId: currentUserId)
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
        let messagePayload: MessageResponse = .dummy(messageId: .unique, parentId: parentMessageId, authorUserId: mutedUserId, cid: cid)
        let event = NotificationThreadMessageNewEventDTO(
            channel: .dummy(cid: cid),
            cid: cid.rawValue,
            createdAt: .unique,
            custom: [:],
            message: messagePayload,
            messageId: messagePayload.id,
            threadId: parentMessageId,
            watcherCount: 0
        )

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
                    channel: .dummy(cid: cid),
                    latestReplies: [.dummy(), .dummy()],
                    parentMessage: .dummy(messageId: parentMessageId),
                    parentMessageId: parentMessageId
                ),
                cache: nil
            )
            try session.saveThreadRead(
                payload: .dummy(
                    lastRead: .unique,
                    unreadMessages: 1,
                    user: .dummy(userId: currentUserId)
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
        let event = ChannelDeletedEventDTO(
            channel: .dummy(cid: cid),
            cid: cid.rawValue,
            createdAt: .unique,
            custom: [:],
            user: UserResponseCommonFields(.dummy(userId: .unique))
        )

        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: .dummy(userId: currentUserId, role: .user))
            let channelDTO = try session.saveChannel(payload: .dummy(channel: .dummy(cid: cid)))
            try session.saveThread(
                payload: .dummy(
                    channel: .dummy(cid: cid),
                    latestReplies: [.dummy(), .dummy()],
                    parentMessage: .dummy(),
                    parentMessageId: .unique
                ),
                cache: nil
            )
            try session.saveThread(
                payload: .dummy(
                    channel: .dummy(cid: cid),
                    latestReplies: [.dummy(), .dummy()],
                    parentMessage: .dummy(),
                    parentMessageId: .unique
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
        let event = ChannelTruncatedEventDTO(
            channel: .dummy(cid: cid),
            cid: cid.rawValue,
            createdAt: .unique,
            custom: [:],
            user: UserResponseCommonFields(.dummy(userId: .unique))
        )

        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: .dummy(userId: currentUserId, role: .user))
            let channelDTO = try session.saveChannel(payload: .dummy(channel: .dummy(cid: cid)))
            try session.saveThread(
                payload: .dummy(
                    channel: .dummy(cid: cid),
                    latestReplies: [.dummy(), .dummy()],
                    parentMessage: .dummy(),
                    parentMessageId: .unique
                ),
                cache: nil
            )
            try session.saveThread(
                payload: .dummy(
                    channel: .dummy(cid: cid),
                    latestReplies: [.dummy(), .dummy()],
                    parentMessage: .dummy(),
                    parentMessageId: .unique
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
        let messagePayload: MessageResponse = .dummy(messageId: .unique, parentId: parentMessageId)
        let event = MessageDeletedEventDTO(
            cid: cid.rawValue,
            createdAt: .unique,
            custom: [:],
            hardDelete: false,
            message: messagePayload,
            messageId: messagePayload.id,
            user: UserResponseCommonFields(.dummy(userId: .unique))
        )

        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: .dummy(userId: currentUserId, role: .user))
            try session.saveChannel(payload: .dummy(channel: .dummy(cid: cid)))
            try session.saveThread(
                payload: .dummy(
                    channel: .dummy(cid: cid),
                    latestReplies: [.dummy(), .dummy()],
                    parentMessage: .dummy(messageId: parentMessageId),
                    parentMessageId: parentMessageId
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
        let messagePayload: MessageResponse = .dummy(messageId: parentMessageId)
        let event = MessageDeletedEventDTO(
            cid: cid.rawValue,
            createdAt: .unique,
            custom: [:],
            hardDelete: false,
            message: messagePayload,
            messageId: messagePayload.id,
            user: UserResponseCommonFields(.dummy(userId: .unique))
        )

        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: .dummy(userId: currentUserId, role: .user))
            try session.saveChannel(payload: .dummy(channel: .dummy(cid: cid)))
            try session.saveThread(
                payload: .dummy(
                    channel: .dummy(cid: cid),
                    latestReplies: [.dummy(), .dummy()],
                    parentMessage: .dummy(messageId: parentMessageId),
                    parentMessageId: parentMessageId
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
        let messagePayload: MessageResponse = .dummy(messageId: parentMessageId)
        let event = MessageDeletedEventDTO(
            cid: cid.rawValue,
            createdAt: .unique,
            custom: [:],
            hardDelete: true,
            message: messagePayload,
            messageId: messagePayload.id,
            user: UserResponseCommonFields(.dummy(userId: .unique))
        )

        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: .dummy(userId: currentUserId, role: .user))
            try session.saveChannel(payload: .dummy(channel: .dummy(cid: cid)))
            try session.saveThread(
                payload: .dummy(
                    channel: .dummy(cid: cid),
                    latestReplies: [.dummy(), .dummy()],
                    parentMessage: .dummy(messageId: parentMessageId),
                    parentMessageId: parentMessageId
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
        let messagePayload: MessageResponse = .dummy(messageId: .unique, parentId: parentMessageId, messageTextUpdatedAt: .unique)
        let event = MessageUpdatedEventDTO(
            cid: cid.rawValue,
            createdAt: .unique,
            custom: [:],
            message: messagePayload,
            messageId: messagePayload.id,
            user: UserResponseCommonFields(.dummy(userId: .unique))
        )

        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: .dummy(userId: currentUserId, role: .user))
            try session.saveChannel(payload: .dummy(channel: .dummy(cid: cid)))
            try session.saveThread(
                payload: .dummy(
                    channel: .dummy(cid: cid),
                    latestReplies: [.dummy(), .dummy()],
                    parentMessage: .dummy(messageId: parentMessageId),
                    parentMessageId: parentMessageId
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
        let messagePayload: MessageResponse = .dummy(messageId: .unique, parentId: parentMessageId, messageTextUpdatedAt: nil)
        let event = MessageUpdatedEventDTO(
            cid: cid.rawValue,
            createdAt: .unique,
            custom: [:],
            message: messagePayload,
            messageId: messagePayload.id,
            user: UserResponseCommonFields(.dummy(userId: .unique))
        )

        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: .dummy(userId: currentUserId, role: .user))
            try session.saveChannel(payload: .dummy(channel: .dummy(cid: cid)))
            try session.saveThread(
                payload: .dummy(
                    channel: .dummy(cid: cid),
                    latestReplies: [.dummy(), .dummy()],
                    parentMessage: .dummy(messageId: parentMessageId),
                    parentMessageId: parentMessageId
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
