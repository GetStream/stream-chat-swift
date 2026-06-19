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

    func test_userGroupMemberPayload_isDecodedCorrectly() throws {
        let json = """
        {
            "group_id": "backendsupport",
            "user_id": "user1",
            "is_admin": true,
            "created_at": "2020-07-16T15:39:03.010717Z"
        }
        """.data(using: .utf8)!

        let payload = try JSONDecoder.stream.decode(UserGroupMemberPayload.self, from: json)

        XCTAssertEqual(payload.groupId, "backendsupport")
        XCTAssertEqual(payload.userId, "user1")
        XCTAssertTrue(payload.isAdmin)
    }

    func test_userGroupMemberPayload_asModel() {
        let createdAt = Date.unique
        let payload = UserGroupMemberPayload(
            groupId: "backendsupport",
            userId: "user1",
            isAdmin: true,
            createdAt: createdAt
        )

        let model = payload.asModel()

        XCTAssertEqual(model.groupId, "backendsupport")
        XCTAssertEqual(model.userId, "user1")
        XCTAssertTrue(model.isAdmin)
        XCTAssertEqual(model.createdAt, createdAt)
    }

    func test_userGroupPayload_withMissingOptionalFields_isDecodedCorrectly() throws {
        let json = """
        {
            "id": "backendsupport",
            "name": "Backend Support Team",
            "created_at": "2020-07-16T15:39:03.010717Z",
            "updated_at": "2020-08-17T13:15:39.895109Z"
        }
        """.data(using: .utf8)!

        let payload = try JSONDecoder.stream.decode(UserGroupPayload.self, from: json)

        XCTAssertEqual(payload.id, "backendsupport")
        XCTAssertNil(payload.description)
        XCTAssertNil(payload.teamId)
        XCTAssertNil(payload.createdBy)
        XCTAssertTrue(payload.members.isEmpty)
    }

    func test_userGroupPayload_asModel_mapsAllFieldsIncludingMembers() {
        let createdAt = Date.unique
        let updatedAt = Date.unique
        let memberCreatedAt = Date.unique
        let payload = UserGroupPayload(
            id: "backendsupport",
            name: "Backend Support Team",
            description: "On-call backend support engineers",
            teamId: "engineering",
            members: [
                UserGroupMemberPayload(
                    groupId: "backendsupport",
                    userId: "user1",
                    isAdmin: true,
                    createdAt: memberCreatedAt
                )
            ],
            createdAt: createdAt,
            updatedAt: updatedAt,
            createdBy: "admin-user"
        )

        let model = payload.asModel()

        XCTAssertEqual(model.id, "backendsupport")
        XCTAssertEqual(model.name, "Backend Support Team")
        XCTAssertEqual(model.description, "On-call backend support engineers")
        XCTAssertEqual(model.teamId, "engineering")
        XCTAssertEqual(model.createdAt, createdAt)
        XCTAssertEqual(model.updatedAt, updatedAt)
        XCTAssertEqual(model.createdBy, "admin-user")
        XCTAssertEqual(model.members.count, 1)
        XCTAssertEqual(model.members.first?.userId, "user1")
        XCTAssertEqual(model.members.first?.isAdmin, true)
        XCTAssertEqual(model.members.first?.createdAt, memberCreatedAt)
    }

    func test_userGroupPayloadResponse_isDecodedCorrectly() throws {
        let json = """
        {
            "user_group": {
                "id": "backendsupport",
                "name": "Backend Support Team",
                "created_at": "2020-07-16T15:39:03.010717Z",
                "updated_at": "2020-08-17T13:15:39.895109Z"
            }
        }
        """.data(using: .utf8)!

        let payload = try JSONDecoder.stream.decode(UserGroupPayloadResponse.self, from: json)

        XCTAssertEqual(payload.userGroup.id, "backendsupport")
    }

    func test_createUserGroupRequestBody_encoding_withMinimalFields() throws {
        let request = CreateUserGroupRequestBody(name: "Backend Support Team")

        let serializedJSON = try JSONEncoder.stream.encode(request)
        let expected: [String: Any] = [
            "name": "Backend Support Team",
            "member_ids": []
        ]
        let expectedJSON = try JSONSerialization.data(withJSONObject: expected, options: [])
        AssertJSONEqual(serializedJSON, expectedJSON)
    }

    func test_updateUserGroupRequestBody_encoding() throws {
        let request = UpdateUserGroupRequestBody(
            name: "Updated Name",
            description: "Updated description",
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

    func test_userGroupMembersRequestBody_encoding() throws {
        let request = UserGroupMembersRequestBody(
            memberIds: ["user1", "user2"],
            asAdmin: true,
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

    func test_userGroupMembersRequestBody_encoding_withMinimalFields() throws {
        let request = UserGroupMembersRequestBody(memberIds: ["user1"])

        let serializedJSON = try JSONEncoder.stream.encode(request)
        let expected: [String: Any] = [
            "member_ids": ["user1"]
        ]
        let expectedJSON = try JSONSerialization.data(withJSONObject: expected, options: [])
        AssertJSONEqual(serializedJSON, expectedJSON)
    }
}
