//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UserGroupMemberPayload: Sendable, Codable, JSONEncodable {
    let appPk: Int
    let createdAt: Date
    let groupId: String
    let isAdmin: Bool
    let userId: String

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
}
