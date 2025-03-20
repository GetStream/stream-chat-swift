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
    }
    
    func test_customInitialization() {
        let filter = Filter<MessageReminderListFilterScope>.equal(.cid, to: ChannelId.unique)
        let sort = [Sorting<MessageReminderListSortingKey>(key: .createdAt, isAscending: false)]
        
        let query = MessageReminderListQuery(
            filter: filter,
            sort: sort,
            pageSize: 10
        )
        
        XCTAssertEqual(query.filter?.filterHash, filter.filterHash)
        XCTAssertEqual(query.pagination.pageSize, 10)
        XCTAssertEqual(query.sort.count, 1)
        XCTAssertEqual(query.sort[0].key, .createdAt)
        XCTAssertFalse(query.sort[0].isAscending)
    }
    
    func test_encode_withAllFields() throws {
        let cid: ChannelId = .init(type: .messaging, id: "123")
        let filter = Filter<MessageReminderListFilterScope>.equal(.cid, to: cid)
        let sort = [Sorting<MessageReminderListSortingKey>(key: .createdAt, isAscending: false)]
        
        let query = MessageReminderListQuery(
            filter: filter,
            sort: sort,
            pageSize: 10
        )
        
        let expectedData: [String: Any] = [
            "filter": ["channel_cid": ["$eq": cid.rawValue]],
            "sort": [["field": "created_at", "direction": -1]],
            "limit": 10
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
        let cid: ChannelId = .init(type: .messaging, id: "123")
        let filter = Filter<MessageReminderListFilterScope>.equal(.cid, to: cid)

        let query = MessageReminderListQuery(
            filter: filter,
            sort: [],
            pageSize: 10
        )
        
        let expectedData: [String: Any] = [
            "filter": ["channel_cid": ["$eq": cid.rawValue]],
            "limit": 10
        ]
        
        let expectedJSON = try JSONSerialization.data(withJSONObject: expectedData, options: [])
        let encodedJSON = try JSONEncoder.default.encode(query)
        AssertJSONEqual(expectedJSON, encodedJSON)
    }
    
    func test_filterKeys() {
        // Test the filter keys for proper values
        XCTAssertEqual(FilterKey<MessageReminderListFilterScope, ChannelId>.cid.rawValue, "channel_cid")
        XCTAssertEqual(FilterKey<MessageReminderListFilterScope, MessageId>.messageId.rawValue, "message_id")
        XCTAssertEqual(FilterKey<MessageReminderListFilterScope, Date>.remindAt.rawValue, "remind_at")
        XCTAssertEqual(FilterKey<MessageReminderListFilterScope, Date>.createdAt.rawValue, "created_at")
    }
    
    func test_sortingKeys() {
        // Test the sorting keys for proper values
        XCTAssertEqual(MessageReminderListSortingKey.remindAt.rawValue, "remind_at")
        XCTAssertEqual(MessageReminderListSortingKey.createdAt.rawValue, "created_at")
        XCTAssertEqual(MessageReminderListSortingKey.updatedAt.rawValue, "updated_at")
    }
}
