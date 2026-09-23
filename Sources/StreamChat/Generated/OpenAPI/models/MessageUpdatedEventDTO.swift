//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class MessageUpdatedEventDTO: Sendable, Event, Decodable {
    /// The number of messages in the channel
    let channelMessageCount: Int?
    /// The CID of the channel where the message was sent
    let cid: ChannelId
    /// Date/time of creation
    let createdAt: Date
    /// Represents any chat message
    let message: MessageResponse
    /// The type of event: "message.updated" in this case
    let type: String
    let user: UserPayload?

    init(
        channelMessageCount: Int? = nil,
        cid: ChannelId,
        createdAt: Date,
        message: MessageResponse,
        type: String = "message.updated",
        user: UserPayload? = nil
    ) {
        self.channelMessageCount = channelMessageCount
        self.cid = cid
        self.createdAt = createdAt
        self.message = message
        self.type = type
        self.user = user
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channelMessageCount = "channel_message_count"
        case cid
        case createdAt = "created_at"
        case message
        case type
        case user
    }
}
