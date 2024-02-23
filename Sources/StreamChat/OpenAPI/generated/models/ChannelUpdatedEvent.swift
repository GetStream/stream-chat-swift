//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct ChannelUpdatedEvent: Codable, Hashable, Event {
    public var channelId: String
    public var channelType: String
    public var cid: String
    public var createdAt: Date
    public var type: String
    public var team: String? = nil
    public var channel: ChannelResponse? = nil
    public var message: Message? = nil
    public var user: UserObject? = nil

    public init(channelId: String, channelType: String, cid: String, createdAt: Date, type: String, team: String? = nil, channel: ChannelResponse? = nil, message: Message? = nil, user: UserObject? = nil) {
        self.channelId = channelId
        self.channelType = channelType
        self.cid = cid
        self.createdAt = createdAt
        self.type = type
        self.team = team
        self.channel = channel
        self.message = message
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case channelId = "channel_id"
        case channelType = "channel_type"
        case cid
        case createdAt = "created_at"
        case type
        case team
        case channel
        case message
        case user
    }
}

extension ChannelUpdatedEvent: EventContainsCid {}
extension ChannelUpdatedEvent: EventContainsCreationDate {}
extension ChannelUpdatedEvent: EventContainsChannel {}
extension ChannelUpdatedEvent: EventContainsOptionalMessage {}
extension ChannelUpdatedEvent: EventContainsUser {}
