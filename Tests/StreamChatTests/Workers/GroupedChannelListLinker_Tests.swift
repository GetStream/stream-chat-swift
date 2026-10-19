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

    func test_channelUpdated_whenStoredGroupLeavesTheGroup_unlinksChannel() throws {
        let cid = ChannelId.unique
        try saveFilteredGroup()
        try saveChannel(cid: cid, lastMessageAt: daysBeforeNow(0), isLinked: true)
        try saveChannel(cid: cid, group: "ended", lastMessageAt: daysBeforeNow(0), isLinked: false)

        // The group is read from the stored channel, not from the event payload.
        let staleChannel = ChatChannel.mock(cid: cid, extraData: [GroupedChannelKey.group: .string("expired")])
        try process(ChannelUpdatedEvent(channel: staleChannel, user: nil, message: nil, createdAt: .unique))

        XCTAssertEqual(false, isLinked(cid))
    }

    func test_channelHidden_unlinksChannel_andChannelVisibleLinksItBack() throws {
        let cid = ChannelId.unique
        try saveFilteredGroup()
        // Middlewares update the hidden state before observers are notified.
        try saveChannel(cid: cid, lastMessageAt: daysBeforeNow(0), isHidden: true, isLinked: true)

        try process(ChannelHiddenEvent(cid: cid, user: .unique, isHistoryCleared: false, createdAt: .unique))
        XCTAssertEqual(false, isLinked(cid))

        try saveChannel(cid: cid, lastMessageAt: daysBeforeNow(0), isLinked: false)
        try process(ChannelVisibleEvent(cid: cid, user: .unique, createdAt: .unique))
        XCTAssertEqual(true, isLinked(cid))
    }

    func test_messageNew_whenChannelStaysHidden_doesNotLinkChannel() throws {
        let cid = ChannelId.unique
        try saveFilteredGroup()
        // A message from a blocked user does not unhide the channel.
        try saveChannel(cid: cid, lastMessageAt: daysBeforeNow(0), isHidden: true, isLinked: false)

        try process(messageNewEvent(cid: cid))

        XCTAssertEqual(false, isLinked(cid))
    }

    func test_channelDeleted_unlinksChannel() throws {
        let cid = ChannelId.unique
        try saveFilteredGroup()
        try saveChannel(cid: cid, lastMessageAt: daysBeforeNow(0), deletedAt: .unique, isLinked: true)

        try process(ChannelDeletedEvent(channel: .mock(cid: cid), user: nil, createdAt: .unique))

        XCTAssertEqual(false, isLinked(cid))
    }

    func test_notificationChannelDeleted_unlinksChannel() throws {
        let cid = ChannelId.unique
        try saveFilteredGroup()
        try saveChannel(cid: cid, lastMessageAt: daysBeforeNow(0), deletedAt: .unique, isLinked: true)

        try process(NotificationChannelDeletedEvent(cid: cid, channel: .mock(cid: cid), createdAt: .unique))

        XCTAssertEqual(false, isLinked(cid))
    }

    func test_channelUpdated_whenChannelIsDisabled_unlinksChannel() throws {
        let cid = ChannelId.unique
        try saveFilteredGroup()
        try saveChannel(cid: cid, lastMessageAt: daysBeforeNow(0), isDisabled: true, isLinked: true)

        try process(ChannelUpdatedEvent(channel: .mock(cid: cid), user: nil, message: nil, createdAt: .unique))

        XCTAssertEqual(false, isLinked(cid))
    }

    func test_notificationRemovedFromChannel_unlinksChannelAndUpdatesFilteredGroupUnreadCount() throws {
        let cid = ChannelId.unique
        try saveFilteredGroup()
        try saveChannel(cid: cid, lastMessageAt: daysBeforeNow(0), unreadMessages: 1, isLinked: true)
        try database.writeSynchronously { session in
            session.updateFilteredGroupUnreadChannelCounts(for: [session.channelListQuery(self.query)].compactMap { $0 })
        }
        XCTAssertEqual(["expired": 1], unreadChannelCountsByGroup())

        try process(NotificationRemovedFromChannelEvent(user: .unique, cid: cid, member: .mock(id: currentUserId), createdAt: .unique))

        XCTAssertEqual(false, isLinked(cid))
        XCTAssertEqual(["expired": 0], unreadChannelCountsByGroup())
    }

    func test_messageNew_inFilteredAllGroup_linksChannelsMatchingTheirBranch() throws {
        let allQuery = ChannelListQuery(groupKey: GroupedChannelKey.all)
        let allLinker = GroupedChannelListLinker(
            query: allQuery,
            databaseContainer: database,
            channelWatcherHandler: ChannelWatcherHandler_Mock(),
            timerType: VirtualTimeTimer.self
        )
        allLinker.start(with: eventNotificationCenter)
        try saveFilteredGroup(query: allQuery, filter: .or([
            .and([.equal(.group, to: "ended"), .greaterOrEqual(.queryTimestamp, than: .daysAgo(7))]),
            .in(.group, values: ["new"])
        ]))
        let recentEndedCid = ChannelId.unique
        let oldEndedCid = ChannelId.unique
        let oldNewCid = ChannelId.unique
        try saveChannel(cid: recentEndedCid, group: "ended", lastMessageAt: daysBeforeNow(3), isLinked: false)
        try saveChannel(cid: oldEndedCid, group: "ended", lastMessageAt: daysBeforeNow(30), isLinked: false)
        try saveChannel(cid: oldNewCid, group: "new", lastMessageAt: daysBeforeNow(400), isLinked: false)

        for cid in [recentEndedCid, oldEndedCid, oldNewCid] {
            try process(messageNewEvent(cid: cid))
        }

        XCTAssertEqual(true, isLinked(recentEndedCid, in: allQuery))
        XCTAssertEqual(false, isLinked(oldEndedCid, in: allQuery))
        XCTAssertEqual(true, isLinked(oldNewCid, in: allQuery))
    }

    // MARK: - Helpers

    // The cutoff is resolved when the predicate is built, so dates are relative to the wall clock.
    private func daysBeforeNow(_ days: Int) -> Date {
        Date().addingTimeInterval(-TimeInterval(days) * 86400)
    }

    private func saveFilteredGroup(
        query: ChannelListQuery? = nil,
        filter: Filter<GroupedChannelsFilterScope> = .greaterOrEqual(.queryTimestamp, than: .daysAgo(14)),
        groupNotLoadedUnreadCount: Int64 = 0
    ) throws {
        let filterJSONData = try JSONEncoder.stream.encode(filter)
        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: .dummy(userId: self.currentUserId, role: .user))
            let queryDTO = session.saveQuery(query: query ?? self.query)
            queryDTO.groupFilterJSONData = filterJSONData
            queryDTO.groupNotLoadedUnreadCount = groupNotLoadedUnreadCount
        }
    }

    private func saveChannel(
        cid: ChannelId,
        group: String = "expired",
        lastMessageAt: Date,
        unreadMessages: Int = 0,
        isHidden: Bool = false,
        isDisabled: Bool = false,
        deletedAt: Date? = nil,
        isLinked: Bool
    ) throws {
        let read = ChannelReadPayload(user: .dummy(userId: currentUserId), lastReadAt: lastMessageAt, lastReadMessageId: nil, unreadMessagesCount: unreadMessages)
        let payload = ChannelPayload.dummy(
            channel: .dummy(
                cid: cid,
                extraData: [GroupedChannelKey.group: .string(group)],
                lastMessageAt: lastMessageAt,
                createdAt: lastMessageAt,
                deletedAt: deletedAt,
                isDisabled: isDisabled,
                isHidden: isHidden
            ),
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

    private func isLinked(_ cid: ChannelId, in query: ChannelListQuery? = nil) -> Bool? {
        try? database.readSynchronously { session in
            session.channelListQuery(query ?? self.query)?.channels.contains { $0.cid == cid.rawValue } ?? false
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
