//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// An object describing the incoming muted-channel JSON payload.
struct MutedChannelPayload: Decodable {
    private enum CodingKeys: String, CodingKey {
        case mutedChannel = "channel"
        case user
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case expiresAt = "expires"
    }

    let mutedChannel: ChannelDetailPayload
    let user: UserPayload
    let createdAt: Date
    let updatedAt: Date
    let expiresAt: Date?

    init(
        mutedChannel: ChannelDetailPayload,
        user: UserPayload,
        createdAt: Date,
        updatedAt: Date,
        expiresAt: Date? = nil
    ) {
        self.mutedChannel = mutedChannel
        self.user = user
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.expiresAt = expiresAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        mutedChannel = try container.decode(ChannelDetailPayload.self, forKey: .mutedChannel)
        user = try container.decode(UserPayload.self, forKey: .user)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .createdAt)
        expiresAt = try container.decodeIfPresent(Date.self, forKey: .expiresAt)
    }
}
