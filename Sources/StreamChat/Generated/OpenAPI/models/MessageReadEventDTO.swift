//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class MessageReadEventDTO: Sendable, Event, Decodable {
    /// Represents channel in chat
    let channel: ChannelDetailPayload?
    let channelCustom: [String: RawJSON]?
    /// The ID of the channel where the message was read
    let channelId: String?
    /// The number of members in the channel
    let channelMemberCount: Int?
    /// The number of messages in the channel
    let channelMessageCount: Int?
    /// The type of the channel where the message was read
    let channelType: String?
    /// The CID of the channel where the message was read
    let cid: ChannelId
    /// Date/time of creation
    let createdAt: Date
    let custom: [String: RawJSON]
    /// The ID of the last read message
    let lastReadMessageId: String?
    let receivedAt: Date?
    /// The team ID
    let team: String?
    let thread: ThreadResponse?
    /// The type of event: "message.read" in this case
    let type: String
    let user: UserPayload?

    init(
        channel: ChannelDetailPayload? = nil,
        channelCustom: [String: RawJSON]? = nil,
        channelId: String? = nil,
        channelMemberCount: Int? = nil,
        channelMessageCount: Int? = nil,
        channelType: String? = nil,
        cid: ChannelId,
        createdAt: Date,
        custom: [String: RawJSON],
        lastReadMessageId: String? = nil,
        receivedAt: Date? = nil,
        team: String? = nil,
        thread: ThreadResponse? = nil,
        type: String = "message.read",
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
        self.lastReadMessageId = lastReadMessageId
        self.receivedAt = receivedAt
        self.team = team
        self.thread = thread
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
        case lastReadMessageId = "last_read_message_id"
        case receivedAt = "received_at"
        case team
        case thread
        case type
        case user
    }
}
