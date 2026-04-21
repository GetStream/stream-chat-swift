//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UserMutedEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    /// Date/time of creation
    var createdAt: Date
    var custom: [String: RawJSON]
    var receivedAt: Date?
    var targetUser: UserResponseCommonFields?
    /// The target users that were muted
    var targetUsers: [UserResponseCommonFields]?
    /// The type of event: "user.muted" in this case
    var type: String = "user.muted"
    var user: UserResponseCommonFields

    init(createdAt: Date, custom: [String: RawJSON], receivedAt: Date? = nil, targetUser: UserResponseCommonFields? = nil, targetUsers: [UserResponseCommonFields]? = nil, user: UserResponseCommonFields) {
        self.createdAt = createdAt
        self.custom = custom
        self.receivedAt = receivedAt
        self.targetUser = targetUser
        self.targetUsers = targetUsers
        self.user = user
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        case custom
        case receivedAt = "received_at"
        case targetUser = "target_user"
        case targetUsers = "target_users"
        case type
        case user
    }

    static func == (lhs: UserMutedEvent, rhs: UserMutedEvent) -> Bool {
        lhs.createdAt == rhs.createdAt &&
            lhs.custom == rhs.custom &&
            lhs.receivedAt == rhs.receivedAt &&
            lhs.targetUser == rhs.targetUser &&
            lhs.targetUsers == rhs.targetUsers &&
            lhs.type == rhs.type &&
            lhs.user == rhs.user
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(createdAt)
        hasher.combine(custom)
        hasher.combine(receivedAt)
        hasher.combine(targetUser)
        hasher.combine(targetUsers)
        hasher.combine(type)
        hasher.combine(user)
    }
}
