//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct UserWatchingStartEvent: Codable, Hashable, Event {
    public var channelId: String
    public var channelType: String
    public var cid: String
    public var createdAt: Date
    public var type: String
    public var watcherCount: Int
    public var team: String? = nil
    public var user: UserObject? = nil

    public init(channelId: String, channelType: String, cid: String, createdAt: Date, type: String, watcherCount: Int, team: String? = nil, user: UserObject? = nil) {
        self.channelId = channelId
        self.channelType = channelType
        self.cid = cid
        self.createdAt = createdAt
        self.type = type
        self.watcherCount = watcherCount
        self.team = team
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case channelId = "channel_id"
        case channelType = "channel_type"
        case cid
        case createdAt = "created_at"
        case type
        case watcherCount = "watcher_count"
        case team
        case user
    }
}

extension UserWatchingStartEvent: EventContainsCid {}
extension UserWatchingStartEvent: EventContainsCreationDate {}
extension UserWatchingStartEvent: EventContainsUser {}
