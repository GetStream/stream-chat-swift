//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension UserGroupResponse {
    /// Converts the generated API response into the public `UserGroup` model.
    func asModel() -> UserGroup {
        UserGroup(
            id: id,
            name: name,
            description: description,
            teamId: teamId,
            members: (members ?? []).map { $0.asModel() },
            createdAt: createdAt,
            updatedAt: updatedAt,
            createdBy: createdBy
        )
    }
}

extension UserGroupMemberResponse {
    /// Converts the generated API response into the public `UserGroupMember` model.
    func asModel() -> UserGroupMember {
        UserGroupMember(
            groupId: groupId,
            userId: userId,
            isAdmin: isAdmin,
            createdAt: createdAt
        )
    }
}
