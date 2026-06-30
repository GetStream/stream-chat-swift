//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension UserGroupMemberPayload {
    func asModel() -> UserGroupMember {
        UserGroupMember(
            groupId: groupId,
            userId: userId,
            isAdmin: isAdmin,
            createdAt: createdAt
        )
    }
}

extension UserGroupResponse {
    func asModel() -> UserGroup {
        UserGroup(
            id: id,
            name: name,
            description: description,
            teamId: teamId,
            members: members?.map { $0.asModel() } ?? [],
            createdAt: createdAt,
            updatedAt: updatedAt,
            createdBy: createdBy
        )
    }
}
