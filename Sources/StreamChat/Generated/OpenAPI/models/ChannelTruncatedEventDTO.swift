//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ChannelTruncatedEventDTO: Sendable, Event, Decodable {
    /// Represents channel in chat
    let channel: ChannelDetailPayload
    let channelMessageCount: Int?
    /// Date/time of creation
    let createdAt: Date
    /// Represents any chat message
    let message: MessageResponse?
    /// The type of event: "channel.truncated" in this case
    let type: String
    let user: UserPayload?

    init(
        channel: ChannelDetailPayload,
        channelMessageCount: Int? = nil,
        createdAt: Date,
        message: MessageResponse? = nil,
        type: String = "channel.truncated",
        user: UserPayload? = nil
    ) {
        self.channel = channel
        self.channelMessageCount = channelMessageCount
        self.createdAt = createdAt
        self.message = message
        self.type = type
        self.user = user
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channel
        case channelMessageCount = "channel_message_count"
        case createdAt = "created_at"
        case message
        case type
        case user
    }
}
