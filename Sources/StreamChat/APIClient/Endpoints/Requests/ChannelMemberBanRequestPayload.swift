//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// The type describes the outgoing JSON to `moderation/ban` endpoint
struct ChannelMemberBanRequestPayload: Encodable {
    private enum CodingKeys: String, CodingKey {
        case userId = "target_user_id"
        case channelType = "type"
        case channelId = "id"
        case timeoutInMinutes = "timeout"
        case reason
        case shadow
    }

    let userId: String
    let channelType: ChannelType
    let channelId: String
    let shadow: Bool
    let timeoutInMinutes: Int?
    let reason: String?

    init(
        userId: UserId,
        cid: ChannelId,
        shadow: Bool,
        timeoutInMinutes: Int? = nil,
        reason: String? = nil
    ) {
        self.userId = userId
        channelType = cid.type
        channelId = cid.id
        self.shadow = shadow
        self.timeoutInMinutes = timeoutInMinutes
        self.reason = reason
    }
}
