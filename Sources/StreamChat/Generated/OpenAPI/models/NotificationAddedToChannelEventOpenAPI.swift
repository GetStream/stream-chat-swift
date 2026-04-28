//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class NotificationAddedToChannelEventOpenAPI: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    var channel: ChannelResponse
    var channelCustom: [String: RawJSON]?
    /// The ID of the channel to which the user was added
    var channelId: String?
    var channelMemberCount: Int?
    var channelMessageCount: Int?
    /// The type of the channel to which the user was added
    var channelType: String?
    /// The CID of the channel to which the user was added
    var cid: String?
    /// Date/time of creation
    var createdAt: Date
    var custom: [String: RawJSON]
    var member: ChannelMemberResponse
    var receivedAt: Date?
    /// The team ID
    var team: String?
    /// The type of event: "notification.added_to_channel" in this case
    var type: String = "notification.added_to_channel"

    init(channel: ChannelResponse, channelCustom: [String: RawJSON]? = nil, channelId: String? = nil, channelMemberCount: Int? = nil, channelMessageCount: Int? = nil, channelType: String? = nil, cid: String? = nil, createdAt: Date, custom: [String: RawJSON], member: ChannelMemberResponse, receivedAt: Date? = nil, team: String? = nil) {
        self.channel = channel
        self.channelCustom = channelCustom
        self.channelId = channelId
        self.channelMemberCount = channelMemberCount
        self.channelMessageCount = channelMessageCount
        self.channelType = channelType
        self.cid = cid
        self.createdAt = createdAt
        self.custom = custom
        self.member = member
        self.receivedAt = receivedAt
        self.team = team
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
        case member
        case receivedAt = "received_at"
        case team
        case type
    }

    static func == (lhs: NotificationAddedToChannelEventOpenAPI, rhs: NotificationAddedToChannelEventOpenAPI) -> Bool {
        lhs.channel == rhs.channel &&
            lhs.channelCustom == rhs.channelCustom &&
            lhs.channelId == rhs.channelId &&
            lhs.channelMemberCount == rhs.channelMemberCount &&
            lhs.channelMessageCount == rhs.channelMessageCount &&
            lhs.channelType == rhs.channelType &&
            lhs.cid == rhs.cid &&
            lhs.createdAt == rhs.createdAt &&
            lhs.custom == rhs.custom &&
            lhs.member == rhs.member &&
            lhs.receivedAt == rhs.receivedAt &&
            lhs.team == rhs.team &&
            lhs.type == rhs.type
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
        hasher.combine(member)
        hasher.combine(receivedAt)
        hasher.combine(team)
        hasher.combine(type)
    }
}
