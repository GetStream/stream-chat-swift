//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ReactionNewEventDTO: Sendable, Event, Decodable {
    /// Represents channel in chat
    let channel: ChannelDetailPayload
    let channelCustom: [String: RawJSON]?
    /// The ID of the channel containing the message
    let channelId: String?
    /// The number of members in the channel
    let channelMemberCount: Int?
    /// The number of messages in the channel
    let channelMessageCount: Int?
    /// The type of the channel containing the message
    let channelType: String?
    /// The CID of the channel containing the message
    let cid: ChannelId
    /// Date/time of creation
    let createdAt: Date
    let custom: [String: RawJSON]
    /// Represents any chat message
    let message: MessageResponse?
    let messageId: String?
    let reaction: MessageReactionPayload?
    let receivedAt: Date?
    /// The team ID
    let team: String?
    /// The participants of the thread
    let threadParticipants: [UserPayload]?
    /// The type of event: "reaction.new" in this case
    let type: String
    let user: UserPayload?

    init(
        channel: ChannelDetailPayload,
        channelCustom: [String: RawJSON]? = nil,
        channelId: String? = nil,
        channelMemberCount: Int? = nil,
        channelMessageCount: Int? = nil,
        channelType: String? = nil,
        cid: ChannelId,
        createdAt: Date,
        custom: [String: RawJSON],
        message: MessageResponse? = nil,
        messageId: String? = nil,
        reaction: MessageReactionPayload? = nil,
        receivedAt: Date? = nil,
        team: String? = nil,
        threadParticipants: [UserPayload]? = nil,
        type: String = "reaction.new",
        user: UserPayload? = nil
    ) {
        self.channel = channel
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
        self.reaction = reaction
        self.receivedAt = receivedAt
        self.team = team
        self.threadParticipants = threadParticipants
        self.type = type
        self.user = user
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channel
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
        case reaction
        case receivedAt = "received_at"
        case team
        case threadParticipants = "thread_participants"
        case type
        case user
    }
}
