//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ChannelHiddenEventDTO: Sendable, Event, Decodable {
    /// Represents channel in chat
    let channel: ChannelDetailPayload
    let channelCustom: [String: RawJSON]?
    /// The ID of the channel which was hidden
    let channelId: String?
    /// The number of members in the channel
    let channelMemberCount: Int?
    let channelMessageCount: Int?
    /// The type of the channel which was hidden
    let channelType: String?
    /// The CID of the channel which was hidden
    let cid: ChannelId
    /// Whether the history was cleared
    let clearHistory: Bool?
    /// Date/time of creation
    let createdAt: Date
    let custom: [String: RawJSON]
    let receivedAt: Date?
    /// The team ID
    let team: String?
    /// The type of event: "channel.hidden" in this case
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
        clearHistory: Bool? = nil,
        createdAt: Date,
        custom: [String: RawJSON],
        receivedAt: Date? = nil,
        team: String? = nil,
        type: String = "channel.hidden",
        user: UserPayload? = nil
    ) {
        self.channel = channel
        self.channelCustom = channelCustom
        self.channelId = channelId
        self.channelMemberCount = channelMemberCount
        self.channelMessageCount = channelMessageCount
        self.channelType = channelType
        self.cid = cid
        self.clearHistory = clearHistory
        self.createdAt = createdAt
        self.custom = custom
        self.receivedAt = receivedAt
        self.team = team
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
        case clearHistory = "clear_history"
        case createdAt = "created_at"
        case custom
        case receivedAt = "received_at"
        case team
        case type
        case user
    }
}
