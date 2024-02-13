//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct ChannelDeletedEvent: Codable, Hashable, Event {
    public var channelId: String
    public var channelType: String
    public var cid: String
    public var createdAt: Date
    public var type: String
    public var team: String? = nil
    public var channel: ChannelResponse? = nil

    public init(channelId: String, channelType: String, cid: String, createdAt: Date, type: String, team: String? = nil, channel: ChannelResponse? = nil) {
        self.channelId = channelId
        self.channelType = channelType
        self.cid = cid
        self.createdAt = createdAt
        self.type = type
        self.team = team
        self.channel = channel
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case channelId = "channel_id"
        case channelType = "channel_type"
        case cid
        case createdAt = "created_at"
        case type
        case team
        case channel
    }
}

extension ChannelDeletedEvent: EventContainsCreationDate {}
extension ChannelDeletedEvent: EventContainsChannel {}
