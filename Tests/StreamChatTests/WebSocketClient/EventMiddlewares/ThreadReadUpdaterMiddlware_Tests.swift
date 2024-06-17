//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ThreadReadUpdaterMiddleware_Tests: XCTestCase {
    var middleware: ThreadReadUpdaterMiddleware!
    var center: EventNotificationCenter_Mock!
    var database: DatabaseContainer_Spy!

    override func setUp() {
        super.setUp()
        database = DatabaseContainer_Spy()
        center = EventNotificationCenter_Mock(database: database)
        middleware = ThreadReadUpdaterMiddleware()
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
            thread: .dummy(parentMessageId: .unique)
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
}
