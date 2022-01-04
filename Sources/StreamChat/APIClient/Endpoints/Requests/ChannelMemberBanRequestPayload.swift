//
// Copyright © 2022 Stream.io Inc. All rights reserved.
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
    }
    
    let userId: String
    let channelType: ChannelType
    let channelId: String
    let timeoutInMinutes: Int?
    let reason: String?
    
    init(
        userId: UserId,
        cid: ChannelId,
        timeoutInMinutes: Int? = nil,
        reason: String? = nil
    ) {
        self.userId = userId
        channelType = cid.type
        channelId = cid.id
        self.timeoutInMinutes = timeoutInMinutes
        self.reason = reason
    }
}
