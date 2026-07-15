//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class UserGroupPayloads_Tests: XCTestCase {
    func test_userGroup_isDecodedCorrectly() throws {
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

        let payload = try JSONDecoder.stream.decode(UserGroup.self, from: json)

        XCTAssertEqual(payload.id, "backendsupport")
        XCTAssertEqual(payload.name, "Backend Support Team")
        XCTAssertEqual(payload.description, "On-call backend support engineers")
        XCTAssertEqual(payload.teamId, "engineering")
        XCTAssertEqual(payload.createdBy, "admin-user")
        XCTAssertEqual(payload.members.count, 1)
        XCTAssertEqual(payload.members.first?.groupId, "backendsupport")
        XCTAssertEqual(payload.members.first?.userId, "user1")
        XCTAssertEqual(payload.members.first?.isAdmin, true)
    }

    func test_userGroup_withMissingOptionalFields_isDecodedCorrectly() throws {
        let json = """
        {
            "id": "backendsupport",
            "name": "Backend Support Team",
            "created_at": "2020-07-16T15:39:03.010717Z",
            "updated_at": "2020-08-17T13:15:39.895109Z"
        }
        """.data(using: .utf8)!

        let payload = try JSONDecoder.stream.decode(UserGroup.self, from: json)

        XCTAssertEqual(payload.id, "backendsupport")
        XCTAssertNil(payload.description)
        XCTAssertNil(payload.teamId)
        XCTAssertNil(payload.createdBy)
        XCTAssertTrue(payload.members.isEmpty)
    }

    func test_userGroupMember_isDecodedCorrectly() throws {
        let json = """
        {
            "group_id": "backendsupport",
            "user_id": "user1",
            "is_admin": true,
            "created_at": "2020-07-16T15:39:03.010717Z"
        }
        """.data(using: .utf8)!

        let payload = try JSONDecoder.stream.decode(UserGroupMember.self, from: json)

        XCTAssertEqual(payload.groupId, "backendsupport")
        XCTAssertEqual(payload.userId, "user1")
        XCTAssertTrue(payload.isAdmin)
    }

    func test_listUserGroupsResponse_isDecodedCorrectly() throws {
        let json = """
        {
            "duration": "1.2ms",
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

        let payload = try JSONDecoder.stream.decode(ListUserGroupsResponse.self, from: json)

        XCTAssertEqual(payload.userGroups.count, 1)
        XCTAssertEqual(payload.userGroups.first?.id, "backendsupport")
    }

    func test_getUserGroupResponse_isDecodedCorrectly() throws {
        let json = """
        {
            "duration": "1.2ms",
            "user_group": {
                "id": "backendsupport",
                "name": "Backend Support Team",
                "created_at": "2020-07-16T15:39:03.010717Z",
                "updated_at": "2020-08-17T13:15:39.895109Z"
            }
        }
        """.data(using: .utf8)!

        let payload = try JSONDecoder.stream.decode(UserGroupResponse.self, from: json)

        XCTAssertEqual(payload.userGroup?.id, "backendsupport")
    }

    func test_createUserGroupRequest_encoding() throws {
        let request = CreateUserGroupRequest(
            description: "On-call backend support engineers",
            id: "backendsupport",
            memberIds: ["user1", "user2"],
            name: "Backend Support Team",
            teamId: "engineering"
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

    func test_createUserGroupRequest_encoding_withMinimalFields() throws {
        let request = CreateUserGroupRequest(name: "Backend Support Team")

        let serializedJSON = try JSONEncoder.stream.encode(request)
        let expected: [String: Any] = [
            "name": "Backend Support Team"
        ]
        let expectedJSON = try JSONSerialization.data(withJSONObject: expected, options: [])
        AssertJSONEqual(serializedJSON, expectedJSON)
    }

    func test_updateUserGroupRequest_encoding() throws {
        let request = UpdateUserGroupRequest(
            description: "Updated description",
            name: "Updated Name",
            teamId: "engineering"
        )

        let serializedJSON = try JSONEncoder.stream.encode(request)
        let expected: [String: Any] = [
            "name": "Updated Name",
            "description": "Updated description",
            "team_id": "engineering"
        ]
        let expectedJSON = try JSONSerialization.data(withJSONObject: expected, options: [])
        AssertJSONEqual(serializedJSON, expectedJSON)
    }

    func test_addUserGroupMembersRequest_encoding() throws {
        let request = AddUserGroupMembersRequest(
            asAdmin: true,
            memberIds: ["user1", "user2"],
            teamId: "engineering"
        )

        let serializedJSON = try JSONEncoder.stream.encode(request)
        let expected: [String: Any] = [
            "member_ids": ["user1", "user2"],
            "as_admin": true,
            "team_id": "engineering"
        ]
        let expectedJSON = try JSONSerialization.data(withJSONObject: expected, options: [])
        AssertJSONEqual(serializedJSON, expectedJSON)
    }

    func test_removeUserGroupMembersRequest_encoding() throws {
        let request = RemoveUserGroupMembersRequest(memberIds: ["user1"])

        let serializedJSON = try JSONEncoder.stream.encode(request)
        let expected: [String: Any] = [
            "member_ids": ["user1"]
        ]
        let expectedJSON = try JSONSerialization.data(withJSONObject: expected, options: [])
        AssertJSONEqual(serializedJSON, expectedJSON)
    }
}
