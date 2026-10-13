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
    private let cutoffFilterJSON = #"{"query_timestamp":{"$gte":"now-14d"}}"#

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

    // MARK: - Events

    func test_messageNew_whenGroupHasNoFilter_linksChannelRegardlessOfActivity() throws {
        let cid = ChannelId.unique
        try saveGroup(filterJSON: nil)
        try saveChannel(cid: cid, group: "expired", lastMessageAt: daysBeforeNow(30), isLinked: false)

        process(messageNewEvent(cid: cid, group: "expired", messageCreatedAt: daysBeforeNow(30)))

        AssertAsync.willBeTrue(isLinked(cid))
    }

    func test_messageNew_whenNewMessageIsWithinCutoff_linksChannel() throws {
        let cid = ChannelId.unique
        try saveGroup(filterJSON: cutoffFilterJSON)
        try saveChannel(cid: cid, group: "expired", lastMessageAt: daysBeforeNow(30), isLinked: false)

        process(messageNewEvent(cid: cid, group: "expired", messageCreatedAt: daysBeforeNow(0)))

        AssertAsync.willBeTrue(isLinked(cid))
    }

    func test_messageNew_whenChannelActivityIsOutsideCutoff_unlinksChannel() throws {
        let cid = ChannelId.unique
        try saveGroup(filterJSON: cutoffFilterJSON)
        try saveChannel(cid: cid, group: "expired", lastMessageAt: daysBeforeNow(30), isLinked: true)

        process(messageNewEvent(cid: cid, group: "expired", messageCreatedAt: daysBeforeNow(30)))

        AssertAsync.willBeTrue(isLinked(cid) == false)
    }

    func test_channelUpdated_whenChannelMovesToAnotherGroup_unlinksChannel() throws {
        let cid = ChannelId.unique
        try saveGroup(filterJSON: cutoffFilterJSON)
        try saveChannel(cid: cid, group: "expired", lastMessageAt: daysBeforeNow(1), isLinked: true)

        process(ChannelUpdatedEvent(
            channel: .mock(cid: cid, lastMessageAt: daysBeforeNow(1), createdAt: daysBeforeNow(1), extraData: ["group": .string("new")]),
            user: nil,
            message: nil,
            createdAt: daysBeforeNow(0)
        ))

        AssertAsync.willBeTrue(isLinked(cid) == false)
    }

    // MARK: - Cutoff Expiry

    func test_expirySweep_unlinksChannelsThatPassedTheCutoff() throws {
        let expiredCid = ChannelId.unique
        let recentCid = ChannelId.unique
        try saveGroup(filterJSON: cutoffFilterJSON)
        try saveChannel(cid: expiredCid, group: "expired", lastMessageAt: daysBeforeNow(15), isLinked: true)
        try saveChannel(cid: recentCid, group: "expired", lastMessageAt: daysBeforeNow(13), isLinked: true)

        time.run(numberOfSeconds: 60)

        AssertAsync {
            Assert.willBeEqual(self.isLinked(expiredCid), false)
            Assert.staysEqual(self.isLinked(recentCid), true)
        }
    }

    func test_expirySweep_whenGroupHasNoFilter_keepsChannels() throws {
        let cid = ChannelId.unique
        try saveGroup(filterJSON: nil)
        try saveChannel(cid: cid, group: "expired", lastMessageAt: daysBeforeNow(30), isLinked: true)

        time.run(numberOfSeconds: 60)

        AssertAsync.staysTrue(isLinked(cid) == true)
    }

    // MARK: - Helpers

    private func daysBeforeNow(_ days: Int) -> Date {
        VirtualTimeTimer.currentTime().addingTimeInterval(-TimeInterval(days) * 86400)
    }

    private func saveGroup(filterJSON: String?) throws {
        try database.writeSynchronously { [query] session in
            let queryDTO = session.saveQuery(query: query)
            queryDTO.groupFilterJSONData = filterJSON.map { Data($0.utf8) }
        }
    }

    private func saveChannel(cid: ChannelId, group: String, lastMessageAt: Date, isLinked: Bool) throws {
        try database.writeSynchronously { [query] session in
            let channelDTO = try session.saveChannel(payload: .dummy(channel: .dummy(
                cid: cid,
                extraData: ["group": .string(group)],
                lastMessageAt: lastMessageAt,
                createdAt: lastMessageAt
            )))
            if isLinked {
                session.channelListQuery(query)?.channels.insert(channelDTO)
            }
        }
    }

    private func isLinked(_ cid: ChannelId) -> Bool? {
        try? database.readSynchronously { [query] session in
            session.channelListQuery(query)?.channels.contains { $0.cid == cid.rawValue } ?? false
        }
    }

    private func messageNewEvent(cid: ChannelId, group: String, messageCreatedAt: Date) -> MessageNewEvent {
        MessageNewEvent(
            user: .unique,
            message: .mock(cid: cid, createdAt: messageCreatedAt),
            channel: .mock(
                cid: cid,
                lastMessageAt: daysBeforeNow(30),
                createdAt: daysBeforeNow(30),
                extraData: ["group": .string(group)]
            ),
            createdAt: messageCreatedAt,
            watcherCount: nil,
            unreadCount: nil
        )
    }

    private func process(_ event: Event) {
        let expectation = expectation(description: "Event processed")
        eventNotificationCenter.process([event], completion: { expectation.fulfill() })
        wait(for: [expectation], timeout: defaultTimeout)
    }
}
