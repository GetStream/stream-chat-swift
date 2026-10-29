//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class UserGroupMember: Sendable, Decodable {
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

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.groupId = try container.decode(String.self, forKey: .groupId)
        self.isAdmin = try container.decode(Bool.self, forKey: .isAdmin)
        self.userId = try container.decode(String.self, forKey: .userId)
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
