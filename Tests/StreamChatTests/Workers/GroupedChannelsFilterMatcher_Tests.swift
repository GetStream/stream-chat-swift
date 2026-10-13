//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class GroupedChannelsFilterMatcher_Tests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_760_000_000)

    // MARK: - query_timestamp

    func test_queryTimestamp_relativeCutoff_matchesAtAndAfterTheCutoff() throws {
        let filter = try rawJSON(#"{"query_timestamp":{"$gte":"now-14d"}}"#)

        XCTAssertTrue(matcher(daysAgo: 13).matches(filter))
        XCTAssertTrue(matcher(daysAgo: 14).matches(filter))
        XCTAssertFalse(matcher(daysAgo: 15).matches(filter))
    }

    func test_queryTimestamp_shortRelativeCutoff_matches() throws {
        let filter = try rawJSON(#"{"query_timestamp":{"$gte":"14d"}}"#)

        XCTAssertTrue(matcher(daysAgo: 13).matches(filter))
        XCTAssertFalse(matcher(daysAgo: 15).matches(filter))
    }

    func test_queryTimestamp_rfc3339Cutoff_matches() throws {
        let filter = try rawJSON(#"{"query_timestamp":{"$gte":"2025-10-01T00:00:00Z"}}"#)
        let fractionalFilter = try rawJSON(#"{"query_timestamp":{"$gte":"2025-10-01T00:00:00.000Z"}}"#)
        let cutoff = Date(timeIntervalSince1970: 1_759_276_800)

        XCTAssertTrue(GroupedChannelsFilterMatcher(group: nil, queryTimestamp: cutoff, now: now).matches(filter))
        XCTAssertFalse(GroupedChannelsFilterMatcher(group: nil, queryTimestamp: cutoff - 1, now: now).matches(filter))
        XCTAssertTrue(GroupedChannelsFilterMatcher(group: nil, queryTimestamp: cutoff, now: now).matches(fractionalFilter))
        XCTAssertFalse(GroupedChannelsFilterMatcher(group: nil, queryTimestamp: cutoff - 1, now: now).matches(fractionalFilter))
    }

    // MARK: - group

    func test_group_equality_matchesNormalizedGroup() throws {
        let shortFilter = try rawJSON(#"{"group":"ended"}"#)
        let eqFilter = try rawJSON(#"{"group":{"$eq":"ended"}}"#)

        XCTAssertTrue(matcher(group: " Ended ").matches(shortFilter))
        XCTAssertTrue(matcher(group: "ended").matches(eqFilter))
        XCTAssertFalse(matcher(group: "new").matches(eqFilter))
        XCTAssertFalse(matcher(group: nil).matches(eqFilter))
    }

    func test_group_in_matchesListedGroups() throws {
        let filter = try rawJSON(#"{"group":{"$in":["campaign","new"]}}"#)

        XCTAssertTrue(matcher(group: "new").matches(filter))
        XCTAssertFalse(matcher(group: "bee").matches(filter))
    }

    func test_group_notEqual_matchesOtherGroups() throws {
        let filter = try rawJSON(#"{"group":{"$ne":"bee"}}"#)

        XCTAssertTrue(matcher(group: "new").matches(filter))
        XCTAssertFalse(matcher(group: "bee").matches(filter))
    }

    // MARK: - Combinations

    func test_orOfAndBranches_matchesPerBranchCutoffs() throws {
        let filter = try rawJSON(#"""
        {"$or":[
            {"$and":[{"group":{"$eq":"ended"}},{"query_timestamp":{"$gte":"now-7d"}}]},
            {"group":{"$in":["campaign","new"]}},
            {"group":"expired","query_timestamp":{"$gte":"now-14d"}}
        ]}
        """#)

        XCTAssertTrue(matcher(group: "ended", daysAgo: 6).matches(filter))
        XCTAssertFalse(matcher(group: "ended", daysAgo: 8).matches(filter))
        XCTAssertTrue(matcher(group: "new", daysAgo: 400).matches(filter))
        XCTAssertTrue(matcher(group: "expired", daysAgo: 13).matches(filter))
        XCTAssertFalse(matcher(group: "expired", daysAgo: 15).matches(filter))
        XCTAssertFalse(matcher(group: "bee", daysAgo: 0).matches(filter))
    }

    func test_unsupportedConditions_match() throws {
        XCTAssertTrue(matcher(group: "new").matches(try rawJSON(#"{"members":{"$in":["user"]}}"#)))
        XCTAssertTrue(matcher(daysAgo: 400).matches(try rawJSON(#"{"query_timestamp":{"$gte":"yesterday"}}"#)))
        XCTAssertTrue(matcher(daysAgo: 400).matches(try rawJSON(#"{"query_timestamp":{"$lt":"now-1d"}}"#)))
    }

    // MARK: - Helpers

    private func matcher(group: String? = "expired", daysAgo: Int = 0) -> GroupedChannelsFilterMatcher {
        GroupedChannelsFilterMatcher(
            group: group,
            queryTimestamp: now.addingTimeInterval(-TimeInterval(daysAgo) * 86400),
            now: now
        )
    }

    private func rawJSON(_ json: String) throws -> RawJSON {
        try JSONDecoder.stream.decode(RawJSON.self, from: Data(json.utf8))
    }
}
