//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class MutedChannelPayload: Sendable, Decodable {
    /// Represents channel in chat
    let channel: ChannelDetailPayload?
    /// Date/time of creation
    let createdAt: Date
    /// Date/time of mute expiration
    let expires: Date?
    /// Date/time of the last update
    let updatedAt: Date
    /// User response object
    let user: UserPayload?

    init(
        channel: ChannelDetailPayload? = nil,
        createdAt: Date,
        expires: Date? = nil,
        updatedAt: Date,
        user: UserPayload? = nil
    ) {
        self.channel = channel
        self.createdAt = createdAt
        self.expires = expires
        self.updatedAt = updatedAt
        self.user = user
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.channel = try container.decodeIfPresent(ChannelDetailPayload.self, forKey: .channel)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.expires = try container.decodeIfPresent(Date.self, forKey: .expires)
        self.updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        self.user = try container.decodeIfPresent(UserPayload.self, forKey: .user)
    }
}
