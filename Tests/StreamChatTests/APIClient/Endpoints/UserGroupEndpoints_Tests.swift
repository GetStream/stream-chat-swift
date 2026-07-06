//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class UserGroupEndpoints_Tests: XCTestCase {
    func test_userGroups_buildsCorrectly() {
        let query = UserGroupListQuery(limit: 10, teamId: "engineering")

        let expectedEndpoint = Endpoint<UserGroupListPayload>(
            path: .userGroups,
            method: .get,
            queryItems: query,
            requiresConnectionId: false,
            requiresToken: true,
            body: nil
        )

        let endpoint: Endpoint<UserGroupListPayload> = .userGroups(query: query)

        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("usergroups", endpoint.path.value)
        XCTAssertEqual(.get, endpoint.method)
        XCTAssertFalse(endpoint.requiresConnectionId)
        XCTAssertTrue(endpoint.requiresToken)
    }

    func test_searchUserGroups_buildsCorrectly() {
        let query = UserGroupSearchQuery(query: "backend", limit: 5, teamId: "engineering")

        let expectedEndpoint = Endpoint<UserGroupListPayload>(
            path: .userGroupSearch,
            method: .get,
            queryItems: query,
            requiresConnectionId: false,
            requiresToken: true,
            body: nil
        )

        let endpoint: Endpoint<UserGroupListPayload> = .searchUserGroups(query: query)

        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("usergroups/search", endpoint.path.value)
        XCTAssertEqual(.get, endpoint.method)
        XCTAssertFalse(endpoint.requiresConnectionId)
    }

    func test_getUserGroup_buildsCorrectly() {
        let expectedEndpoint = Endpoint<UserGroupPayloadResponse>(
            path: .userGroup(id: "backendsupport"),
            method: .get,
            queryItems: UserGroupTeamQuery(teamId: "engineering"),
            requiresConnectionId: false,
            requiresToken: true,
            body: nil
        )

        let endpoint: Endpoint<UserGroupPayloadResponse> = .getUserGroup(id: "backendsupport", teamId: "engineering")

        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("usergroups/backendsupport", endpoint.path.value)
        XCTAssertEqual(.get, endpoint.method)
        XCTAssertFalse(endpoint.requiresConnectionId)
    }

    func test_createUserGroup_buildsCorrectly() {
        let request = CreateUserGroupRequestBody(
            id: "backendsupport",
            name: "Backend Support Team",
            description: "On-call backend support engineers",
            teamId: "engineering",
            memberIds: ["user1", "user2"]
        )

        let expectedEndpoint = Endpoint<UserGroupPayloadResponse>(
            path: .userGroups,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            requiresToken: true,
            body: request
        )

        let endpoint: Endpoint<UserGroupPayloadResponse> = .createUserGroup(request: request)

        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("usergroups", endpoint.path.value)
        XCTAssertEqual(.post, endpoint.method)
        XCTAssertFalse(endpoint.requiresConnectionId)
    }

    func test_updateUserGroup_buildsCorrectly() {
        let request = UpdateUserGroupRequestBody(
            name: "Updated Name",
            description: "Updated description",
            teamId: "engineering"
        )

        let expectedEndpoint = Endpoint<UserGroupPayloadResponse>(
            path: .userGroup(id: "backendsupport"),
            method: .put,
            queryItems: nil,
            requiresConnectionId: false,
            requiresToken: true,
            body: request
        )

        let endpoint: Endpoint<UserGroupPayloadResponse> = .updateUserGroup(id: "backendsupport", request: request)

        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("usergroups/backendsupport", endpoint.path.value)
        XCTAssertEqual(.put, endpoint.method)
        XCTAssertFalse(endpoint.requiresConnectionId)
    }

    func test_deleteUserGroup_buildsCorrectly() {
        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: .userGroup(id: "backendsupport"),
            method: .delete,
            queryItems: UserGroupTeamQuery(teamId: "engineering"),
            requiresConnectionId: false,
            requiresToken: true,
            body: nil
        )

        let endpoint: Endpoint<EmptyResponse> = .deleteUserGroup(id: "backendsupport", teamId: "engineering")

        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("usergroups/backendsupport", endpoint.path.value)
        XCTAssertEqual(.delete, endpoint.method)
        XCTAssertFalse(endpoint.requiresConnectionId)
    }

    func test_addUserGroupMembers_buildsCorrectly() {
        let request = UserGroupMembersRequestBody(
            memberIds: ["user1", "user2"],
            asAdmin: true,
            teamId: "engineering"
        )

        let expectedEndpoint = Endpoint<UserGroupPayloadResponse>(
            path: .userGroupMembers(id: "backendsupport"),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            requiresToken: true,
            body: request
        )

        let endpoint: Endpoint<UserGroupPayloadResponse> = .addUserGroupMembers(id: "backendsupport", request: request)

        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("usergroups/backendsupport/members", endpoint.path.value)
        XCTAssertEqual(.post, endpoint.method)
        XCTAssertFalse(endpoint.requiresConnectionId)
    }

    func test_removeUserGroupMembers_buildsCorrectly() {
        let request = UserGroupMembersRequestBody(
            memberIds: ["user1", "user2"],
            teamId: "engineering"
        )

        let expectedEndpoint = Endpoint<UserGroupPayloadResponse>(
            path: .userGroupMembersDelete(id: "backendsupport"),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            requiresToken: true,
            body: request
        )

        let endpoint: Endpoint<UserGroupPayloadResponse> = .removeUserGroupMembers(id: "backendsupport", request: request)

        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("usergroups/backendsupport/members/delete", endpoint.path.value)
        XCTAssertEqual(.post, endpoint.method)
        XCTAssertFalse(endpoint.requiresConnectionId)
    }
}
