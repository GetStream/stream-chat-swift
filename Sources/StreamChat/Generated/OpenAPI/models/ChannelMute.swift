//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ChannelMute: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var channel: ChannelResponse?
    /// Date/time of creation
    var createdAt: Date
    /// Date/time of mute expiration
    var expires: Date?
    /// Date/time of the last update
    var updatedAt: Date
    var user: UserResponse?

    init(channel: ChannelResponse? = nil, createdAt: Date, expires: Date? = nil, updatedAt: Date, user: UserResponse? = nil) {
        self.channel = channel
        self.createdAt = createdAt
        self.expires = expires
        self.updatedAt = updatedAt
        self.user = user
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channel
        case createdAt = "created_at"
        case expires
        case updatedAt = "updated_at"
        case user
    }

    static func == (lhs: ChannelMute, rhs: ChannelMute) -> Bool {
        lhs.channel == rhs.channel &&
            lhs.createdAt == rhs.createdAt &&
            lhs.expires == rhs.expires &&
            lhs.updatedAt == rhs.updatedAt &&
            lhs.user == rhs.user
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(channel)
        hasher.combine(createdAt)
        hasher.combine(expires)
        hasher.combine(updatedAt)
        hasher.combine(user)
    }
}
