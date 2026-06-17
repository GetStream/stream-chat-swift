//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class UserGroupPayloads_Tests: XCTestCase {
    func test_userGroupPayload_isDecodedCorrectly() throws {
        let json = """
        {
            "id": "backendsupport",
            "name": "Backend Support Team",
            "description": "On-call backend support engineers",
            "team_id": "engineering",
            "members": [
                {
                    "group_id": "backendsupport",
                    "user_id": "user1",
                    "is_admin": true,
                    "created_at": "2020-07-16T15:39:03.010717Z"
                }
            ],
            "created_at": "2020-07-16T15:39:03.010717Z",
            "updated_at": "2020-08-17T13:15:39.895109Z",
            "created_by": "admin-user"
        }
        """.data(using: .utf8)!

        let payload = try JSONDecoder.stream.decode(UserGroupPayload.self, from: json)
        let model = payload.asModel()

        XCTAssertEqual(payload.id, "backendsupport")
        XCTAssertEqual(payload.name, "Backend Support Team")
        XCTAssertEqual(payload.description, "On-call backend support engineers")
        XCTAssertEqual(payload.teamId, "engineering")
        XCTAssertEqual(payload.members.count, 1)
        XCTAssertEqual(payload.members.first?.userId, "user1")
        XCTAssertTrue(payload.members.first?.isAdmin == true)
        XCTAssertEqual(payload.createdBy, "admin-user")
        XCTAssertEqual(model.members.first?.groupId, "backendsupport")
    }

    func test_userGroupListPayload_isDecodedCorrectly() throws {
        let json = """
        {
            "user_groups": [
                {
                    "id": "backendsupport",
                    "name": "Backend Support Team",
                    "created_at": "2020-07-16T15:39:03.010717Z",
                    "updated_at": "2020-08-17T13:15:39.895109Z"
                }
            ]
        }
        """.data(using: .utf8)!

        let payload = try JSONDecoder.stream.decode(UserGroupListPayload.self, from: json)

        XCTAssertEqual(payload.userGroups.count, 1)
        XCTAssertEqual(payload.userGroups.first?.id, "backendsupport")
    }

    func test_createUserGroupRequestBody_encoding() throws {
        let request = CreateUserGroupRequestBody(
            id: "backendsupport",
            name: "Backend Support Team",
            description: "On-call backend support engineers",
            teamId: "engineering",
            memberIds: ["user1", "user2"]
        )

        let serializedJSON = try JSONEncoder.stream.encode(request)
        let expected: [String: Any] = [
            "id": "backendsupport",
            "name": "Backend Support Team",
            "description": "On-call backend support engineers",
            "team_id": "engineering",
            "member_ids": ["user1", "user2"]
        ]
        let expectedJSON = try JSONSerialization.data(withJSONObject: expected, options: [])
        AssertJSONEqual(serializedJSON, expectedJSON)
    }
}
