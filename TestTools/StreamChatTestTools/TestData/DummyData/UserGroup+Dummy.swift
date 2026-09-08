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
        createdAt: Date = .unique,
        groupId: String = .unique,
        isAdmin: Bool = false,
        userId: UserId = .unique
    ) -> UserGroupMember {
        .init(
            createdAt: createdAt,
            groupId: groupId,
            isAdmin: isAdmin,
            userId: userId
        )
    }
}

extension ListUserGroupsResponse {
    static func dummy(userGroups: [UserGroup] = [.dummy(), .dummy()]) -> ListUserGroupsResponse {
        .init(userGroups: userGroups)
    }
}

extension UserGroupResponse {
    static func dummy(userGroup: UserGroup? = .dummy()) -> UserGroupResponse {
        .init(userGroup: userGroup)
    }
}
