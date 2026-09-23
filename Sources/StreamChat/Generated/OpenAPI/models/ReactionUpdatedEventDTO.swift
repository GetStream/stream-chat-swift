//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ReactionUpdatedEventDTO: Sendable, Event, Decodable {
    /// Represents channel in chat
    let channel: ChannelDetailPayload
    /// The number of messages in the channel
    let channelMessageCount: Int?
    /// The CID of the channel containing the message
    let cid: ChannelId
    /// Date/time of creation
    let createdAt: Date
    /// Represents any chat message
    let message: MessageResponse
    let reaction: MessageReactionPayload?
    /// The type of event: "reaction.updated" in this case
    let type: String
    let user: UserPayload?

    init(
        channel: ChannelDetailPayload,
        channelMessageCount: Int? = nil,
        cid: ChannelId,
        createdAt: Date,
        message: MessageResponse,
        reaction: MessageReactionPayload? = nil,
        type: String = "reaction.updated",
        user: UserPayload? = nil
    ) {
        self.channel = channel
        self.channelMessageCount = channelMessageCount
        self.cid = cid
        self.createdAt = createdAt
        self.message = message
        self.reaction = reaction
        self.type = type
        self.user = user
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channel
        case channelMessageCount = "channel_message_count"
        case cid
        case createdAt = "created_at"
        case message
        case reaction
        case type
        case user
    }
}
