//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class GroupedChannelListLinker_Tests: XCTestCase {
    private var channelWatcherHandler: ChannelWatcherHandler_Mock!
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
        channelWatcherHandler = ChannelWatcherHandler_Mock()
        linker = GroupedChannelListLinker(
            query: query,
            databaseContainer: database,
            channelWatcherHandler: channelWatcherHandler,
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
        channelWatcherHandler = nil
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

    func test_expirySweep_whenGroupHasNoFilter_unlinksOnlyChannelThatLeftTheGroup() throws {
        let leftCid = ChannelId.unique
        let stayingCid = ChannelId.unique
        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: .dummy(userId: self.currentUserId, role: .user))
            _ = session.saveQuery(query: self.query)
        }
        try saveChannel(cid: stayingCid, lastMessageAt: daysBeforeNow(30), isLinked: true)
        try saveChannel(cid: leftCid, lastMessageAt: daysBeforeNow(0), isLinked: true)
        // Events replayed by reconnect sync are not posted, so only the stored group changes.
        try saveChannel(cid: leftCid, group: "ended", lastMessageAt: daysBeforeNow(0), isLinked: false)

        time.run(numberOfSeconds: 60)
        try database.writeSynchronously { _ in }

        XCTAssertEqual(false, isLinked(leftCid))
        XCTAssertEqual(true, isLinked(stayingCid))
    }

    func test_expirySweep_whenLinkedChannelIsHidden_unlinksChannel() throws {
        let cid = ChannelId.unique
        try saveFilteredGroup()
        try saveChannel(cid: cid, lastMessageAt: daysBeforeNow(0), isHidden: true, isLinked: true)

        time.run(numberOfSeconds: 60)
        try database.writeSynchronously { _ in }

        XCTAssertEqual(false, isLinked(cid))
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

    func test_messageNew_whenChannelHasNoGroup_linksItOnlyIntoAllGroup() throws {
        let allQuery = ChannelListQuery(groupKey: GroupedChannelKey.all)
        let allLinker = GroupedChannelListLinker(
            query: allQuery,
            databaseContainer: database,
            channelWatcherHandler: ChannelWatcherHandler_Mock(),
            timerType: VirtualTimeTimer.self
        )
        allLinker.start(with: eventNotificationCenter)
        try saveFilteredGroup()
        try saveFilteredGroup(query: allQuery)
        let cid = ChannelId.unique
        try saveChannel(cid: cid, group: nil, lastMessageAt: daysBeforeNow(0), isLinked: false)

        try process(messageNewEvent(cid: cid))

        XCTAssertEqual(true, isLinked(cid, in: allQuery))
        XCTAssertEqual(false, isLinked(cid))
    }

    func test_messageNew_whenCurrentUserIsNotMember_doesNotLinkChannel() throws {
        let cid = ChannelId.unique
        try saveFilteredGroup()
        try saveChannel(cid: cid, lastMessageAt: daysBeforeNow(0), isMember: false, isLinked: false)

        try process(messageNewEvent(cid: cid))

        XCTAssertEqual(false, isLinked(cid))
    }

    func test_channelPartialUpdated_whenStoredChannelEntersTheGroup_linksChannel() throws {
        let cid = ChannelId.unique
        try saveFilteredGroup()
        try saveChannel(cid: cid, lastMessageAt: daysBeforeNow(0), isLinked: false)

        try process(channelPartialUpdatedEvent(cid: cid, group: "expired", isStored: true))

        XCTAssertEqual(true, isLinked(cid))
    }

    func test_channelPartialUpdated_whenChannelIsNotStoredAndJoinsTheGroup_watchesAndLinksChannel() throws {
        let cid = ChannelId.unique
        try saveFilteredGroup(watch: true)

        try process(channelPartialUpdatedEvent(cid: cid, group: "expired", isStored: false))
        XCTAssertEqual([cid], channelWatcherHandler.attemptToWatch_channelIds)
        XCTAssertEqual(false, isLinked(cid))

        // Watching saves the channel before the completion runs.
        try saveChannel(cid: cid, lastMessageAt: daysBeforeNow(0), isLinked: false)
        channelWatcherHandler.attemptToWatch_completion?(nil)
        try database.writeSynchronously { _ in }

        XCTAssertEqual(true, isLinked(cid))
        XCTAssertEqual(1, channelWatcherHandler.attemptToWatch_callCount)
    }

    func test_channelPartialUpdated_whenChannelIsNotStoredAndGroupDoesNotWatch_doesNotWatchChannel() throws {
        let cid = ChannelId.unique
        try saveFilteredGroup(watch: false)

        try process(channelPartialUpdatedEvent(cid: cid, group: "expired", isStored: false))

        XCTAssertEqual(0, channelWatcherHandler.attemptToWatch_callCount)
    }

    func test_channelPartialUpdated_whenChannelIsNotStoredAndBelongsToAnotherGroup_doesNotWatchChannel() throws {
        let cid = ChannelId.unique
        try saveFilteredGroup()

        try process(channelPartialUpdatedEvent(cid: cid, group: "ended", isStored: false))

        XCTAssertEqual(0, channelWatcherHandler.attemptToWatch_callCount)
    }

    // MARK: - Helpers

    // The cutoff is resolved when the predicate is built, so dates are relative to the wall clock.
    private func daysBeforeNow(_ days: Int) -> Date {
        Date().addingTimeInterval(-TimeInterval(days) * 86400)
    }

    private func saveFilteredGroup(
        query: ChannelListQuery? = nil,
        filter: Filter<GroupedChannelsFilterScope> = .greaterOrEqual(.queryTimestamp, than: .daysAgo(14)),
        groupNotLoadedUnreadCount: Int64 = 0,
        watch: Bool = false
    ) throws {
        let filterJSONData = try JSONEncoder.stream.encode(filter)
        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: .dummy(userId: self.currentUserId, role: .user))
            let queryDTO = session.saveQuery(query: query ?? self.query)
            queryDTO.groupFilterJSONData = filterJSONData
            queryDTO.groupNotLoadedUnreadCount = groupNotLoadedUnreadCount
            queryDTO.watch = watch
        }
    }

    private func saveChannel(
        cid: ChannelId,
        group: String? = "expired",
        lastMessageAt: Date,
        unreadMessages: Int = 0,
        isHidden: Bool = false,
        isDisabled: Bool = false,
        deletedAt: Date? = nil,
        isMember: Bool = true,
        isLinked: Bool
    ) throws {
        let read = ChannelReadPayload(user: .dummy(userId: currentUserId), lastReadAt: lastMessageAt, lastReadMessageId: nil, unreadMessagesCount: unreadMessages)
        let payload = ChannelPayload.dummy(
            channel: .dummy(
                cid: cid,
                extraData: group.map { [GroupedChannelKey.group: .string($0)] } ?? [:],
                lastMessageAt: lastMessageAt,
                createdAt: lastMessageAt,
                deletedAt: deletedAt,
                isDisabled: isDisabled,
                isHidden: isHidden
            ),
            membership: isMember ? .dummy(user: .dummy(userId: currentUserId)) : nil,
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

    private func channelPartialUpdatedEvent(cid: ChannelId, group: String, isStored: Bool) -> NotificationChannelPartialUpdatedEvent {
        NotificationChannelPartialUpdatedEvent(
            cid: cid,
            group: group,
            isChannelStored: isStored,
            createdAt: .unique
        )
    }

    // Observers are notified before the completion runs and the linker's write is queued on the serial
    // writable context, so an empty write after it is a barrier for the linking result.
    // The same holds for the linker's reads on the serial read-only context.
    private func process(_ event: Event) throws {
        let expectation = expectation(description: "Event processed")
        eventNotificationCenter.process([event], completion: { expectation.fulfill() })
        wait(for: [expectation], timeout: defaultTimeout)
        try database.writeSynchronously { _ in }
        try database.readSynchronously { _ in }
    }
}
