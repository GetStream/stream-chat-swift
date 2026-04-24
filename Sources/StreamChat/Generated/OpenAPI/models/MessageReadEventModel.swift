//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class MessageReadEventModel: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    var channel: ChannelResponse?
    var channelCustom: [String: RawJSON]?
    /// The ID of the channel where the message was read
    var channelId: String?
    /// The number of members in the channel
    var channelMemberCount: Int?
    /// The number of messages in the channel
    var channelMessageCount: Int?
    /// The type of the channel where the message was read
    var channelType: String?
    /// The CID of the channel where the message was read
    var cid: String?
    /// Date/time of creation
    var createdAt: Date
    var custom: [String: RawJSON]
    /// The ID of the last read message
    var lastReadMessageId: String?
    var receivedAt: Date?
    /// The team ID
    var team: String?
    var thread: ThreadResponse?
    /// The type of event: "message.read" in this case
    var type: String = "message.read"
    var user: UserResponseCommonFields?

    init(channel: ChannelResponse? = nil, channelCustom: [String: RawJSON]? = nil, channelId: String? = nil, channelMemberCount: Int? = nil, channelMessageCount: Int? = nil, channelType: String? = nil, cid: String? = nil, createdAt: Date, custom: [String: RawJSON], lastReadMessageId: String? = nil, receivedAt: Date? = nil, team: String? = nil, thread: ThreadResponse? = nil, user: UserResponseCommonFields? = nil) {
        self.channel = channel
        self.channelCustom = channelCustom
        self.channelId = channelId
        self.channelMemberCount = channelMemberCount
        self.channelMessageCount = channelMessageCount
        self.channelType = channelType
        self.cid = cid
        self.createdAt = createdAt
        self.custom = custom
        self.lastReadMessageId = lastReadMessageId
        self.receivedAt = receivedAt
        self.team = team
        self.thread = thread
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
        case lastReadMessageId = "last_read_message_id"
        case receivedAt = "received_at"
        case team
        case thread
        case type
        case user
    }

    static func == (lhs: MessageReadEventModel, rhs: MessageReadEventModel) -> Bool {
        lhs.channel == rhs.channel &&
            lhs.channelCustom == rhs.channelCustom &&
            lhs.channelId == rhs.channelId &&
            lhs.channelMemberCount == rhs.channelMemberCount &&
            lhs.channelMessageCount == rhs.channelMessageCount &&
            lhs.channelType == rhs.channelType &&
            lhs.cid == rhs.cid &&
            lhs.createdAt == rhs.createdAt &&
            lhs.custom == rhs.custom &&
            lhs.lastReadMessageId == rhs.lastReadMessageId &&
            lhs.receivedAt == rhs.receivedAt &&
            lhs.team == rhs.team &&
            lhs.thread == rhs.thread &&
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
        hasher.combine(lastReadMessageId)
        hasher.combine(receivedAt)
        hasher.combine(team)
        hasher.combine(thread)
        hasher.combine(type)
        hasher.combine(user)
    }
}
