//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

/// An object describing the incoming muted-user JSON payload.
struct MutedChannelPayload: Decodable {
    private enum CodingKeys: String, CodingKey {
        case mutedChannel = "channel"
        case user
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    let mutedChannel: ChannelDetailPayload
    let user: UserPayload
    let createdAt: Date
    let updatedAt: Date
    
    init(
        mutedChannel: ChannelDetailPayload,
        user: UserPayload,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.mutedChannel = mutedChannel
        self.user = user
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        mutedChannel = try container.decode(ChannelDetailPayload.self, forKey: .mutedChannel)
        user = try container.decode(UserPayload.self, forKey: .user)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .createdAt)
    }
}
