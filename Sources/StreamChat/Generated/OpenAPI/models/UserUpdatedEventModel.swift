//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UserUpdatedEventModel: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    /// Date/time of creation
    var createdAt: Date
    var custom: [String: RawJSON]
    var receivedAt: Date?
    /// The type of event: "user.updated" in this case
    var type: String = "user.updated"
    var user: UserResponsePrivacyFields

    init(createdAt: Date, custom: [String: RawJSON], receivedAt: Date? = nil, user: UserResponsePrivacyFields) {
        self.createdAt = createdAt
        self.custom = custom
        self.receivedAt = receivedAt
        self.user = user
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        case custom
        case receivedAt = "received_at"
        case type
        case user
    }

    static func == (lhs: UserUpdatedEventModel, rhs: UserUpdatedEventModel) -> Bool {
        lhs.createdAt == rhs.createdAt &&
            lhs.custom == rhs.custom &&
            lhs.receivedAt == rhs.receivedAt &&
            lhs.type == rhs.type &&
            lhs.user == rhs.user
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(createdAt)
        hasher.combine(custom)
        hasher.combine(receivedAt)
        hasher.combine(type)
        hasher.combine(user)
    }
}
