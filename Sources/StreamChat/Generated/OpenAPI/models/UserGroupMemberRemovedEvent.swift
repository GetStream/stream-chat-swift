//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UserGroupMemberRemovedEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    /// Date/time of creation
    var createdAt: Date
    var custom: [String: RawJSON]
    /// The user IDs that were removed
    var members: [String]
    var receivedAt: Date?
    /// The type of event: "user_group.member_removed" in this case
    var type: String = "user_group.member_removed"
    var user: UserResponseCommonFields?
    var userGroup: UserGroup?

    init(createdAt: Date, custom: [String: RawJSON], members: [String], receivedAt: Date? = nil, user: UserResponseCommonFields? = nil, userGroup: UserGroup? = nil) {
        self.createdAt = createdAt
        self.custom = custom
        self.members = members
        self.receivedAt = receivedAt
        self.user = user
        self.userGroup = userGroup
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        case custom
        case members
        case receivedAt = "received_at"
        case type
        case user
        case userGroup = "user_group"
    }

    static func == (lhs: UserGroupMemberRemovedEvent, rhs: UserGroupMemberRemovedEvent) -> Bool {
        lhs.createdAt == rhs.createdAt &&
            lhs.custom == rhs.custom &&
            lhs.members == rhs.members &&
            lhs.receivedAt == rhs.receivedAt &&
            lhs.type == rhs.type &&
            lhs.user == rhs.user &&
            lhs.userGroup == rhs.userGroup
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(createdAt)
        hasher.combine(custom)
        hasher.combine(members)
        hasher.combine(receivedAt)
        hasher.combine(type)
        hasher.combine(user)
        hasher.combine(userGroup)
    }
}
