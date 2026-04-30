//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// The type describes the outgoing JSON to `ban` endpoint
struct ChannelMemberUnbanRequestPayload: Encodable {
    private enum CodingKeys: String, CodingKey {
        case userId = "target_user_id"
        case channelCid = "channel_cid"
        case createdBy = "created_by"
        case removeFutureChannelsBan = "remove_future_channels_ban"
        case reason
    }

    let userId: String
    let channelCid: String
    let createdBy: String?
    let removeFutureChannelsBan: Bool?
    let reason: String?

    init(
        userId: UserId,
        cid: ChannelId,
        createdBy: UserId? = nil,
        removeFutureChannelsBan: Bool? = nil,
        reason: String? = nil
    ) {
        self.userId = userId
        channelCid = cid.rawValue
        self.createdBy = createdBy
        self.removeFutureChannelsBan = removeFutureChannelsBan
        self.reason = reason
    }
}
