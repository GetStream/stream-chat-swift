//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class BanResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var bannedBy: UserResponse?
    var channel: ChannelResponse?
    var createdAt: Date
    var expires: Date?
    var reason: String?
    var shadow: Bool?
    var user: UserResponse?

    init(bannedBy: UserResponse? = nil, channel: ChannelResponse? = nil, createdAt: Date, expires: Date? = nil, reason: String? = nil, shadow: Bool? = nil, user: UserResponse? = nil) {
        self.bannedBy = bannedBy
        self.channel = channel
        self.createdAt = createdAt
        self.expires = expires
        self.reason = reason
        self.shadow = shadow
        self.user = user
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case bannedBy = "banned_by"
        case channel
        case createdAt = "created_at"
        case expires
        case reason
        case shadow
        case user
    }

    static func == (lhs: BanResponse, rhs: BanResponse) -> Bool {
        lhs.bannedBy == rhs.bannedBy &&
            lhs.channel == rhs.channel &&
            lhs.createdAt == rhs.createdAt &&
            lhs.expires == rhs.expires &&
            lhs.reason == rhs.reason &&
            lhs.shadow == rhs.shadow &&
            lhs.user == rhs.user
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(bannedBy)
        hasher.combine(channel)
        hasher.combine(createdAt)
        hasher.combine(expires)
        hasher.combine(reason)
        hasher.combine(shadow)
        hasher.combine(user)
    }
}
