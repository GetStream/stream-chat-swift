//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class GroupedChannelsQuery_Tests: XCTestCase {
    func test_queryTimestamp_daysAgo_encodesRelativeCutoff() throws {
        let filter = Filter<GroupedChannelsFilterScope>.greaterOrEqual(.queryTimestamp, than: .daysAgo(7))

        AssertJSONEqual(try JSONEncoder.stream.encode(filter), Data(#"{"query_timestamp":{"$gte":"now-7d"}}"#.utf8))
    }

    func test_queryTimestamp_date_encodesWithEncoderDateStrategy() throws {
        let date = Date(timeIntervalSince1970: 1_760_000_000)
        let filter = Filter<GroupedChannelsFilterScope>.greaterOrEqual(.queryTimestamp, than: .date(date))

        let dateString = try XCTUnwrap(String(data: JSONEncoder.stream.encode(date), encoding: .utf8))
        AssertJSONEqual(try JSONEncoder.stream.encode(filter), Data(#"{"query_timestamp":{"$gte":\#(dateString)}}"#.utf8))
    }

    func test_requests_mapGroupsAndSort() {
        let query = GroupedChannelsQuery(
            groups: [
                .init(key: "new"),
                .init(key: "expired", filter: .greaterOrEqual(.queryTimestamp, than: .daysAgo(14)))
            ],
            sort: [.init(key: .queryTimestamp)]
        )

        XCTAssertEqual(["expired", "new"], query.groupRequests?.keys.sorted())
        XCTAssertNil(query.groupRequests?["new"]?.filterConditions)
        XCTAssertNotNil(query.groupRequests?["expired"]?.filterConditions)
        XCTAssertEqual(["query_timestamp"], query.sortRequests?.map(\.field))
        XCTAssertEqual([-1], query.sortRequests?.map(\.direction))
    }

    func test_requests_whenGroupsAndSortAreEmpty_areNil() {
        let query = GroupedChannelsQuery(groups: [])

        XCTAssertNil(query.groupRequests)
        XCTAssertNil(query.sortRequests)
        XCTAssertTrue(query.watch)
        XCTAssertFalse(query.presence)
        XCTAssertNil(query.limit)
    }

    // MARK: - Persisted Filter Predicate

    func test_groupedFilterPredicate_allFilter_matchesPerBranchCutoffs() throws {
        let filter = Filter<GroupedChannelsFilterScope>.or([
            .and([.equal(.group, to: "ended"), .greaterOrEqual(.queryTimestamp, than: .daysAgo(7))]),
            .in(.group, values: ["campaign", "new"]),
            .and([.equal(.group, to: "expired"), .greaterOrEqual(.queryTimestamp, than: .daysAgo(14))])
        ])
        let predicate = try XCTUnwrap(groupedFilterPredicate(JSONEncoder.stream.encode(filter)))

        XCTAssertTrue(predicate.evaluate(with: channel(group: "ended", daysAgo: 6)))
        XCTAssertFalse(predicate.evaluate(with: channel(group: "ended", daysAgo: 8)))
        XCTAssertTrue(predicate.evaluate(with: channel(group: "new", daysAgo: 400)))
        XCTAssertTrue(predicate.evaluate(with: channel(group: "expired", daysAgo: 13)))
        XCTAssertFalse(predicate.evaluate(with: channel(group: "expired", daysAgo: 15)))
        XCTAssertFalse(predicate.evaluate(with: channel(group: "bee", daysAgo: 0)))
        XCTAssertFalse(predicate.evaluate(with: channel(group: "renewal", daysAgo: 0)))
    }

    func test_groupedFilterPredicate_relativeCutoffs_matchAfterTheCutoff() throws {
        for json in [#"{"query_timestamp":{"$gte":"now-14d"}}"#, #"{"query_timestamp":{"$gte":"14d"}}"#] {
            let predicate = try XCTUnwrap(groupedFilterPredicate(Data(json.utf8)))

            XCTAssertTrue(predicate.evaluate(with: channel(group: "expired", daysAgo: 13.9)), json)
            XCTAssertFalse(predicate.evaluate(with: channel(group: "expired", daysAgo: 14.1)), json)
        }
    }

    func test_groupedFilterPredicate_rfc3339Cutoff_matchesFromTheCutoff() throws {
        let predicate = try XCTUnwrap(groupedFilterPredicate(Data(#"{"query_timestamp":{"$gte":"2025-10-01T00:00:00Z"}}"#.utf8)))
        let cutoff = Date(timeIntervalSince1970: 1_759_276_800)

        XCTAssertTrue(predicate.evaluate(with: channel(group: "expired", queryTimestamp: cutoff)))
        XCTAssertFalse(predicate.evaluate(with: channel(group: "expired", queryTimestamp: cutoff - 1)))
    }

    func test_groupedFilterPredicate_groupConditions_compareNormalizedGroups() throws {
        let shortForm = try XCTUnwrap(groupedFilterPredicate(Data(#"{"group":" Ended "}"#.utf8)))

        XCTAssertTrue(shortForm.evaluate(with: channel(group: "ended", daysAgo: 0)))
        XCTAssertFalse(shortForm.evaluate(with: channel(group: "new", daysAgo: 0)))
    }

    func test_groupedFilterPredicate_unsupportedConditions_haveNoPredicate() throws {
        XCTAssertNil(try groupedFilterPredicate(Data(#"{"members":{"$in":["user"]}}"#.utf8)))
        XCTAssertNil(try groupedFilterPredicate(Data(#"{"query_timestamp":{"$gte":"yesterday"}}"#.utf8)))
        // One unsupported branch disables the whole filter instead of narrowing the `$or`.
        XCTAssertNil(try groupedFilterPredicate(Data(#"{"$or":[{"query_timestamp":{"$gte":"now-24h"}},{"group":"new"}]}"#.utf8)))
    }

    // MARK: - Helpers

    private func groupedFilterPredicate(_ data: Data) throws -> NSPredicate? {
        try Filter<GroupedChannelsFilterScope>.groupedFilter(fromJSONData: data)?.predicate
    }

    // Key-value coding stand-in for `ChannelDTO`, matching the key paths of the grouped filter keys.
    private func channel(group: String?, daysAgo: Double) -> NSDictionary {
        channel(group: group, queryTimestamp: Date().addingTimeInterval(-daysAgo * 86400))
    }

    private func channel(group: String?, queryTimestamp: Date) -> NSDictionary {
        var values: [String: Any] = [#keyPath(ChannelDTO.defaultSortingAt): queryTimestamp]
        values[#keyPath(ChannelDTO.group)] = group
        return values as NSDictionary
    }
}
