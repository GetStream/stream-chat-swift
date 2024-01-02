//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// The type describes the outgoing JSON to `ban` endpoint
struct ChannelMemberUnbanRequestPayload: Encodable {
    private enum CodingKeys: String, CodingKey {
        case userId = "target_user_id"
        case channelType = "type"
        case channelId = "id"
    }

    let userId: String
    let channelType: ChannelType
    let channelId: String

    init(
        userId: UserId,
        cid: ChannelId
    ) {
        self.userId = userId
        channelType = cid.type
        channelId = cid.id
    }
}
