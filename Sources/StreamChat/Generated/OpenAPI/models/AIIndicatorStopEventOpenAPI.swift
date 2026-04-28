//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class AIIndicatorStopEventOpenAPI: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    /// The ID of the channel
    var channelId: String?
    /// The type of the channel
    var channelType: String?
    /// The CID of the channel
    var cid: String?
    /// Date/time of creation
    var createdAt: Date
    var custom: [String: RawJSON]
    var receivedAt: Date?
    /// The type of event: "ai_indicator.stop" in this case
    var type: String = "ai_indicator.stop"

    init(channelId: String? = nil, channelType: String? = nil, cid: String? = nil, createdAt: Date, custom: [String: RawJSON], receivedAt: Date? = nil) {
        self.channelId = channelId
        self.channelType = channelType
        self.cid = cid
        self.createdAt = createdAt
        self.custom = custom
        self.receivedAt = receivedAt
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

    static func == (lhs: AIIndicatorStopEventOpenAPI, rhs: AIIndicatorStopEventOpenAPI) -> Bool {
        lhs.channelId == rhs.channelId &&
            lhs.channelType == rhs.channelType &&
            lhs.cid == rhs.cid &&
            lhs.createdAt == rhs.createdAt &&
            lhs.custom == rhs.custom &&
            lhs.receivedAt == rhs.receivedAt &&
            lhs.type == rhs.type
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(channelId)
        hasher.combine(channelType)
        hasher.combine(cid)
        hasher.combine(createdAt)
        hasher.combine(custom)
        hasher.combine(receivedAt)
        hasher.combine(type)
    }
}
