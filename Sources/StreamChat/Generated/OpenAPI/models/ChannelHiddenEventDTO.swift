//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ChannelHiddenEventDTO: Sendable, Event, Decodable {
    /// Represents channel in chat
    let channel: ChannelDetailPayload
    /// The CID of the channel which was hidden
    let cid: ChannelId
    /// Whether the history was cleared
    let clearHistory: Bool?
    /// Date/time of creation
    let createdAt: Date
    /// The type of event: "channel.hidden" in this case
    let type: String
    let user: UserPayload?

    init(
        channel: ChannelDetailPayload,
        cid: ChannelId,
        clearHistory: Bool? = nil,
        createdAt: Date,
        type: String = "channel.hidden",
        user: UserPayload? = nil
    ) {
        self.channel = channel
        self.cid = cid
        self.clearHistory = clearHistory
        self.createdAt = createdAt
        self.type = type
        self.user = user
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channel
        case cid
        case clearHistory = "clear_history"
        case createdAt = "created_at"
        case type
        case user
    }
}
