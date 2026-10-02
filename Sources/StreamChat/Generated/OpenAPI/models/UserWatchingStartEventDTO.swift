//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// This event is sent when a user starts watching a channel. The event contains information about the user that started watching the channel.
final class UserWatchingStartEventDTO: Sendable, Event, Decodable {
    /// The CID of the channel which the user started watching
    let cid: ChannelId
    /// Date/time of creation
    let createdAt: Date
    /// The type of event: "user.watching.start" in this case
    let type: String
    let user: UserPayload
    /// The number of users watching the channel
    let watcherCount: Int

    init(
        cid: ChannelId,
        createdAt: Date,
        type: String = "user.watching.start",
        user: UserPayload,
        watcherCount: Int
    ) {
        self.cid = cid
        self.createdAt = createdAt
        self.type = type
        self.user = user
        self.watcherCount = watcherCount
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case cid
        case createdAt = "created_at"
        case type
        case user
        case watcherCount = "watcher_count"
    }
}
