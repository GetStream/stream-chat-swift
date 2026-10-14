//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class GroupedChannelListLinker_Tests: XCTestCase {
    private var database: DatabaseContainer_Spy!
    private var eventNotificationCenter: PersistentEventNotificationCenter!
    private var time: VirtualTime!
    private var linker: GroupedChannelListLinker!
    private let query = ChannelListQuery(groupKey: "expired")
    private let currentUserId = UserId.unique

    override func setUp() {
        super.setUp()
        database = DatabaseContainer_Spy()
        eventNotificationCenter = PersistentEventNotificationCenter(database: database)
        time = VirtualTime()
        VirtualTimeTimer.time = time
        linker = GroupedChannelListLinker(
            query: query,
            databaseContainer: database,
            channelWatcherHandler: ChannelWatcherHandler_Mock(),
            timerType: VirtualTimeTimer.self
        )
        linker.start(with: eventNotificationCenter)
    }

    override func tearDown() {
        linker = nil
        VirtualTimeTimer.invalidate()
        time = nil
        eventNotificationCenter = nil
        database = nil
        super.tearDown()
    }

    func test_messageNew_whenChannelActivityIsWithinCutoff_linksChannel() throws {
        let cid = ChannelId.unique
        try saveFilteredGroup()
        // The event's message is already saved when observers are notified.
        try saveChannel(cid: cid, lastMessageAt: daysBeforeNow(0), isLinked: false)

        try process(messageNewEvent(cid: cid))

        XCTAssertEqual(true, isLinked(cid))
    }

    func test_messageNew_whenChannelActivityIsOutsideCutoff_unlinksChannel() throws {
        let cid = ChannelId.unique
        try saveFilteredGroup()
        try saveChannel(cid: cid, lastMessageAt: daysBeforeNow(30), isLinked: true)

        try process(messageNewEvent(cid: cid))

        XCTAssertEqual(false, isLinked(cid))
    }

    func test_messageNew_whenNotLoadedUnreadChannelIsLinked_movesItOutOfTheNotLoadedCount() throws {
        let cid = ChannelId.unique
        try saveFilteredGroup(groupNotLoadedUnreadCount: 2)
        try saveChannel(cid: cid, lastMessageAt: daysBeforeNow(0), unreadMessages: 2, isLinked: false)

        try process(messageNewEvent(cid: cid))

        XCTAssertEqual(["expired": 2], unreadChannelCountsByGroup())
    }

    func test_expirySweep_whenUnreadChannelExpires_unlinksItAndUpdatesFilteredGroupUnreadCount() throws {
        let cid = ChannelId.unique
        try saveFilteredGroup()
        try saveChannel(cid: cid, lastMessageAt: daysBeforeNow(30), unreadMessages: 1, isLinked: true)
        try database.writeSynchronously { session in
            session.updateFilteredGroupUnreadChannelCounts(for: [session.channelListQuery(self.query)].compactMap { $0 })
        }
        XCTAssertEqual(["expired": 1], unreadChannelCountsByGroup())

        time.run(numberOfSeconds: 60)
        try database.writeSynchronously { _ in }

        XCTAssertEqual(false, isLinked(cid))
        XCTAssertEqual(["expired": 0], unreadChannelCountsByGroup())
    }

    // MARK: - Helpers

    // The cutoff is resolved when the predicate is built, so dates are relative to the wall clock.
    private func daysBeforeNow(_ days: Int) -> Date {
        Date().addingTimeInterval(-TimeInterval(days) * 86400)
    }

    private func saveFilteredGroup(groupNotLoadedUnreadCount: Int64 = 0) throws {
        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: .dummy(userId: self.currentUserId, role: .user))
            let queryDTO = session.saveQuery(query: self.query)
            queryDTO.groupFilterJSONData = Data(#"{"query_timestamp":{"$gte":"now-14d"}}"#.utf8)
            queryDTO.groupNotLoadedUnreadCount = groupNotLoadedUnreadCount
        }
    }

    private func saveChannel(cid: ChannelId, lastMessageAt: Date, unreadMessages: Int = 0, isLinked: Bool) throws {
        let read = ChannelReadPayload(user: .dummy(userId: currentUserId), lastReadAt: lastMessageAt, lastReadMessageId: nil, unreadMessagesCount: unreadMessages)
        let payload = ChannelPayload.dummy(
            channel: .dummy(cid: cid, extraData: [GroupedChannelKey.group: .string("expired")], lastMessageAt: lastMessageAt, createdAt: lastMessageAt),
            channelReads: [read]
        )
        try database.writeSynchronously { session in
            let channelDTO = try session.saveChannel(payload: payload)
            if isLinked {
                session.channelListQuery(self.query)?.channels.insert(channelDTO)
            }
        }
    }

    private func unreadChannelCountsByGroup() -> [String: Int]? {
        try? database.readSynchronously { $0.currentUser?.unreadChannelCountsByGroup }
    }

    private func isLinked(_ cid: ChannelId) -> Bool? {
        try? database.readSynchronously { session in
            session.channelListQuery(self.query)?.channels.contains { $0.cid == cid.rawValue } ?? false
        }
    }

    private func messageNewEvent(cid: ChannelId) -> MessageNewEvent {
        MessageNewEvent(
            user: .unique,
            message: .mock(cid: cid),
            channel: .mock(cid: cid),
            createdAt: .unique,
            watcherCount: nil,
            unreadCount: nil
        )
    }

    // Observers are notified before the completion runs and the linker's write is queued on the serial
    // writable context, so an empty write after it is a barrier for the linking result.
    private func process(_ event: Event) throws {
        let expectation = expectation(description: "Event processed")
        eventNotificationCenter.process([event], completion: { expectation.fulfill() })
        wait(for: [expectation], timeout: defaultTimeout)
        try database.writeSynchronously { _ in }
    }
}
