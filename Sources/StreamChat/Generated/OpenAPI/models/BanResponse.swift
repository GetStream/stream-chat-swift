//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class BanResponse: Sendable, Decodable {
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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.bannedBy = try container.decodeIfPresent(UserPayload.self, forKey: .bannedBy)
        self.channel = try container.decodeIfPresent(ChannelDetailPayload.self, forKey: .channel)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.expires = try container.decodeIfPresent(Date.self, forKey: .expires)
        self.reason = try container.decodeIfPresent(String.self, forKey: .reason)
        self.shadow = try container.decodeIfPresent(Bool.self, forKey: .shadow)
        self.user = try container.decodeIfPresent(UserPayload.self, forKey: .user)
    }
}
