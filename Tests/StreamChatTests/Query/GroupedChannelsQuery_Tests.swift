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

    func test_group_notEqual_encodesExclusion() throws {
        let filter = Filter<GroupedChannelsFilterScope>.notEqual(.group, to: "bee")

        AssertJSONEqual(try JSONEncoder.stream.encode(filter), Data(#"{"group":{"$ne":"bee"}}"#.utf8))
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
}
