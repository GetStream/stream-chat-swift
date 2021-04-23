//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// An object describing the incoming muted-user JSON payload.
struct MutedChannelPayload<ExtraData: ExtraDataTypes>: Decodable {
    private enum CodingKeys: String, CodingKey {
        case mutedChannel = "channel"
        case user
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    let mutedChannel: ChannelDetailPayload<ExtraData>
    let user: UserPayload<ExtraData.User>
    let createdAt: Date
    let updatedAt: Date
    
    init(
        mutedChannel: ChannelDetailPayload<ExtraData>,
        user: UserPayload<ExtraData.User>,
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
        mutedChannel = try container.decode(ChannelDetailPayload<ExtraData>.self, forKey: .mutedChannel)
        user = try container.decode(UserPayload<ExtraData.User>.self, forKey: .user)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .createdAt)
    }
}
