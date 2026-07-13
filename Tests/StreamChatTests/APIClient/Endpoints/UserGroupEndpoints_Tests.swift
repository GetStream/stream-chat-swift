//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class UserGroupEndpoints_Tests: XCTestCase {
    func test_listUserGroups_buildsCorrectly() {
        let expectedEndpoint = Endpoint<ListUserGroupsResponse>(
            path: .listUserGroups,
            method: .get,
            queryItems: [
                "limit": "10",
                "team_id": "engineering"
            ],
            requiresConnectionId: false,
            requiresToken: true,
            body: nil
        )

        let endpoint: Endpoint<ListUserGroupsResponse> = .listUserGroups(
            limit: 10,
            idGt: nil,
            createdAtGt: nil,
            teamId: "engineering"
        )

        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("/api/v2/usergroups", endpoint.path.value)
        XCTAssertEqual(.get, endpoint.method)
        XCTAssertFalse(endpoint.requiresConnectionId)
        XCTAssertTrue(endpoint.requiresToken)
        XCTAssertNil(endpoint.body)
    }

    func test_searchUserGroups_buildsCorrectly() {
        let expectedEndpoint = Endpoint<ListUserGroupsResponse>(
            path: .searchUserGroups,
            method: .get,
            queryItems: [
                "query": "backend",
                "limit": "5",
                "team_id": "engineering"
            ],
            requiresConnectionId: false,
            requiresToken: true,
            body: nil
        )

        let endpoint: Endpoint<ListUserGroupsResponse> = .searchUserGroups(
            query: "backend",
            limit: 5,
            nameGt: nil,
            idGt: nil,
            teamId: "engineering"
        )

        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("/api/v2/usergroups/search", endpoint.path.value)
        XCTAssertEqual(.get, endpoint.method)
        XCTAssertFalse(endpoint.requiresConnectionId)
    }

    func test_getUserGroup_buildsCorrectly() {
        let expectedEndpoint = Endpoint<UserGroupResponse>(
            path: .getUserGroup(id: "backendsupport"),
            method: .get,
            queryItems: [
                "team_id": "engineering"
            ],
            requiresConnectionId: false,
            requiresToken: true,
            body: nil
        )

        let endpoint: Endpoint<UserGroupResponse> = .getUserGroup(id: "backendsupport", teamId: "engineering")

        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("/api/v2/usergroups/backendsupport", endpoint.path.value)
        XCTAssertEqual(.get, endpoint.method)
        XCTAssertFalse(endpoint.requiresConnectionId)
    }

    func test_createUserGroup_buildsCorrectly() {
        let request = CreateUserGroupRequest(
            description: "On-call backend support engineers",
            id: "backendsupport",
            memberIds: ["user1", "user2"],
            name: "Backend Support Team",
            teamId: "engineering"
        )

        let expectedEndpoint = Endpoint<UserGroupResponse>(
            path: .createUserGroup,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            requiresToken: true,
            body: request
        )

        let endpoint: Endpoint<UserGroupResponse> = .createUserGroup(createUserGroupRequest: request)

        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("/api/v2/usergroups", endpoint.path.value)
        XCTAssertEqual(.post, endpoint.method)
        XCTAssertFalse(endpoint.requiresConnectionId)
    }

    func test_updateUserGroup_buildsCorrectly() {
        let request = UpdateUserGroupRequest(
            description: "Updated description",
            name: "Updated Name",
            teamId: "engineering"
        )

        let expectedEndpoint = Endpoint<UserGroupResponse>(
            path: .updateUserGroup(id: "backendsupport"),
            method: .put,
            queryItems: nil,
            requiresConnectionId: false,
            requiresToken: true,
            body: request
        )

        let endpoint: Endpoint<UserGroupResponse> = .updateUserGroup(id: "backendsupport", updateUserGroupRequest: request)

        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("/api/v2/usergroups/backendsupport", endpoint.path.value)
        XCTAssertEqual(.put, endpoint.method)
        XCTAssertFalse(endpoint.requiresConnectionId)
    }

    func test_deleteUserGroup_buildsCorrectly() {
        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: .deleteUserGroup(id: "backendsupport"),
            method: .delete,
            queryItems: [
                "team_id": "engineering"
            ],
            requiresConnectionId: false,
            requiresToken: true,
            body: nil
        )

        let endpoint: Endpoint<EmptyResponse> = .deleteUserGroup(id: "backendsupport", teamId: "engineering")

        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("/api/v2/usergroups/backendsupport", endpoint.path.value)
        XCTAssertEqual(.delete, endpoint.method)
        XCTAssertFalse(endpoint.requiresConnectionId)
    }

    func test_addUserGroupMembers_buildsCorrectly() {
        let request = AddUserGroupMembersRequest(
            asAdmin: true,
            memberIds: ["user1", "user2"],
            teamId: "engineering"
        )

        let expectedEndpoint = Endpoint<UserGroupResponse>(
            path: .addUserGroupMembers(id: "backendsupport"),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            requiresToken: true,
            body: request
        )

        let endpoint: Endpoint<UserGroupResponse> = .addUserGroupMembers(id: "backendsupport", addUserGroupMembersRequest: request)

        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("/api/v2/usergroups/backendsupport/members", endpoint.path.value)
        XCTAssertEqual(.post, endpoint.method)
        XCTAssertFalse(endpoint.requiresConnectionId)
    }

    func test_removeUserGroupMembers_buildsCorrectly() {
        let request = RemoveUserGroupMembersRequest(
            memberIds: ["user1", "user2"],
            teamId: "engineering"
        )

        let expectedEndpoint = Endpoint<UserGroupResponse>(
            path: .removeUserGroupMembers(id: "backendsupport"),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            requiresToken: true,
            body: request
        )

        let endpoint: Endpoint<UserGroupResponse> = .removeUserGroupMembers(id: "backendsupport", removeUserGroupMembersRequest: request)

        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("/api/v2/usergroups/backendsupport/members/delete", endpoint.path.value)
        XCTAssertEqual(.post, endpoint.method)
        XCTAssertFalse(endpoint.requiresConnectionId)
    }
}
