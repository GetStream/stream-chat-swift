//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UserGroupMember: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var appPk: Int
    var createdAt: Date
    var groupId: String
    var isAdmin: Bool
    var userId: String

    init(appPk: Int, createdAt: Date, groupId: String, isAdmin: Bool, userId: String) {
        self.appPk = appPk
        self.createdAt = createdAt
        self.groupId = groupId
        self.isAdmin = isAdmin
        self.userId = userId
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case appPk = "app_pk"
        case createdAt = "created_at"
        case groupId = "group_id"
        case isAdmin = "is_admin"
        case userId = "user_id"
    }

    static func == (lhs: UserGroupMember, rhs: UserGroupMember) -> Bool {
        lhs.appPk == rhs.appPk &&
            lhs.createdAt == rhs.createdAt &&
            lhs.groupId == rhs.groupId &&
            lhs.isAdmin == rhs.isAdmin &&
            lhs.userId == rhs.userId
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(appPk)
        hasher.combine(createdAt)
        hasher.combine(groupId)
        hasher.combine(isAdmin)
        hasher.combine(userId)
    }
}
