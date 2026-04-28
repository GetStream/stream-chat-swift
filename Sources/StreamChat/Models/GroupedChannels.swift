//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A grouped channels response returned by `ChatClient.queryGroupedChannels`.
public struct GroupedChannels: Equatable, Sendable {
    /// The grouped channel groups returned by the backend, keyed by group name.
    public let groups: [String: GroupedChannelsGroup]

    init(
        groups: [String: GroupedChannelsGroup]
    ) {
        self.groups = groups
    }
}

/// A grouped channels group returned by `ChatClient.queryGroupedChannels`.
public struct GroupedChannelsGroup: Equatable, Sendable {
    /// The group key as returned by the backend (e.g. `"all"`, `"new"`, `"current"`).
    public let groupKey: String

    /// The channels that belong to this group.
    public let channels: [ChatChannel]

    /// The total unread channel count in the group.
    public let unreadChannels: Int

    init(
        groupKey: String,
        channels: [ChatChannel],
        unreadChannels: Int
    ) {
        self.groupKey = groupKey
        self.channels = channels
        let derivedUnreadChannels = channels.reduce(into: 0) { partialResult, channel in
            if channel.unreadCount.messages > 0 {
                partialResult += 1
            }
        }

        self.unreadChannels = max(unreadChannels, derivedUnreadChannels)
    }
}
