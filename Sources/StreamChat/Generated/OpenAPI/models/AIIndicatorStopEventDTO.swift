//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class AIIndicatorStopEventDTO: Sendable, Event, Decodable {
    /// The CID of the channel
    let cid: ChannelId?
    /// Date/time of creation
    let createdAt: Date
    /// The type of event: "ai_indicator.stop" in this case
    let type: String

    init(cid: ChannelId? = nil, createdAt: Date, type: String = "ai_indicator.stop") {
        self.cid = cid
        self.createdAt = createdAt
        self.type = type
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case cid
        case createdAt = "created_at"
        case type
    }
}
