//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class MessageUpdatedEventDTO: Sendable, Event, Decodable {
    let channelCustom: [String: RawJSON]?
    /// The ID of the channel where the message was sent
    let channelId: String?
    /// The number of members in the channel
    let channelMemberCount: Int?
    /// The number of messages in the channel
    let channelMessageCount: Int?
    /// The type of the channel where the message was sent
    let channelType: String?
    /// The CID of the channel where the message was sent
    let cid: ChannelId
    /// Date/time of creation
    let createdAt: Date
    let custom: [String: RawJSON]
    /// Represents any chat message
    let message: MessageResponse
    let messageId: String?
    let messageUpdate: MessageUpdate?
    let receivedAt: Date?
    /// The team ID
    let team: String?
    /// The type of event: "message.updated" in this case
    let type: String
    let user: UserPayload?

    init(
        channelCustom: [String: RawJSON]? = nil,
        channelId: String? = nil,
        channelMemberCount: Int? = nil,
        channelMessageCount: Int? = nil,
        channelType: String? = nil,
        cid: ChannelId,
        createdAt: Date,
        custom: [String: RawJSON],
        message: MessageResponse,
        messageId: String? = nil,
        messageUpdate: MessageUpdate? = nil,
        receivedAt: Date? = nil,
        team: String? = nil,
        type: String = "message.updated",
        user: UserPayload? = nil
    ) {
        self.channelCustom = channelCustom
        self.channelId = channelId
        self.channelMemberCount = channelMemberCount
        self.channelMessageCount = channelMessageCount
        self.channelType = channelType
        self.cid = cid
        self.createdAt = createdAt
        self.custom = custom
        self.message = message
        self.messageId = messageId
        self.messageUpdate = messageUpdate
        self.receivedAt = receivedAt
        self.team = team
        self.type = type
        self.user = user
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channelCustom = "channel_custom"
        case channelId = "channel_id"
        case channelMemberCount = "channel_member_count"
        case channelMessageCount = "channel_message_count"
        case channelType = "channel_type"
        case cid
        case createdAt = "created_at"
        case custom
        case message
        case messageId = "message_id"
        case messageUpdate = "message_update"
        case receivedAt = "received_at"
        case team
        case type
        case user
    }
}
