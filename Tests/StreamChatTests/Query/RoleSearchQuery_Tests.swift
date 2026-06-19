//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class RoleSearchQuery_Tests: XCTestCase {
    func test_init_setsAllProperties() {
        let query = RoleSearchQuery(
            query: "adm",
            limit: 10,
            includeGlobalRoles: true,
            nameGreaterThan: "admin",
            roleType: .user
        )

        XCTAssertEqual(query.query, "adm")
        XCTAssertEqual(query.limit, 10)
        XCTAssertEqual(query.includeGlobalRoles, true)
        XCTAssertEqual(query.nameGreaterThan, "admin")
        XCTAssertEqual(query.roleType, .user)
    }

    func test_init_usesDefaultValues() {
        let query = RoleSearchQuery(query: "adm")

        XCTAssertEqual(query.query, "adm")
        XCTAssertNil(query.limit)
        XCTAssertNil(query.includeGlobalRoles)
        XCTAssertNil(query.nameGreaterThan)
        XCTAssertNil(query.roleType)
    }

    func test_encode_whenAllFieldsAreSet_thenEncodesCorrectly() throws {
        let query = RoleSearchQuery(
            query: "adm",
            limit: 10,
            includeGlobalRoles: true,
            nameGreaterThan: "admin",
            roleType: .channel
        )

        let encodedJSON = try JSONEncoder.stream.encode(query)
        let expected: [String: Any] = [
            "query": "adm",
            "limit": 10,
            "include_global_roles": true,
            "name_gt": "admin",
            "role_type": "channel"
        ]
        let expectedJSON = try JSONSerialization.data(withJSONObject: expected, options: [])

        AssertJSONEqual(encodedJSON, expectedJSON)
    }

    func test_encode_whenOptionalFieldsAreNil_thenTheyAreOmitted() throws {
        let query = RoleSearchQuery(query: "adm")

        let encodedJSON = try JSONEncoder.stream.encode(query)
        let decoded = try JSONSerialization.jsonObject(with: encodedJSON) as? [String: Any]

        XCTAssertEqual(decoded?["query"] as? String, "adm")
        XCTAssertNil(decoded?["limit"])
        XCTAssertNil(decoded?["include_global_roles"])
        XCTAssertNil(decoded?["name_gt"])
        XCTAssertNil(decoded?["role_type"])
    }

    func test_encode_encodesRoleTypeRawValue() throws {
        let query = RoleSearchQuery(query: "adm", roleType: .user)

        let encodedJSON = try JSONEncoder.stream.encode(query)
        let decoded = try JSONSerialization.jsonObject(with: encodedJSON) as? [String: Any]

        XCTAssertEqual(decoded?["role_type"] as? String, "user")
    }

    func test_roleType_rawValues() {
        XCTAssertEqual(RoleType.user.rawValue, "user")
        XCTAssertEqual(RoleType.channel.rawValue, "channel")
    }
}
