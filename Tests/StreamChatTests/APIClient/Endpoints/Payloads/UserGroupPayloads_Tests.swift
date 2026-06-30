//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class UserGroupPayloads_Tests: XCTestCase {
    // MARK: - Decoding

    func test_userGroupResponse_isDecodedCorrectly() throws {
        let json = """
        {
            "id": "backendsupport",
            "name": "Backend Support Team",
            "description": "On-call backend support engineers",
            "team_id": "engineering",
            "members": [
                {
                    "app_pk": 1,
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

        let payload = try JSONDecoder.stream.decode(UserGroupResponse.self, from: json)

        XCTAssertEqual(payload.id, "backendsupport")
        XCTAssertEqual(payload.name, "Backend Support Team")
        XCTAssertEqual(payload.description, "On-call backend support engineers")
        XCTAssertEqual(payload.teamId, "engineering")
        XCTAssertEqual(payload.members?.count, 1)
        XCTAssertEqual(payload.members?.first?.userId, "user1")
        XCTAssertTrue(payload.members?.first?.isAdmin == true)
        XCTAssertEqual(payload.createdBy, "admin-user")
    }

    func test_userGroupResponse_withMissingOptionalFields_isDecodedCorrectly() throws {
        let json = """
        {
            "id": "backendsupport",
            "name": "Backend Support Team",
            "created_at": "2020-07-16T15:39:03.010717Z",
            "updated_at": "2020-08-17T13:15:39.895109Z"
        }
        """.data(using: .utf8)!

        let payload = try JSONDecoder.stream.decode(UserGroupResponse.self, from: json)

        XCTAssertEqual(payload.id, "backendsupport")
        XCTAssertNil(payload.description)
        XCTAssertNil(payload.teamId)
        XCTAssertNil(payload.createdBy)
        XCTAssertNil(payload.members)
        // A response without members maps to a model with no members.
        XCTAssertTrue(payload.asModel().members.isEmpty)
    }

    func test_listUserGroupsResponse_isDecodedCorrectly() throws {
        let json = """
        {
            "duration": "1ms",
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

    // MARK: - asModel

    func test_userGroupMemberPayload_asModel() {
        let createdAt = Date.unique
        let payload = UserGroupMemberPayload.dummy(
            createdAt: createdAt,
            groupId: "backendsupport",
            isAdmin: true,
            userId: "user1"
        )

        let model = payload.asModel()

        XCTAssertEqual(model.groupId, "backendsupport")
        XCTAssertEqual(model.userId, "user1")
        XCTAssertTrue(model.isAdmin)
        XCTAssertEqual(model.createdAt, createdAt)
    }

    func test_userGroupResponse_asModel_mapsAllFieldsIncludingMembers() {
        let createdAt = Date.unique
        let updatedAt = Date.unique
        let memberCreatedAt = Date.unique
        let payload = UserGroupResponse.dummy(
            createdAt: createdAt,
            createdBy: "admin-user",
            description: "On-call backend support engineers",
            id: "backendsupport",
            members: [
                .dummy(createdAt: memberCreatedAt, groupId: "backendsupport", isAdmin: true, userId: "user1")
            ],
            name: "Backend Support Team",
            teamId: "engineering",
            updatedAt: updatedAt
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

    // MARK: - Request encoding

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
        let request = RemoveUserGroupMembersRequest(
            memberIds: ["user1", "user2"],
            teamId: "engineering"
        )

        let serializedJSON = try JSONEncoder.stream.encode(request)
        let expected: [String: Any] = [
            "member_ids": ["user1", "user2"],
            "team_id": "engineering"
        ]
        let expectedJSON = try JSONSerialization.data(withJSONObject: expected, options: [])
        AssertJSONEqual(serializedJSON, expectedJSON)
    }
}
