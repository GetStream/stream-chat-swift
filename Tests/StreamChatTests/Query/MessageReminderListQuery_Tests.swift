//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class MessageReminderListQuery_Tests: XCTestCase {
    func test_defaultInitialization() {
        let query = MessageReminderListQuery()
        
        XCTAssertNil(query.filter)
        XCTAssertEqual(query.pagination.pageSize, 25)
        XCTAssertEqual(query.pagination.offset, 0)
        XCTAssertEqual(query.sort.count, 1)
        XCTAssertEqual(query.sort[0].key, .remindAt)
        XCTAssertTrue(query.sort[0].isAscending)
        XCTAssertNil(query.next)
        XCTAssertNil(query.prev)
    }
    
    func test_customInitialization() {
        let filter = Filter<MessageReminderListFilterScope>.equal(.userId, to: "user-id")
        let sort = [Sorting<MessageReminderListSortingKey>(key: .createdAt, isAscending: false)]
        let next = "next-token"
        let prev = "prev-token"
        
        let query = MessageReminderListQuery(
            filter: filter,
            sort: sort,
            pageSize: 10,
            next: next,
            prev: prev
        )
        
        XCTAssertEqual(query.filter?.filterHash, filter.filterHash)
        XCTAssertEqual(query.pagination.pageSize, 10)
        XCTAssertEqual(query.sort.count, 1)
        XCTAssertEqual(query.sort[0].key, .createdAt)
        XCTAssertFalse(query.sort[0].isAscending)
        XCTAssertEqual(query.next, next)
        XCTAssertEqual(query.prev, prev)
    }
    
    func test_encode_withAllFields() throws {
        let filter = Filter<MessageReminderListFilterScope>.equal(.userId, to: "user-id")
        let sort = [Sorting<MessageReminderListSortingKey>(key: .createdAt, isAscending: false)]
        let next = "next-token"
        let prev = "prev-token"
        
        let query = MessageReminderListQuery(
            filter: filter,
            sort: sort,
            pageSize: 10,
            next: next,
            prev: prev
        )
        
        let expectedData: [String: Any] = [
            "filter": ["user_id": ["$eq": "user-id"]],
            "sort": [["field": "created_at", "direction": -1]],
            "limit": 10,
            "next": next,
            "prev": prev
        ]
        
        let expectedJSON = try JSONSerialization.data(withJSONObject: expectedData, options: [])
        let encodedJSON = try JSONEncoder.default.encode(query)
        AssertJSONEqual(expectedJSON, encodedJSON)
    }
    
    func test_encode_withoutFilter() throws {
        let sort = [Sorting<MessageReminderListSortingKey>(key: .createdAt, isAscending: false)]
        
        let query = MessageReminderListQuery(
            filter: nil,
            sort: sort,
            pageSize: 10
        )
        
        let expectedData: [String: Any] = [
            "sort": [["field": "created_at", "direction": -1]],
            "limit": 10
        ]
        
        let expectedJSON = try JSONSerialization.data(withJSONObject: expectedData, options: [])
        let encodedJSON = try JSONEncoder.default.encode(query)
        AssertJSONEqual(expectedJSON, encodedJSON)
    }
    
    func test_encode_withoutSort() throws {
        let filter = Filter<MessageReminderListFilterScope>.equal(.userId, to: "user-id")
        
        let query = MessageReminderListQuery(
            filter: filter,
            sort: [],
            pageSize: 10
        )
        
        let expectedData: [String: Any] = [
            "filter": ["user_id": ["$eq": "user-id"]],
            "limit": 10
        ]
        
        let expectedJSON = try JSONSerialization.data(withJSONObject: expectedData, options: [])
        let encodedJSON = try JSONEncoder.default.encode(query)
        AssertJSONEqual(expectedJSON, encodedJSON)
    }
    
    func test_filterKeys() {
        // Test the filter keys for proper values
        XCTAssertEqual(FilterKey<MessageReminderListFilterScope, ChannelId>.channelCid.rawValue, "channel_cid")
        XCTAssertEqual(FilterKey<MessageReminderListFilterScope, MessageId>.messageId.rawValue, "message_id")
        XCTAssertEqual(FilterKey<MessageReminderListFilterScope, Date>.remindAt.rawValue, "remind_at")
        XCTAssertEqual(FilterKey<MessageReminderListFilterScope, Date>.createdAt.rawValue, "created_at")
        XCTAssertEqual(FilterKey<MessageReminderListFilterScope, UserId>.userId.rawValue, "user_id")
    }
    
    func test_sortingKeys() {
        // Test the sorting keys for proper values
        XCTAssertEqual(MessageReminderListSortingKey.remindAt.rawValue, "remind_at")
        XCTAssertEqual(MessageReminderListSortingKey.createdAt.rawValue, "created_at")
        XCTAssertEqual(MessageReminderListSortingKey.updatedAt.rawValue, "updated_at")
    }
}
