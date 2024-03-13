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
    public var thread: Thread? = nil
    public var user: UserObject? = nil

    public init(channelId: String, channelType: String, cid: String, createdAt: Date, type: String, lastReadMessageId: String? = nil, team: String? = nil, thread: Thread? = nil, user: UserObject? = nil) {
        self.channelId = channelId
        self.channelType = channelType
        self.cid = cid
        self.createdAt = createdAt
        self.type = type
        self.lastReadMessageId = lastReadMessageId
        self.team = team
        self.thread = thread
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
        case thread
        case user
    }
}

extension MessageReadEvent: EventContainsCid {}
extension MessageReadEvent: EventContainsCreationDate {}
extension MessageReadEvent: EventContainsUser {}
