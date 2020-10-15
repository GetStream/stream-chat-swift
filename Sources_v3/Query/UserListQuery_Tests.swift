//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient
import XCTest

final class UserListFilterScope_Tests: XCTestCase {
    typealias Key<T: FilterValue> = FilterKey<UserListFilterScope<NoExtraData>, T>
    
    func test_filterKeys_matchChannelCodingKeys() {
        XCTAssertEqual(Key<UserId>.id.rawValue, UserPayloadsCodingKeys.id.rawValue)
        XCTAssertEqual(Key<UserRole>.role.rawValue, UserPayloadsCodingKeys.role.rawValue)
        XCTAssertEqual(Key<Bool>.isOnline.rawValue, UserPayloadsCodingKeys.isOnline.rawValue)
        XCTAssertEqual(Key<Bool>.isBanned.rawValue, UserPayloadsCodingKeys.isBanned.rawValue)
        XCTAssertEqual(Key<Date>.createdAt.rawValue, UserPayloadsCodingKeys.createdAt.rawValue)
        XCTAssertEqual(Key<Date>.updatedAt.rawValue, UserPayloadsCodingKeys.updatedAt.rawValue)
        XCTAssertEqual(Key<Date>.lastActiveAt.rawValue, UserPayloadsCodingKeys.lastActiveAt.rawValue)
        XCTAssertEqual(Key<Bool>.isInvisible.rawValue, UserPayloadsCodingKeys.isInvisible.rawValue)
        XCTAssertEqual(Key<Int>.unreadChannelsCount.rawValue, UserPayloadsCodingKeys.unreadChannelsCount.rawValue)
        XCTAssertEqual(Key<Int>.unreadMessagesCount.rawValue, UserPayloadsCodingKeys.unreadMessagesCount.rawValue)
        XCTAssertEqual(Key<Bool>.isAnonymous.rawValue, UserPayloadsCodingKeys.isAnonymous.rawValue)
    }
    
    func test_filterKeys_matchNameAndImageExtraDataCodingKeys() {
        XCTAssertEqual(
            FilterKey<UserListFilterScope<NameAndImageExtraData>, String>.name.rawValue,
            NameAndImageExtraData.CodingKeys.name.rawValue
        )
        XCTAssertEqual(
            FilterKey<UserListFilterScope<NameAndImageExtraData>, URL>.imageURL.rawValue,
            NameAndImageExtraData.CodingKeys.imageURL.rawValue
        )
    }
}

class UserListQuery_Tests: XCTestCase {
    // Test UserListQuery encoded correctly
    func test_UserListQuery_encodedCorrectly() throws {
        let filter: Filter<UserListFilterScope<NameAndImageExtraData>> = .equal(.id, to: "luke")
        let sort: [Sorting<UserListSortingKey>] = [.init(key: .lastActivityAt)]

        // Create UserListQuery
        let query = UserListQuery(
            filter: filter,
            sort: sort,
            pageSize: 23
        )

        let expectedData: [String: Any] = [
            "presence": true,
            "limit": 23,
            "filter_conditions": ["id": ["$eq": "luke"]],
            "sort": [["field": "last_active", "direction": -1]]
        ]

        let expectedJSON = try JSONSerialization.data(withJSONObject: expectedData, options: [])
        let encodedJSON = try JSONEncoder.default.encode(query)
        
        // Assert UserListQuery encoded correctly
        AssertJSONEqual(expectedJSON, encodedJSON)
    }
    
    func test_singleUserQuery_worksCorrectly() throws {
        let userId: UserId = .unique
        
        let actual = UserListQuery<NoExtraData>.user(withID: userId)
        let actualJSON = try JSONEncoder.default.encode(actual)

        let expected = UserListQuery<NoExtraData>(filter: .equal("id", to: userId))
        let expectedJSON = try JSONEncoder.default.encode(expected)
    
        // Assert queries match
        AssertJSONEqual(actualJSON, expectedJSON)
    }
}
