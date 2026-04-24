//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ChannelHiddenEventModel: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    var channel: ChannelResponse
    var channelCustom: [String: RawJSON]?
    /// The ID of the channel which was hidden
    var channelId: String?
    /// The number of members in the channel
    var channelMemberCount: Int?
    var channelMessageCount: Int?
    /// The type of the channel which was hidden
    var channelType: String?
    /// The CID of the channel which was hidden
    var cid: String?
    /// Whether the history was cleared
    var clearHistory: Bool
    /// Date/time of creation
    var createdAt: Date
    var custom: [String: RawJSON]
    var receivedAt: Date?
    /// The team ID
    var team: String?
    /// The type of event: "channel.hidden" in this case
    var type: String = "channel.hidden"
    var user: UserResponseCommonFields?

    init(channel: ChannelResponse, channelCustom: [String: RawJSON]? = nil, channelId: String? = nil, channelMemberCount: Int? = nil, channelMessageCount: Int? = nil, channelType: String? = nil, cid: String? = nil, clearHistory: Bool, createdAt: Date, custom: [String: RawJSON], receivedAt: Date? = nil, team: String? = nil, user: UserResponseCommonFields? = nil) {
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

    static func == (lhs: ChannelHiddenEventModel, rhs: ChannelHiddenEventModel) -> Bool {
        lhs.channel == rhs.channel &&
            lhs.channelCustom == rhs.channelCustom &&
            lhs.channelId == rhs.channelId &&
            lhs.channelMemberCount == rhs.channelMemberCount &&
            lhs.channelMessageCount == rhs.channelMessageCount &&
            lhs.channelType == rhs.channelType &&
            lhs.cid == rhs.cid &&
            lhs.clearHistory == rhs.clearHistory &&
            lhs.createdAt == rhs.createdAt &&
            lhs.custom == rhs.custom &&
            lhs.receivedAt == rhs.receivedAt &&
            lhs.team == rhs.team &&
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
        hasher.combine(clearHistory)
        hasher.combine(createdAt)
        hasher.combine(custom)
        hasher.combine(receivedAt)
        hasher.combine(team)
        hasher.combine(type)
        hasher.combine(user)
    }
}
