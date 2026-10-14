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

        try process(messageNewEvent(cid: cid))

        XCTAssertEqual(true, isLinked(cid))
    }

    func test_messageNew_whenChannelActivityIsWithinCutoff_linksChannel() throws {
        let cid = ChannelId.unique
        try saveGroup(filterJSON: cutoffFilterJSON)
        // The event's message is already saved when observers are notified.
        try saveChannel(cid: cid, group: "expired", lastMessageAt: daysBeforeNow(0), isLinked: false)

        try process(messageNewEvent(cid: cid))

        XCTAssertEqual(true, isLinked(cid))
    }

    func test_messageNew_whenChannelActivityIsOutsideCutoff_unlinksChannel() throws {
        let cid = ChannelId.unique
        try saveGroup(filterJSON: cutoffFilterJSON)
        try saveChannel(cid: cid, group: "expired", lastMessageAt: daysBeforeNow(30), isLinked: true)

        try process(messageNewEvent(cid: cid))

        XCTAssertEqual(false, isLinked(cid))
    }

    func test_channelUpdated_whenChannelMovesToAnotherGroup_unlinksChannel() throws {
        let cid = ChannelId.unique
        try saveGroup(filterJSON: cutoffFilterJSON)
        try saveChannel(cid: cid, group: "expired", lastMessageAt: daysBeforeNow(1), isLinked: true)
        // The updated channel is already saved when observers are notified.
        try saveChannel(cid: cid, group: "new", lastMessageAt: daysBeforeNow(1), isLinked: true)

        try process(ChannelUpdatedEvent(channel: .mock(cid: cid), user: nil, message: nil, createdAt: .unique))

        XCTAssertEqual(false, isLinked(cid))
    }

    // MARK: - Cutoff Expiry

    func test_expirySweep_whenGroupHasNoFilter_keepsChannels() throws {
        let cid = ChannelId.unique
        try saveGroup(filterJSON: nil)
        try saveChannel(cid: cid, group: "expired", lastMessageAt: daysBeforeNow(30), isLinked: true)

        try runExpirySweep()

        XCTAssertEqual(true, isLinked(cid))
    }

    func test_expirySweep_afterFirstPageWithinCutoffs_keepsEveryChannelLinked() throws {
        let groupsJSON = #"""
        {
          "all": {
            "filter_conditions": {
              "$or": [
                {"group": "ended", "query_timestamp": {"$gte": "now-7d"}},
                {"group": "campaign"},
                {"group": "new"},
                {"group": "current", "query_timestamp": {"$gte": "now-365d"}},
                {"group": "expired", "query_timestamp": {"$gte": "now-14d"}}
              ]
            }
          },
          "current": {"filter_conditions": {"query_timestamp": {"$gte": "now-365d"}}},
          "new": {},
          "expired": {"filter_conditions": {"query_timestamp": {"$gte": "now-14d"}}}
        }
        """#
        let groups = try JSONDecoder.stream.decode([String: [String: RawJSON]].self, from: Data(groupsJSON.utf8))
            .mapValues { GroupedChannelsGroupRequest(filterConditions: $0["filter_conditions"]) }
        let groupLinkers = ["all", "current", "new"].map { groupKey in
            let linker = GroupedChannelListLinker(
                query: ChannelListQuery(groupKey: groupKey),
                databaseContainer: database,
                channelWatcherHandler: ChannelWatcherHandler_Mock(),
                timerType: VirtualTimeTimer.self
            )
            linker.start(with: eventNotificationCenter)
            return linker
        }
        let ended = channelPayload(cid: .unique, group: "ended", lastMessageAt: daysBeforeNow(6))
        let campaign = channelPayload(cid: .unique, group: "campaign", lastMessageAt: daysBeforeNow(400))
        let new = channelPayload(cid: .unique, group: "new", lastMessageAt: daysBeforeNow(400))
        let current = channelPayload(cid: .unique, group: "current", lastMessageAt: daysBeforeNow(364))
        let expired = channelPayload(cid: .unique, group: "expired", lastMessageAt: daysBeforeNow(13))
        let expectedLinks: [String: Set<String>] = [
            "all": Set([ended, campaign, new, current, expired].map(\.channel.cid.rawValue)),
            "current": [current.channel.cid.rawValue],
            "new": [new.channel.cid.rawValue],
            "expired": [expired.channel.cid.rawValue]
        ]

        // Load the first page of every group.
        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: .dummy(userId: .unique, role: .user))
        }
        let apiClient = APIClient_Spy()
        let updater = ChannelListUpdater(database: database, apiClient: apiClient)
        let firstPageLoaded = expectation(description: "First page loaded")
        updater.queryGroupedChannels(
            groups: groups,
            limit: 10,
            sort: [.init(direction: -1, field: "query_timestamp")],
            watch: false,
            presence: false
        ) { result in
            XCTAssertNil(result.error)
            firstPageLoaded.fulfill()
        }
        apiClient.test_simulateResponse(Result<GroupedQueryChannelsResponse, Error>.success(.init(groups: [
            "all": .init(channels: [ended, campaign, new, current, expired]),
            "current": .init(channels: [current]),
            "new": .init(channels: [new]),
            "expired": .init(channels: [expired])
        ])))
        wait(for: [firstPageLoaded], timeout: defaultTimeout)
        XCTAssertEqual(expectedLinks, linkedChannelsByGroup(Array(expectedLinks.keys)))

        try runExpirySweep()

        XCTAssertEqual(expectedLinks, linkedChannelsByGroup(Array(expectedLinks.keys)))
        withExtendedLifetime(groupLinkers) {}
    }

    // MARK: - Helpers

    // The cutoff is resolved when the predicate is built, so dates are relative to the wall clock.
    private func daysBeforeNow(_ days: Int) -> Date {
        Date().addingTimeInterval(-TimeInterval(days) * 86400)
    }

    private func saveGroup(filterJSON: String?) throws {
        try database.writeSynchronously { session in
            let queryDTO = session.saveQuery(query: self.query)
            queryDTO.groupFilterJSONData = filterJSON.map { Data($0.utf8) }
        }
    }

    private func saveChannel(
        cid: ChannelId,
        group: String,
        lastMessageAt: Date,
        isLinked: Bool
    ) throws {
        let payload = channelPayload(cid: cid, group: group, lastMessageAt: lastMessageAt)
        try database.writeSynchronously { session in
            let channelDTO = try session.saveChannel(payload: payload)
            if isLinked {
                session.channelListQuery(self.query)?.channels.insert(channelDTO)
            }
        }
    }

    private func channelPayload(cid: ChannelId, group: String, lastMessageAt: Date) -> ChannelPayload {
        .dummy(channel: .dummy(
            cid: cid,
            extraData: [GroupedChannelKey.group: .string(group)],
            lastMessageAt: lastMessageAt,
            createdAt: lastMessageAt
        ))
    }

    private func linkedChannelsByGroup(_ groupKeys: [String]) -> [String: Set<String>]? {
        try? database.readSynchronously { session in
            groupKeys.reduce(into: [:]) { result, groupKey in
                result[groupKey] = Set(session.channelListQuery(ChannelListQuery(groupKey: groupKey))?.channels.map(\.cid) ?? [])
            }
        }
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

    private func runExpirySweep() throws {
        time.run(numberOfSeconds: 60)
        try database.writeSynchronously { _ in }
    }
}
