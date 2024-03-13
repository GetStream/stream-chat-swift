//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct ThreadUpdatedEvent: Codable, Hashable, Event {
    public var channelId: String
    public var channelType: String
    public var cid: String
    public var createdAt: Date
    public var type: String
    public var thread: Thread? = nil
    public var user: UserObject? = nil

    public init(channelId: String, channelType: String, cid: String, createdAt: Date, type: String, thread: Thread? = nil, user: UserObject? = nil) {
        self.channelId = channelId
        self.channelType = channelType
        self.cid = cid
        self.createdAt = createdAt
        self.type = type
        self.thread = thread
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case channelId = "channel_id"
        case channelType = "channel_type"
        case cid
        case createdAt = "created_at"
        case type
        case thread
        case user
    }
}

extension ThreadUpdatedEvent: EventContainsCid {}
extension ThreadUpdatedEvent: EventContainsCreationDate {}
extension ThreadUpdatedEvent: EventContainsUser {}
