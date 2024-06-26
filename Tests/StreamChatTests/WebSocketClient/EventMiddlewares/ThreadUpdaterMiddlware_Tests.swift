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
            unreadCount: .noUnread,
            createdAt: .unique,
            threadDetails: .dummy(parentMessageId: .unique)
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
        let currentUserId = UserId.unique
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
        let currentUserId = UserId.unique
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
}
