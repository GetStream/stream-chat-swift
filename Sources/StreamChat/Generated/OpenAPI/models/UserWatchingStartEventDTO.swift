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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.cid = try container.decode(ChannelId.self, forKey: .cid)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.type = try container.decode(String.self, forKey: .type)
        self.user = try container.decode(UserPayload.self, forKey: .user)
        self.watcherCount = try container.decode(Int.self, forKey: .watcherCount)
    }
}
