//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class BanResponse: Sendable, Codable, JSONEncodable {
    /// User response object
    let bannedBy: UserPayload?
    /// Represents channel in chat
    let channel: ChannelDetailPayload?
    let createdAt: Date
    let expires: Date?
    let reason: String?
    let shadow: Bool?
    /// User response object
    let user: UserPayload?

    init(
        bannedBy: UserPayload? = nil,
        channel: ChannelDetailPayload? = nil,
        createdAt: Date,
        expires: Date? = nil,
        reason: String? = nil,
        shadow: Bool? = nil,
        user: UserPayload? = nil
    ) {
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
}
