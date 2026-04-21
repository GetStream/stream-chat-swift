//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ReactionDeletedEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    var channel: ChannelResponse
    var channelCustom: [String: RawJSON]?
    /// The ID of the channel containing the message
    var channelId: String?
    /// The number of members in the channel
    var channelMemberCount: Int?
    /// The number of messages in the channel
    var channelMessageCount: Int?
    /// The type of the channel containing the message
    var channelType: String?
    /// The CID of the channel containing the message
    var cid: String?
    /// Date/time of creation
    var createdAt: Date
    var custom: [String: RawJSON]
    var message: MessageResponse?
    var messageId: String?
    var reaction: ReactionResponse?
    var receivedAt: Date?
    /// The team ID
    var team: String?
    /// The participants of the thread
    var threadParticipants: [UserResponseCommonFields]?
    /// The type of event: "reaction.deleted" in this case
    var type: String = "reaction.deleted"
    var user: UserResponseCommonFields?

    init(channel: ChannelResponse, channelCustom: [String: RawJSON]? = nil, channelId: String? = nil, channelMemberCount: Int? = nil, channelMessageCount: Int? = nil, channelType: String? = nil, cid: String? = nil, createdAt: Date, custom: [String: RawJSON], message: MessageResponse? = nil, messageId: String? = nil, reaction: ReactionResponse? = nil, receivedAt: Date? = nil, team: String? = nil, threadParticipants: [UserResponseCommonFields]? = nil, user: UserResponseCommonFields? = nil) {
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

    static func == (lhs: ReactionDeletedEvent, rhs: ReactionDeletedEvent) -> Bool {
        lhs.channel == rhs.channel &&
            lhs.channelCustom == rhs.channelCustom &&
            lhs.channelId == rhs.channelId &&
            lhs.channelMemberCount == rhs.channelMemberCount &&
            lhs.channelMessageCount == rhs.channelMessageCount &&
            lhs.channelType == rhs.channelType &&
            lhs.cid == rhs.cid &&
            lhs.createdAt == rhs.createdAt &&
            lhs.custom == rhs.custom &&
            lhs.message == rhs.message &&
            lhs.messageId == rhs.messageId &&
            lhs.reaction == rhs.reaction &&
            lhs.receivedAt == rhs.receivedAt &&
            lhs.team == rhs.team &&
            lhs.threadParticipants == rhs.threadParticipants &&
            lhs.type == rhs.type &&
            lhs.user == rhs.user
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(channel)
        hasher.combine(channelCustom)
        hasher.combine(channelId)
        hasher.combine(channelMemberCount)
        hasher.combine(channelMessageCount)
        hasher.combine(channelType)
        hasher.combine(cid)
        hasher.combine(createdAt)
        hasher.combine(custom)
        hasher.combine(message)
        hasher.combine(messageId)
        hasher.combine(reaction)
        hasher.combine(receivedAt)
        hasher.combine(team)
        hasher.combine(threadParticipants)
        hasher.combine(type)
        hasher.combine(user)
    }
}
