//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct NotificationInvitedEvent: Codable, Hashable, Event {
    public var channelId: String
    public var channelType: String
    public var cid: String
    public var createdAt: Date
    public var type: String
    public var channel: ChannelResponse? = nil
    public var member: ChannelMember? = nil
    public var user: UserObject? = nil

    public init(channelId: String, channelType: String, cid: String, createdAt: Date, type: String, channel: ChannelResponse? = nil, member: ChannelMember? = nil, user: UserObject? = nil) {
        self.channelId = channelId
        self.channelType = channelType
        self.cid = cid
        self.createdAt = createdAt
        self.type = type
        self.channel = channel
        self.member = member
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case channelId = "channel_id"
        case channelType = "channel_type"
        case cid
        case createdAt = "created_at"
        case type
        case channel
        case member
        case user
    }
}

extension NotificationInvitedEvent: EventContainsCreationDate {}
extension NotificationInvitedEvent: EventContainsChannel {}
extension NotificationInvitedEvent: EventContainsUser {}
