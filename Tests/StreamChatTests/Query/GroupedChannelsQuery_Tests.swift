//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class GroupedChannelsQuery_Tests: XCTestCase {
    func test_groupedFilterPredicate_allFilter_matchesPerBranchCutoffs() throws {
        let filter = Filter<GroupedChannelsFilterScope>.or([
            .and([.equal(.group, to: "ended"), .greaterOrEqual(.queryTimestamp, than: .daysAgo(7))]),
            .in(.group, values: ["campaign", "new"]),
            .and([.equal(.group, to: "expired"), .greaterOrEqual(.queryTimestamp, than: .daysAgo(14))])
        ])
        let predicate = try XCTUnwrap(Filter<GroupedChannelsFilterScope>.groupedFilter(fromJSONData: JSONEncoder.stream.encode(filter))?.predicate)

        XCTAssertTrue(predicate.evaluate(with: channel(group: "ended", daysAgo: 6)))
        XCTAssertFalse(predicate.evaluate(with: channel(group: "ended", daysAgo: 8)))
        XCTAssertTrue(predicate.evaluate(with: channel(group: "new", daysAgo: 400)))
        XCTAssertTrue(predicate.evaluate(with: channel(group: "expired", daysAgo: 13)))
        XCTAssertFalse(predicate.evaluate(with: channel(group: "expired", daysAgo: 15)))
        XCTAssertFalse(predicate.evaluate(with: channel(group: "bee", daysAgo: 0)))
        XCTAssertFalse(predicate.evaluate(with: channel(group: "renewal", daysAgo: 0)))
    }

    func test_groupedFilterPredicate_dateCutoff_matchesChannelsSinceDate() throws {
        let filter = Filter<GroupedChannelsFilterScope>.greaterOrEqual(.queryTimestamp, than: .date(Date().addingTimeInterval(-7 * 86400)))
        let predicate = try XCTUnwrap(Filter<GroupedChannelsFilterScope>.groupedFilter(fromJSONData: JSONEncoder.stream.encode(filter))?.predicate)

        XCTAssertTrue(predicate.evaluate(with: channel(group: "expired", daysAgo: 6)))
        XCTAssertFalse(predicate.evaluate(with: channel(group: "expired", daysAgo: 8)))
    }

    func test_groupedFilterPredicate_groupMatchIsExact() throws {
        let filter = Filter<GroupedChannelsFilterScope>.or([
            .equal(.group, to: "Ended"),
            .in(.group, values: ["new"])
        ])
        let predicate = try XCTUnwrap(Filter<GroupedChannelsFilterScope>.groupedFilter(fromJSONData: JSONEncoder.stream.encode(filter))?.predicate)

        XCTAssertTrue(predicate.evaluate(with: channel(group: "Ended", daysAgo: 0)))
        XCTAssertFalse(predicate.evaluate(with: channel(group: "ended", daysAgo: 0)))
        XCTAssertTrue(predicate.evaluate(with: channel(group: "new", daysAgo: 0)))
        XCTAssertFalse(predicate.evaluate(with: channel(group: "New", daysAgo: 0)))
    }

    // Key-value coding stand-in for `ChannelDTO`, matching the key paths of the grouped filter keys.
    private func channel(group: String, daysAgo: Double) -> NSDictionary {
        [
            #keyPath(ChannelDTO.group): group,
            #keyPath(ChannelDTO.queryTimestamp): Date().addingTimeInterval(-daysAgo * 86400)
        ]
    }
}
