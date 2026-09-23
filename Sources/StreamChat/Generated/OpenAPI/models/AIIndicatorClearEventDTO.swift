//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class AIIndicatorClearEventDTO: Sendable, Event, Decodable {
    /// The ID of the channel
    let channelId: String?
    /// The type of the channel
    let channelType: String?
    /// The CID of the channel
    let cid: ChannelId?
    /// Date/time of creation
    let createdAt: Date
    let custom: [String: RawJSON]
    let receivedAt: Date?
    /// The type of event: "ai_indicator.clear" in this case
    let type: String

    init(
        channelId: String? = nil,
        channelType: String? = nil,
        cid: ChannelId? = nil,
        createdAt: Date,
        custom: [String: RawJSON],
        receivedAt: Date? = nil,
        type: String = "ai_indicator.clear"
    ) {
        self.channelId = channelId
        self.channelType = channelType
        self.cid = cid
        self.createdAt = createdAt
        self.custom = custom
        self.receivedAt = receivedAt
        self.type = type
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channelId = "channel_id"
        case channelType = "channel_type"
        case cid
        case createdAt = "created_at"
        case custom
        case receivedAt = "received_at"
        case type
    }
}
