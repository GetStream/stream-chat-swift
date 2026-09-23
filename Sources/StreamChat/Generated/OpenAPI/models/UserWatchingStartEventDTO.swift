//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UserWatchingStartEventDTO: Sendable, Event, Decodable {
    /// The ID of the channel which the user started watching
    let channelId: String?
    /// The type of the channel which the user started watching
    let channelType: String?
    /// The CID of the channel which the user started watching
    let cid: ChannelId
    /// Date/time of creation
    let createdAt: Date
    let custom: [String: RawJSON]
    let receivedAt: Date?
    /// The type of event: "user.watching.start" in this case
    let type: String
    let user: UserPayload
    /// The number of users watching the channel
    let watcherCount: Int

    init(
        channelId: String? = nil,
        channelType: String? = nil,
        cid: ChannelId,
        createdAt: Date,
        custom: [String: RawJSON],
        receivedAt: Date? = nil,
        type: String = "user.watching.start",
        user: UserPayload,
        watcherCount: Int
    ) {
        self.channelId = channelId
        self.channelType = channelType
        self.cid = cid
        self.createdAt = createdAt
        self.custom = custom
        self.receivedAt = receivedAt
        self.type = type
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
}
