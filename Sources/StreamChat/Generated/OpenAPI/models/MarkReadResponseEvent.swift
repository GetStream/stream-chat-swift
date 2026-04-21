//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class MarkReadResponseEvent: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var channel: ChannelResponse?
    var channelId: String
    var channelLastMessageAt: Date?
    var channelType: String
    var cid: String
    var createdAt: Date
    var lastReadMessageId: String?
    var team: String?
    var thread: ThreadResponse?
    var type: String
    var user: UserResponseCommonFields?

    init(channel: ChannelResponse? = nil, channelId: String, channelLastMessageAt: Date? = nil, channelType: String, cid: String, createdAt: Date, lastReadMessageId: String? = nil, team: String? = nil, thread: ThreadResponse? = nil, type: String, user: UserResponseCommonFields? = nil) {
        self.channel = channel
        self.channelId = channelId
        self.channelLastMessageAt = channelLastMessageAt
        self.channelType = channelType
        self.cid = cid
        self.createdAt = createdAt
        self.lastReadMessageId = lastReadMessageId
        self.team = team
        self.thread = thread
        self.type = type
        self.user = user
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channel
        case channelId = "channel_id"
        case channelLastMessageAt = "channel_last_message_at"
        case channelType = "channel_type"
        case cid
        case createdAt = "created_at"
        case lastReadMessageId = "last_read_message_id"
        case team
        case thread
        case type
        case user
    }

    static func == (lhs: MarkReadResponseEvent, rhs: MarkReadResponseEvent) -> Bool {
        lhs.channel == rhs.channel &&
            lhs.channelId == rhs.channelId &&
            lhs.channelLastMessageAt == rhs.channelLastMessageAt &&
            lhs.channelType == rhs.channelType &&
            lhs.cid == rhs.cid &&
            lhs.createdAt == rhs.createdAt &&
            lhs.lastReadMessageId == rhs.lastReadMessageId &&
            lhs.team == rhs.team &&
            lhs.thread == rhs.thread &&
            lhs.type == rhs.type &&
            lhs.user == rhs.user
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(channel)
        hasher.combine(channelId)
        hasher.combine(channelLastMessageAt)
        hasher.combine(channelType)
        hasher.combine(cid)
        hasher.combine(createdAt)
        hasher.combine(lastReadMessageId)
        hasher.combine(team)
        hasher.combine(thread)
        hasher.combine(type)
        hasher.combine(user)
    }
}
