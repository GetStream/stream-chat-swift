//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UserMuteResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var createdAt: Date
    var expires: Date?
    var target: UserResponse?
    var updatedAt: Date
    var user: UserResponse?

    init(createdAt: Date, expires: Date? = nil, target: UserResponse? = nil, updatedAt: Date, user: UserResponse? = nil) {
        self.createdAt = createdAt
        self.expires = expires
        self.target = target
        self.updatedAt = updatedAt
        self.user = user
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        case expires
        case target
        case updatedAt = "updated_at"
        case user
    }

    static func == (lhs: UserMuteResponse, rhs: UserMuteResponse) -> Bool {
        lhs.createdAt == rhs.createdAt &&
            lhs.expires == rhs.expires &&
            lhs.target == rhs.target &&
            lhs.updatedAt == rhs.updatedAt &&
            lhs.user == rhs.user
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(createdAt)
        hasher.combine(expires)
        hasher.combine(target)
        hasher.combine(updatedAt)
        hasher.combine(user)
    }
}
