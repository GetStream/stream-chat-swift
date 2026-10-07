//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Emitted when a new reaction is added to a message.
final class ReactionNewEventDTO: Sendable, Event, Decodable {
    /// Represents channel in chat
    let channel: ChannelDetailPayload
    /// The number of messages in the channel
    let channelMessageCount: Int?
    /// The CID of the channel containing the message
    let cid: ChannelId
    /// Date/time of creation
    let createdAt: Date
    /// Represents any chat message
    let message: MessageResponse?
    let reaction: MessageReactionPayload?
    /// The type of event: "reaction.new" in this case
    let type: String
    let user: UserPayload?

    init(
        channel: ChannelDetailPayload,
        channelMessageCount: Int? = nil,
        cid: ChannelId,
        createdAt: Date,
        message: MessageResponse? = nil,
        reaction: MessageReactionPayload? = nil,
        type: String = "reaction.new",
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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.channel = try container.decode(ChannelDetailPayload.self, forKey: .channel)
        self.channelMessageCount = try container.decodeIfPresent(
            Int.self,
            forKey: .channelMessageCount
        )
        self.cid = try container.decode(ChannelId.self, forKey: .cid)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.message = try container.decodeIfPresent(MessageResponse.self, forKey: .message)
        self.reaction = try container.decodeIfPresent(MessageReactionPayload.self, forKey: .reaction)
        self.type = try container.decode(String.self, forKey: .type)
        self.user = try container.decodeIfPresent(UserPayload.self, forKey: .user)
    }
}
