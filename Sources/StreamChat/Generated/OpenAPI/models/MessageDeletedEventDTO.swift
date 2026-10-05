//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

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

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channelMessageCount = "channel_message_count"
        case cid
        case createdAt = "created_at"
        case deletedForMe = "deleted_for_me"
        case hardDelete = "hard_delete"
        case message
        case type
        case user
    }
}
