//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class UserGroupMember: Sendable, Codable, JSONEncodable {
    public let createdAt: Date
    public let groupId: String
    public let isAdmin: Bool
    public let userId: String

    init(createdAt: Date, groupId: String, isAdmin: Bool, userId: String) {
        self.createdAt = createdAt
        self.groupId = groupId
        self.isAdmin = isAdmin
        self.userId = userId
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        case groupId = "group_id"
        case isAdmin = "is_admin"
        case userId = "user_id"
    }
}

extension UserGroupMember: Hashable {
    public static func == (lhs: UserGroupMember, rhs: UserGroupMember) -> Bool {
        lhs.createdAt == rhs.createdAt &&
            lhs.groupId == rhs.groupId &&
            lhs.isAdmin == rhs.isAdmin &&
            lhs.userId == rhs.userId
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(createdAt)
        hasher.combine(groupId)
        hasher.combine(isAdmin)
        hasher.combine(userId)
    }
}
