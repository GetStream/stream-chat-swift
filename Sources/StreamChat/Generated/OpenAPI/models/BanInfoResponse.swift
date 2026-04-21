//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class BanInfoResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// When the ban was created
    var createdAt: Date
    var createdBy: UserResponse?
    /// When the ban expires
    var expires: Date?
    /// Reason for the ban
    var reason: String?
    /// Whether this is a shadow ban
    var shadow: Bool?
    var user: UserResponse?

    init(createdAt: Date, createdBy: UserResponse? = nil, expires: Date? = nil, reason: String? = nil, shadow: Bool? = nil, user: UserResponse? = nil) {
        self.createdAt = createdAt
        self.createdBy = createdBy
        self.expires = expires
        self.reason = reason
        self.shadow = shadow
        self.user = user
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        case createdBy = "created_by"
        case expires
        case reason
        case shadow
        case user
    }

    static func == (lhs: BanInfoResponse, rhs: BanInfoResponse) -> Bool {
        lhs.createdAt == rhs.createdAt &&
            lhs.createdBy == rhs.createdBy &&
            lhs.expires == rhs.expires &&
            lhs.reason == rhs.reason &&
            lhs.shadow == rhs.shadow &&
            lhs.user == rhs.user
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(createdAt)
        hasher.combine(createdBy)
        hasher.combine(expires)
        hasher.combine(reason)
        hasher.combine(shadow)
        hasher.combine(user)
    }
}
