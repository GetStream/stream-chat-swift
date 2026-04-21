//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UserDeactivatedEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    /// Date/time of creation
    var createdAt: Date
    var createdBy: UserResponseCommonFields?
    var custom: [String: RawJSON]
    var receivedAt: Date?
    /// The type of event: "user.deactivated" in this case
    var type: String = "user.deactivated"
    var user: UserResponseCommonFields

    init(createdAt: Date, createdBy: UserResponseCommonFields? = nil, custom: [String: RawJSON], receivedAt: Date? = nil, user: UserResponseCommonFields) {
        self.createdAt = createdAt
        self.createdBy = createdBy
        self.custom = custom
        self.receivedAt = receivedAt
        self.user = user
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        case createdBy = "created_by"
        case custom
        case receivedAt = "received_at"
        case type
        case user
    }

    static func == (lhs: UserDeactivatedEvent, rhs: UserDeactivatedEvent) -> Bool {
        lhs.createdAt == rhs.createdAt &&
            lhs.createdBy == rhs.createdBy &&
            lhs.custom == rhs.custom &&
            lhs.receivedAt == rhs.receivedAt &&
            lhs.type == rhs.type &&
            lhs.user == rhs.user
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(createdAt)
        hasher.combine(createdBy)
        hasher.combine(custom)
        hasher.combine(receivedAt)
        hasher.combine(type)
        hasher.combine(user)
    }
}
