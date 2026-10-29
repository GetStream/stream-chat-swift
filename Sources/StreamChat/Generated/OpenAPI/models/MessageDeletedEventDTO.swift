//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Emitted when a message is deleted.
final class MessageDeletedEventDTO: Sendable, Event, Decodable {
    /// The number of messages in the channel
    let channelMessageCount: Int?
    /// The CID of the channel where the message was sent
    let cid: ChannelId
    /// Date/time of creation
    let createdAt: Date
    /// Whether the message was deleted only for the current user
    let deletedForMe: Bool?
    /// Whether the message was hard deleted
    let hardDelete: Bool?
    /// Represents any chat message
    let message: MessageResponse
    /// The type of event: "message.deleted" in this case
    let type: String
    let user: UserPayload?

    init(
        channelMessageCount: Int? = nil,
        cid: ChannelId,
        createdAt: Date,
        deletedForMe: Bool? = nil,
        hardDelete: Bool? = nil,
        message: MessageResponse,
        type: String = "message.deleted",
        user: UserPayload? = nil
    ) {
        self.channelMessageCount = channelMessageCount
        self.cid = cid
        self.createdAt = createdAt
        self.deletedForMe = deletedForMe
        self.hardDelete = hardDelete
        self.message = message
        self.type = type
        self.user = user
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.channelMessageCount = try container.decodeIfPresent(
            Int.self,
            forKey: .channelMessageCount
        )
        self.cid = try container.decode(ChannelId.self, forKey: .cid)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.deletedForMe = try container.decodeIfPresent(Bool.self, forKey: .deletedForMe)
        self.hardDelete = try container.decodeIfPresent(Bool.self, forKey: .hardDelete)
        self.message = try container.decode(MessageResponse.self, forKey: .message)
        self.type = try container.decode(String.self, forKey: .type)
        self.user = try container.decodeIfPresent(UserPayload.self, forKey: .user)
    }
}
