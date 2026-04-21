//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UserGroupUpdatedEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    /// Date/time of creation
    var createdAt: Date
    var custom: [String: RawJSON]
    var receivedAt: Date?
    /// The type of event: "user_group.updated" in this case
    var type: String = "user_group.updated"
    var user: UserResponseCommonFields?
    var userGroup: UserGroup?

    init(createdAt: Date, custom: [String: RawJSON], receivedAt: Date? = nil, user: UserResponseCommonFields? = nil, userGroup: UserGroup? = nil) {
        self.createdAt = createdAt
        self.custom = custom
        self.receivedAt = receivedAt
        self.user = user
        self.userGroup = userGroup
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        case custom
        case receivedAt = "received_at"
        case type
        case user
        case userGroup = "user_group"
    }

    static func == (lhs: UserGroupUpdatedEvent, rhs: UserGroupUpdatedEvent) -> Bool {
        lhs.createdAt == rhs.createdAt &&
            lhs.custom == rhs.custom &&
            lhs.receivedAt == rhs.receivedAt &&
            lhs.type == rhs.type &&
            lhs.user == rhs.user &&
            lhs.userGroup == rhs.userGroup
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(createdAt)
        hasher.combine(custom)
        hasher.combine(receivedAt)
        hasher.combine(type)
        hasher.combine(user)
        hasher.combine(userGroup)
    }
}
