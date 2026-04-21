//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UserWatchingStopEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    /// The ID of the channel which the user stopped watching
    var channelId: String?
    /// The type of the channel which the user stopped watching
    var channelType: String?
    /// The CID of the channel which the user stopped watching
    var cid: String?
    /// Date/time of creation
    var createdAt: Date
    var custom: [String: RawJSON]
    var receivedAt: Date?
    /// The type of event: "user.watching.stop" in this case
    var type: String = "user.watching.stop"
    var user: UserResponseCommonFields
    /// The number of users watching the channel
    var watcherCount: Int

    init(channelId: String? = nil, channelType: String? = nil, cid: String? = nil, createdAt: Date, custom: [String: RawJSON], receivedAt: Date? = nil, user: UserResponseCommonFields, watcherCount: Int) {
        self.channelId = channelId
        self.channelType = channelType
        self.cid = cid
        self.createdAt = createdAt
        self.custom = custom
        self.receivedAt = receivedAt
        self.user = user
        self.watcherCount = watcherCount
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channelId = "channel_id"
        case channelType = "channel_type"
        case cid
        case createdAt = "created_at"
        case custom
        case receivedAt = "received_at"
        case type
        case user
        case watcherCount = "watcher_count"
    }

    static func == (lhs: UserWatchingStopEvent, rhs: UserWatchingStopEvent) -> Bool {
        lhs.channelId == rhs.channelId &&
            lhs.channelType == rhs.channelType &&
            lhs.cid == rhs.cid &&
            lhs.createdAt == rhs.createdAt &&
            lhs.custom == rhs.custom &&
            lhs.receivedAt == rhs.receivedAt &&
            lhs.type == rhs.type &&
            lhs.user == rhs.user &&
            lhs.watcherCount == rhs.watcherCount
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(channelId)
        hasher.combine(channelType)
        hasher.combine(cid)
        hasher.combine(createdAt)
        hasher.combine(custom)
        hasher.combine(receivedAt)
        hasher.combine(type)
        hasher.combine(user)
        hasher.combine(watcherCount)
    }
}
