//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension UserGroupMemberPayload {
    static func dummy(
        appPk: Int = 0,
        createdAt: Date = .unique,
        groupId: String = .unique,
        isAdmin: Bool = false,
        userId: String = .unique
    ) -> UserGroupMemberPayload {
        .init(
            appPk: appPk,
            createdAt: createdAt,
            groupId: groupId,
            isAdmin: isAdmin,
            userId: userId
        )
    }
}

extension UserGroupResponse {
    static func dummy(
        createdAt: Date = .unique,
        createdBy: String? = nil,
        description: String? = nil,
        id: String = .unique,
        members: [UserGroupMemberPayload] = [.dummy()],
        name: String = .unique,
        teamId: String? = nil,
        updatedAt: Date = .unique
    ) -> UserGroupResponse {
        .init(
            createdAt: createdAt,
            createdBy: createdBy,
            description: description,
            id: id,
            members: members,
            name: name,
            teamId: teamId,
            updatedAt: updatedAt
        )
    }
}

extension ListUserGroupsResponse {
    static func dummy(userGroups: [UserGroupResponse] = [.dummy(), .dummy()]) -> ListUserGroupsResponse {
        .init(duration: "", userGroups: userGroups)
    }
}

extension SearchUserGroupsResponse {
    static func dummy(userGroups: [UserGroupResponse] = [.dummy(), .dummy()]) -> SearchUserGroupsResponse {
        .init(duration: "", userGroups: userGroups)
    }
}

extension GetUserGroupResponse {
    static func dummy(userGroup: UserGroupResponse = .dummy()) -> GetUserGroupResponse {
        .init(duration: "", userGroup: userGroup)
    }
}

extension CreateUserGroupResponse {
    static func dummy(userGroup: UserGroupResponse = .dummy()) -> CreateUserGroupResponse {
        .init(duration: "", userGroup: userGroup)
    }
}

extension UpdateUserGroupResponse {
    static func dummy(userGroup: UserGroupResponse = .dummy()) -> UpdateUserGroupResponse {
        .init(duration: "", userGroup: userGroup)
    }
}

extension AddUserGroupMembersResponse {
    static func dummy(userGroup: UserGroupResponse = .dummy()) -> AddUserGroupMembersResponse {
        .init(duration: "", userGroup: userGroup)
    }
}

extension RemoveUserGroupMembersResponse {
    static func dummy(userGroup: UserGroupResponse = .dummy()) -> RemoveUserGroupMembersResponse {
        .init(duration: "", userGroup: userGroup)
    }
}
