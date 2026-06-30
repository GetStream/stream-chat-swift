//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class UserGroupEndpoints_Tests: XCTestCase {
    func test_listUserGroups_buildsCorrectly() {
        let query = UserGroupListQuery(limit: 10, teamId: "engineering")

        let endpoint: Endpoint<ListUserGroupsResponse> = .listUserGroups(
            limit: query.limit,
            idGt: query.idGreaterThan,
            createdAtGt: query.createdAtGreaterThan.map { RFC3339DateFormatter.string(from: $0) },
            teamId: query.teamId
        )

        XCTAssertEqual("/api/v2/usergroups", endpoint.path.value)
        XCTAssertEqual(.get, endpoint.method)
        XCTAssertFalse(endpoint.requiresConnectionId)
    }

    func test_searchUserGroups_buildsCorrectly() {
        let query = UserGroupSearchQuery(query: "backend", limit: 5, teamId: "engineering")

        let endpoint: Endpoint<SearchUserGroupsResponse> = .searchUserGroups(
            query: query.query,
            limit: query.limit,
            nameGt: query.nameGreaterThan,
            idGt: query.idGreaterThan,
            teamId: query.teamId
        )

        XCTAssertEqual("/api/v2/usergroups/search", endpoint.path.value)
        XCTAssertEqual(.get, endpoint.method)
        XCTAssertFalse(endpoint.requiresConnectionId)
    }

    func test_getUserGroup_buildsCorrectly() {
        let endpoint: Endpoint<GetUserGroupResponse> = .getUserGroup(id: "backendsupport", teamId: "engineering")

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

        let expectedEndpoint = Endpoint<CreateUserGroupResponse>(
            path: .createUserGroup,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            requiresToken: true,
            body: request
        )

        let endpoint: Endpoint<CreateUserGroupResponse> = .createUserGroup(createUserGroupRequest: request)

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

        let expectedEndpoint = Endpoint<UpdateUserGroupResponse>(
            path: .updateUserGroup(id: "backendsupport"),
            method: .put,
            queryItems: nil,
            requiresConnectionId: false,
            requiresToken: true,
            body: request
        )

        let endpoint: Endpoint<UpdateUserGroupResponse> = .updateUserGroup(id: "backendsupport", updateUserGroupRequest: request)

        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("/api/v2/usergroups/backendsupport", endpoint.path.value)
        XCTAssertEqual(.put, endpoint.method)
        XCTAssertFalse(endpoint.requiresConnectionId)
    }

    func test_deleteUserGroup_buildsCorrectly() {
        let endpoint: Endpoint<Response> = .deleteUserGroup(id: "backendsupport", teamId: "engineering")

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

        let expectedEndpoint = Endpoint<AddUserGroupMembersResponse>(
            path: .addUserGroupMembers(id: "backendsupport"),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            requiresToken: true,
            body: request
        )

        let endpoint: Endpoint<AddUserGroupMembersResponse> = .addUserGroupMembers(id: "backendsupport", addUserGroupMembersRequest: request)

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

        let expectedEndpoint = Endpoint<RemoveUserGroupMembersResponse>(
            path: .removeUserGroupMembers(id: "backendsupport"),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            requiresToken: true,
            body: request
        )

        let endpoint: Endpoint<RemoveUserGroupMembersResponse> = .removeUserGroupMembers(id: "backendsupport", removeUserGroupMembersRequest: request)

        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("/api/v2/usergroups/backendsupport/members/delete", endpoint.path.value)
        XCTAssertEqual(.post, endpoint.method)
        XCTAssertFalse(endpoint.requiresConnectionId)
    }
}
