//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct MessageReadEvent: Codable, Hashable, Event {
    public var channelId: String
    public var channelType: String
    public var cid: String
    public var createdAt: Date
    public var type: String
    public var lastReadMessageId: String? = nil
    public var team: String? = nil
    public var user: UserObject? = nil

    public init(channelId: String, channelType: String, cid: String, createdAt: Date, type: String, lastReadMessageId: String? = nil, team: String? = nil, user: UserObject? = nil) {
        self.channelId = channelId
        self.channelType = channelType
        self.cid = cid
        self.createdAt = createdAt
        self.type = type
        self.lastReadMessageId = lastReadMessageId
        self.team = team
        self.user = user
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case channelId = "channel_id"
        case channelType = "channel_type"
        case cid
        case createdAt = "created_at"
        case type
        case lastReadMessageId = "last_read_message_id"
        case team
        case user
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(channelId, forKey: .channelId)
        try container.encode(channelType, forKey: .channelType)
        try container.encode(cid, forKey: .cid)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(type, forKey: .type)
        try container.encode(lastReadMessageId, forKey: .lastReadMessageId)
        try container.encode(team, forKey: .team)
        try container.encode(user, forKey: .user)
    }
}

extension MessageReadEvent: EventContainsCreationDate {}
extension MessageReadEvent: EventContainsUser {}
