//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension UserGroup {
    static func dummy(
        createdAt: Date = .unique,
        createdBy: UserId? = nil,
        description: String? = nil,
        id: String = .unique,
        members: [UserGroupMember] = [],
        name: String = .unique,
        teamId: String? = nil,
        updatedAt: Date = .unique
    ) -> UserGroup {
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

extension UserGroupMember {
    static func dummy(
        appPk: Int = 0,
        createdAt: Date = .unique,
        groupId: String = .unique,
        isAdmin: Bool = false,
        userId: UserId = .unique
    ) -> UserGroupMember {
        .init(
            appPk: appPk,
            createdAt: createdAt,
            groupId: groupId,
            isAdmin: isAdmin,
            userId: userId
        )
    }
}

extension ListUserGroupsResponse {
    static func dummy(duration: String = "", userGroups: [UserGroup] = [.dummy(), .dummy()]) -> ListUserGroupsResponse {
        .init(duration: duration, userGroups: userGroups)
    }
}

extension SearchUserGroupsResponse {
    static func dummy(duration: String = "", userGroups: [UserGroup] = [.dummy(), .dummy()]) -> SearchUserGroupsResponse {
        .init(duration: duration, userGroups: userGroups)
    }
}

extension GetUserGroupResponse {
    static func dummy(duration: String = "", userGroup: UserGroup? = .dummy()) -> GetUserGroupResponse {
        .init(duration: duration, userGroup: userGroup)
    }
}

extension CreateUserGroupResponse {
    static func dummy(duration: String = "", userGroup: UserGroup? = .dummy()) -> CreateUserGroupResponse {
        .init(duration: duration, userGroup: userGroup)
    }
}

extension UpdateUserGroupResponse {
    static func dummy(duration: String = "", userGroup: UserGroup? = .dummy()) -> UpdateUserGroupResponse {
        .init(duration: duration, userGroup: userGroup)
    }
}

extension AddUserGroupMembersResponse {
    static func dummy(duration: String = "", userGroup: UserGroup? = .dummy()) -> AddUserGroupMembersResponse {
        .init(duration: duration, userGroup: userGroup)
    }
}

extension RemoveUserGroupMembersResponse {
    static func dummy(duration: String = "", userGroup: UserGroup? = .dummy()) -> RemoveUserGroupMembersResponse {
        .init(duration: duration, userGroup: userGroup)
    }
}
