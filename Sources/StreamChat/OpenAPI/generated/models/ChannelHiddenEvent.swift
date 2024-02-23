//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct ChannelHiddenEvent: Codable, Hashable, Event {
    public var channelId: String
    public var channelType: String
    public var cid: String
    public var clearHistory: Bool
    public var createdAt: Date
    public var type: String
    public var channel: ChannelResponse? = nil
    public var user: UserObject? = nil

    public init(channelId: String, channelType: String, cid: String, clearHistory: Bool, createdAt: Date, type: String, channel: ChannelResponse? = nil, user: UserObject? = nil) {
        self.channelId = channelId
        self.channelType = channelType
        self.cid = cid
        self.clearHistory = clearHistory
        self.createdAt = createdAt
        self.type = type
        self.channel = channel
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case channelId = "channel_id"
        case channelType = "channel_type"
        case cid
        case clearHistory = "clear_history"
        case createdAt = "created_at"
        case type
        case channel
        case user
    }
}

extension ChannelHiddenEvent: EventContainsCid {}
extension ChannelHiddenEvent: EventContainsCreationDate {}
extension ChannelHiddenEvent: EventContainsChannel {}
extension ChannelHiddenEvent: EventContainsUser {}
