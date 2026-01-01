//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ThreadListQuery_Tests: XCTestCase {
    func test_threadListQuery_encodedCorrectly() throws {
        let cid = ChannelId.unique
        let filter = Filter<ThreadListFilterScope>.equal(.cid, to: cid.rawValue)
        let sort = Sorting<ThreadListSortingKey>.init(key: .createdAt)
        let watch = true
        let limit = 25
        let replyLimit = 5
        let participantLimit = 15
        let next = "next_token"

        // Create ThreadListQuery
        let query = ThreadListQuery(
            watch: watch,
            filter: filter,
            sort: [sort],
            limit: limit,
            replyLimit: replyLimit,
            participantLimit: participantLimit,
            next: next
        )

        let expectedData: [String: Any] = [
            "limit": limit,
            "reply_limit": replyLimit,
            "participant_limit": participantLimit,
            "sort": [["field": "created_at", "direction": -1] as [String: Any]],
            "filter": ["channel_cid": ["$eq": cid.rawValue]],
            "watch": watch,
            "next": next
        ]

        let expectedJSON = try JSONSerialization.data(withJSONObject: expectedData, options: [])
        let encodedJSON = try JSONEncoder.default.encode(query)

        // Assert ThreadListQuery encoded correctly
        AssertJSONEqual(expectedJSON, encodedJSON)
    }

    func test_threadListQuery_defaultValues() {
        let query = ThreadListQuery(watch: true)

        XCTAssertNil(query.filter)
        XCTAssertEqual(query.sort.count, 3)
        XCTAssertEqual(query.sort[0].key, .hasUnread)
        XCTAssertEqual(query.sort[1].key, .lastMessageAt)
        XCTAssertEqual(query.sort[2].key, .parentMessageId)
        XCTAssertTrue(query.watch)
        XCTAssertEqual(query.limit, 20)
        XCTAssertEqual(query.replyLimit, 3)
        XCTAssertEqual(query.participantLimit, 10)
        XCTAssertNil(query.next)
    }

    func test_threadListQuery_withFilter() throws {
        let userId = UserId.unique
        let filter = Filter<ThreadListFilterScope>.equal(.createdByUserId, to: userId)
        let query = ThreadListQuery(watch: false, filter: filter)

        let encodedJSON = try JSONEncoder.default.encode(query)
        let decoded = try JSONSerialization.jsonObject(with: encodedJSON) as? [String: Any]

        let filterData = decoded?["filter"] as? [String: Any]
        let createdByFilter = filterData?["created_by_user_id"] as? [String: Any]
        let eqValue = createdByFilter?["$eq"] as? String

        XCTAssertEqual(eqValue, userId)
    }

    func test_threadListQuery_withMultipleFilters() throws {
        let cid = ChannelId.unique
        let startDate = Date()
        let filter = Filter<ThreadListFilterScope>.and([
            .equal(.cid, to: cid.rawValue),
            .greater(.createdAt, than: startDate)
        ])
        let query = ThreadListQuery(watch: false, filter: filter)

        let encodedJSON = try JSONEncoder.default.encode(query)
        let decoded = try JSONSerialization.jsonObject(with: encodedJSON) as? [String: Any]

        let filterData = decoded?["filter"] as? [String: Any]
        XCTAssertNotNil(filterData?["$and"])
    }

    func test_threadListQuery_withCustomSorting() throws {
        let sort = [
            Sorting<ThreadListSortingKey>(key: .replyCount, isAscending: true),
            Sorting<ThreadListSortingKey>(key: .participantCount, isAscending: false)
        ]
        let query = ThreadListQuery(watch: true, sort: sort)

        let encodedJSON = try JSONEncoder.default.encode(query)
        let decoded = try JSONSerialization.jsonObject(with: encodedJSON) as? [String: Any]

        let sortData = decoded?["sort"] as? [[String: Any]]
        XCTAssertEqual(sortData?.count, 2)
        
        XCTAssertEqual(sortData?[0]["field"] as? String, "reply_count")
        XCTAssertEqual(sortData?[0]["direction"] as? Int, 1)
        
        XCTAssertEqual(sortData?[1]["field"] as? String, "participant_count")
        XCTAssertEqual(sortData?[1]["direction"] as? Int, -1)
    }

    func test_threadListQuery_withoutFilter_doesNotEncodeFilter() throws {
        let query = ThreadListQuery(watch: true, filter: nil)

        let encodedJSON = try JSONEncoder.default.encode(query)
        let decoded = try JSONSerialization.jsonObject(with: encodedJSON) as? [String: Any]

        XCTAssertNil(decoded?["filter"])
    }

    func test_threadListQuery_withoutNext_doesNotEncodeNext() throws {
        let query = ThreadListQuery(watch: true, next: nil)

        let encodedJSON = try JSONEncoder.default.encode(query)
        let decoded = try JSONSerialization.jsonObject(with: encodedJSON) as? [String: Any]

        XCTAssertNil(decoded?["next"])
    }
}
