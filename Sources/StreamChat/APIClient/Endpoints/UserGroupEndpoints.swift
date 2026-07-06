//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension Endpoint {
    static func userGroups(query: UserGroupListQuery) -> Endpoint<UserGroupListPayload> {
        .init(
            path: .userGroups,
            method: .get,
            queryItems: query,
            requiresConnectionId: false,
            body: nil
        )
    }

    static func searchUserGroups(query: UserGroupSearchQuery) -> Endpoint<UserGroupListPayload> {
        .init(
            path: .userGroupSearch,
            method: .get,
            queryItems: query,
            requiresConnectionId: false,
            body: nil
        )
    }

    static func getUserGroup(id: String, teamId: String?) -> Endpoint<UserGroupPayloadResponse> {
        .init(
            path: .userGroup(id: id),
            method: .get,
            queryItems: UserGroupTeamQuery(teamId: teamId),
            requiresConnectionId: false,
            body: nil
        )
    }

    static func createUserGroup(request: CreateUserGroupRequestBody) -> Endpoint<UserGroupPayloadResponse> {
        .init(
            path: .userGroups,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: request
        )
    }

    static func updateUserGroup(
        id: String,
        request: UpdateUserGroupRequestBody
    ) -> Endpoint<UserGroupPayloadResponse> {
        .init(
            path: .userGroup(id: id),
            method: .put,
            queryItems: nil,
            requiresConnectionId: false,
            body: request
        )
    }

    static func deleteUserGroup(id: String, teamId: String?) -> Endpoint<EmptyResponse> {
        .init(
            path: .userGroup(id: id),
            method: .delete,
            queryItems: UserGroupTeamQuery(teamId: teamId),
            requiresConnectionId: false,
            body: nil
        )
    }

    static func addUserGroupMembers(
        id: String,
        request: UserGroupMembersRequestBody
    ) -> Endpoint<UserGroupPayloadResponse> {
        .init(
            path: .userGroupMembers(id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: request
        )
    }

    static func removeUserGroupMembers(
        id: String,
        request: UserGroupMembersRequestBody
    ) -> Endpoint<UserGroupPayloadResponse> {
        .init(
            path: .userGroupMembersDelete(id: id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: request
        )
    }
}
