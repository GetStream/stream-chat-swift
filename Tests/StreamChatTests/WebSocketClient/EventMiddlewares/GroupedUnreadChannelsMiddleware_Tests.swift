//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class GroupedUnreadChannelsMiddleware_Tests: XCTestCase {
    private var database: DatabaseContainer_Spy!
    private var middleware: GroupedUnreadChannelsMiddleware!
    private let currentUserId = UserId.unique

    override func setUp() {
        super.setUp()
        database = DatabaseContainer_Spy()
        middleware = .init()
    }

    override func tearDown() {
        database = nil
        AssertAsync.canBeReleased(&database)
        super.tearDown()
    }

    // MARK: - Tests

    func test_handle_whenLinkedChannelIsRead_updatesFilteredGroupCount() throws {
        let cid = ChannelId.unique
        try saveFilteredGroup(linking: cid, unreadMessages: 2, groupNotLoadedUnreadCount: 1)
        let event = NotificationMarkReadEventDTO(channel: .dummy(cid: cid), cid: cid, createdAt: .unique, totalUnreadCount: 0, unreadChannels: 0)

        try database.writeSynchronously { session in
            session.loadChannelRead(cid: cid, userId: self.currentUserId)?.unreadMessageCount = 0
            _ = self.middleware.handle(event: event, wsEvent: .typeNotificationMarkReadEvent(event), session: session)
        }

        XCTAssertEqual(["expired": 1], try unreadChannelCountsByGroup())
    }

    func test_handle_whenLinkedChannelGetsUnread_updatesFilteredGroupCount() throws {
        let cid = ChannelId.unique
        try saveFilteredGroup(linking: cid, unreadMessages: 0, groupNotLoadedUnreadCount: 1)
        let event = MessageNewEventDTO(cid: cid, createdAt: .unique, message: .dummy(messageId: .unique, authorUserId: .unique))

        try database.writeSynchronously { session in
            session.loadChannelRead(cid: cid, userId: self.currentUserId)?.unreadMessageCount = 1
            _ = self.middleware.handle(event: event, wsEvent: .typeMessageNewEvent(event), session: session)
        }

        XCTAssertEqual(["expired": 2], try unreadChannelCountsByGroup())
    }

    func test_handle_whenEventDoesNotAffectUnreadState_keepsFilteredGroupCount() throws {
        let cid = ChannelId.unique
        try saveFilteredGroup(linking: cid, unreadMessages: 0, groupNotLoadedUnreadCount: 1)
        let event = TypingStartEventDTO(cid: cid, createdAt: .unique, user: .dummy(userId: .unique))

        try database.writeSynchronously { session in
            session.loadChannelRead(cid: cid, userId: self.currentUserId)?.unreadMessageCount = 1
            _ = self.middleware.handle(event: event, wsEvent: .typeTypingStartEvent(event), session: session)
        }

        XCTAssertNil(try unreadChannelCountsByGroup()?["expired"])
    }

    func test_handle_whenLinkedChannelIsHidden_updatesFilteredGroupCount() throws {
        let cid = ChannelId.unique
        try saveFilteredGroup(linking: cid, unreadMessages: 2, groupNotLoadedUnreadCount: 1)
        let event = ChannelHiddenEventDTO(channel: .dummy(cid: cid), cid: cid, createdAt: .unique)

        try database.writeSynchronously { session in
            session.channel(cid: cid)?.isHidden = true
            _ = self.middleware.handle(event: event, wsEvent: .typeChannelHiddenEvent(event), session: session)
        }

        XCTAssertEqual(["expired": 1], try unreadChannelCountsByGroup())
    }

    func test_handle_whenMarkAllRead_clearsNotLoadedCount() throws {
        let cid = ChannelId.unique
        try saveFilteredGroup(linking: cid, unreadMessages: 2, groupNotLoadedUnreadCount: 3)
        let event = NotificationMarkReadEventDTO(createdAt: .unique, totalUnreadCount: 0, unreadChannels: 0)

        try database.writeSynchronously { session in
            session.loadChannelRead(cid: cid, userId: self.currentUserId)?.unreadMessageCount = 0
            _ = self.middleware.handle(event: event, wsEvent: .typeNotificationMarkReadEvent(event), session: session)
        }

        XCTAssertEqual(["expired": 0], try unreadChannelCountsByGroup())
    }

    func test_handle_whenChannelIsNotLinkedToFilteredGroup_doesNotUpdateCounts() throws {
        let otherCid = ChannelId.unique
        try saveFilteredGroup(linking: .unique, unreadMessages: 2, groupNotLoadedUnreadCount: 1)
        try database.createChannel(cid: otherCid)
        let event = NotificationMarkReadEventDTO(channel: .dummy(cid: otherCid), cid: otherCid, createdAt: .unique, totalUnreadCount: 0, unreadChannels: 0)

        try database.writeSynchronously { session in
            _ = self.middleware.handle(event: event, wsEvent: .typeNotificationMarkReadEvent(event), session: session)
        }

        XCTAssertNil(try unreadChannelCountsByGroup())
    }

    // MARK: - Helpers

    private func saveFilteredGroup(linking cid: ChannelId, unreadMessages: Int, groupNotLoadedUnreadCount: Int64) throws {
        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: .dummy(userId: self.currentUserId, role: .user))
            let queryDTO = session.saveQuery(query: ChannelListQuery(groupKey: "expired"))
            queryDTO.groupFilterJSONData = Data(#"{"query_timestamp":{"$gte":"now-14d"}}"#.utf8)
            queryDTO.groupNotLoadedUnreadCount = groupNotLoadedUnreadCount
            let read = ChannelReadPayload(
                user: .dummy(userId: self.currentUserId),
                lastReadAt: .unique,
                lastReadMessageId: nil,
                unreadMessagesCount: unreadMessages
            )
            queryDTO.channels.insert(try session.saveChannel(payload: .dummy(channel: .dummy(cid: cid), channelReads: [read])))
        }
    }

    private func unreadChannelCountsByGroup() throws -> [String: Int]? {
        try database.readSynchronously { $0.currentUser?.unreadChannelCountsByGroup }
    }
}
