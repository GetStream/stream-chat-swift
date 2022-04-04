//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class PinnedMessagesQuery_Tests: XCTestCase {
    func test_queryWithPagination_isEncodedCorrectly() throws {
        // Create page size.
        let pageSize: Int = 10
        
        // Create pagination
        let messageId: MessageId = .unique
        let pagination: PinnedMessagesPagination = .aroundMessage(messageId)
        
        // Create query.
        let query = PinnedMessagesQuery(
            pageSize: pageSize,
            pagination: pagination
        )
        
        // Encode query.
        let json = try JSONEncoder.default.encode(query)
        
        // Assert encoding is correct.
        AssertJSONEqual(json, [
            "limit": pageSize,
            "id_around": messageId
        ])
    }
    
    func test_queryWithoutPagination_isEncodedCorrectly() throws {
        // Create page size.
        let pageSize: Int = 10
        
        // Create query.
        let query = PinnedMessagesQuery(
            pageSize: pageSize,
            pagination: nil
        )
        
        // Encode query.
        let json = try JSONEncoder.default.encode(query)
        
        // Assert encoding is correct.
        AssertJSONEqual(json, ["limit": pageSize])
    }
    
    func test_queryWithSort_isEncodedCorrectly() throws {
        // Create page size.
        let pageSize: Int = 10
        
        // Create sorting options
        let sorting: [Sorting<PinnedMessagesSortingKey>] = [
            .init(key: .pinnedAt, isAscending: true),
            .init(key: .init(rawValue: "custom"), isAscending: false)
        ]
        
        // Create query with sort options.
        let query = PinnedMessagesQuery(
            pageSize: pageSize,
            sorting: sorting
        )
        
        // Encode query.
        let json = try JSONEncoder.default.encode(query)
        
        // Assert encoding is correct.
        AssertJSONEqual(json, [
            "limit": pageSize,
            "sort": [
                [
                    "field": "pinned_at",
                    "direction": 1
                ],
                [
                    "field": "custom",
                    "direction": -1
                ]
            ] as NSArray
        ])
    }
    
    func test_queryWithoutSorting_isEncodedCorrectly() throws {
        // Create page size.
        let pageSize: Int = 10
        
        // Create query with empty sort options.
        let query = PinnedMessagesQuery(
            pageSize: pageSize,
            sorting: []
        )
        
        // Encode query.
        let json = try JSONEncoder.default.encode(query)
        
        // Assert encoding is correct.
        AssertJSONEqual(json, ["limit": pageSize])
    }
}
