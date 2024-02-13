//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct NotificationNewMessageEvent: Codable, Hashable, Event {
    public var channelId: String
    public var channelType: String
    public var cid: String
    public var createdAt: Date
    public var type: String
    public var message: Message
    public var team: String? = nil
    public var channel: ChannelResponse? = nil

    public init(channelId: String, channelType: String, cid: String, createdAt: Date, type: String, message: Message, team: String? = nil, channel: ChannelResponse? = nil) {
        self.channelId = channelId
        self.channelType = channelType
        self.cid = cid
        self.createdAt = createdAt
        self.type = type
        self.message = message
        self.team = team
        self.channel = channel
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case channelId = "channel_id"
        case channelType = "channel_type"
        case cid
        case createdAt = "created_at"
        case type
        case message
        case team
        case channel
    }
}

extension NotificationNewMessageEvent: EventContainsCreationDate {}
extension NotificationNewMessageEvent: EventContainsChannel {}
