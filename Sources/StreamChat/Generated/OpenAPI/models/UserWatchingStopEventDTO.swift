//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UserWatchingStopEventDTO: Sendable, Event, Decodable {
    /// The CID of the channel which the user stopped watching
    let cid: ChannelId
    /// Date/time of creation
    let createdAt: Date
    /// The type of event: "user.watching.stop" in this case
    let type: String
    let user: UserPayload
    /// The number of users watching the channel
    let watcherCount: Int

    init(
        cid: ChannelId,
        createdAt: Date,
        type: String = "user.watching.stop",
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
