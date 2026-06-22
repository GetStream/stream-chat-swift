//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class UserGroupEndpoints_Tests: XCTestCase {
    func test_listUserGroups_buildsCorrectly() {
        let endpoint: Endpoint<ListUserGroupsResponse> = .listUserGroups(
            limit: 10,
            idGt: nil,
            createdAtGt: nil,
            teamId: "engineering"
        )

        XCTAssertEqual("/api/v2/usergroups", endpoint.path.value)
        XCTAssertEqual(.get, endpoint.method)
        XCTAssertFalse(endpoint.requiresConnectionId)
        XCTAssertTrue(endpoint.requiresToken)
    }

    func test_searchUserGroups_buildsCorrectly() {
        let endpoint: Endpoint<SearchUserGroupsResponse> = .searchUserGroups(
            query: "backend",
            limit: 5,
            nameGt: nil,
            idGt: nil,
            teamId: "engineering"
        )

        XCTAssertEqual("/api/v2/usergroups/search", endpoint.path.value)
        XCTAssertEqual(.get, endpoint.method)
        XCTAssertFalse(endpoint.requiresConnectionId)
        XCTAssertTrue(endpoint.requiresToken)
    }

    func test_getUserGroup_buildsCorrectly() {
        let endpoint: Endpoint<GetUserGroupResponse> = .getUserGroup(id: "backendsupport", teamId: "engineering")

        XCTAssertEqual("/api/v2/usergroups/backendsupport", endpoint.path.value)
        XCTAssertEqual(.get, endpoint.method)
        XCTAssertFalse(endpoint.requiresConnectionId)
        XCTAssertTrue(endpoint.requiresToken)
    }

    func test_createUserGroup_buildsCorrectly() {
        let request = CreateUserGroupRequest(
            description: "On-call backend support engineers",
            id: "backendsupport",
            memberIds: ["user1", "user2"],
            name: "Backend Support Team",
            teamId: "engineering"
        )

        let expectedEndpoint: Endpoint<CreateUserGroupResponse> = .init(
            path: .createUserGroup,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: request
        )

        let endpoint: Endpoint<CreateUserGroupResponse> = .createUserGroup(createUserGroupRequest: request)

        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("/api/v2/usergroups", endpoint.path.value)
        XCTAssertEqual(.post, endpoint.method)
    }

    func test_updateUserGroup_buildsCorrectly() {
        let request = UpdateUserGroupRequest(
            description: "Updated description",
            name: "Updated Name",
            teamId: "engineering"
        )

        let expectedEndpoint: Endpoint<UpdateUserGroupResponse> = .init(
            path: .updateUserGroup(id: "backendsupport"),
            method: .put,
            queryItems: nil,
            requiresConnectionId: false,
            body: request
        )

        let endpoint: Endpoint<UpdateUserGroupResponse> = .updateUserGroup(id: "backendsupport", updateUserGroupRequest: request)

        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("/api/v2/usergroups/backendsupport", endpoint.path.value)
        XCTAssertEqual(.put, endpoint.method)
    }

    func test_deleteUserGroup_buildsCorrectly() {
        let endpoint: Endpoint<Response> = .deleteUserGroup(id: "backendsupport", teamId: "engineering")

        XCTAssertEqual("/api/v2/usergroups/backendsupport", endpoint.path.value)
        XCTAssertEqual(.delete, endpoint.method)
        XCTAssertFalse(endpoint.requiresConnectionId)
        XCTAssertTrue(endpoint.requiresToken)
    }

    func test_addUserGroupMembers_buildsCorrectly() {
        let request = AddUserGroupMembersRequest(
            asAdmin: true,
            memberIds: ["user1", "user2"],
            teamId: "engineering"
        )

        let expectedEndpoint: Endpoint<AddUserGroupMembersResponse> = .init(
            path: .addUserGroupMembers(id: "backendsupport"),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: request
        )

        let endpoint: Endpoint<AddUserGroupMembersResponse> = .addUserGroupMembers(
            id: "backendsupport",
            addUserGroupMembersRequest: request
        )

        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("/api/v2/usergroups/backendsupport/members", endpoint.path.value)
        XCTAssertEqual(.post, endpoint.method)
    }

    func test_removeUserGroupMembers_buildsCorrectly() {
        let request = RemoveUserGroupMembersRequest(
            memberIds: ["user1", "user2"],
            teamId: "engineering"
        )

        let expectedEndpoint: Endpoint<RemoveUserGroupMembersResponse> = .init(
            path: .removeUserGroupMembers(id: "backendsupport"),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: request
        )

        let endpoint: Endpoint<RemoveUserGroupMembersResponse> = .removeUserGroupMembers(
            id: "backendsupport",
            removeUserGroupMembersRequest: request
        )

        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("/api/v2/usergroups/backendsupport/members/delete", endpoint.path.value)
        XCTAssertEqual(.post, endpoint.method)
    }
}
