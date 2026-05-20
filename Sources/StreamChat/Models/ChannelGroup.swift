//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A channel group returned by ``ChatClient/queryGroupedChannels(limit:presence:watch:)``.
///
/// To observe and read the channels that belong to a group, create a
/// ``ChannelList`` with ``ChatClient/makeChannelList(with:)-(String)`` and read
/// ``ChannelListState/channels`` from its ``ChannelList/state``:
///
/// ```swift
/// let channelList = client.makeChannelList(with: group.groupKey)
/// try await channelList.get()
/// let channels = await channelList.state.channels
/// ```
public struct ChannelGroup: Sendable {
    /// The group key as returned by the backend (e.g. `"all"`, `"new"`, `"current"`).
    public let groupKey: String

    /// The total unread channel count in the group.
    public let unreadChannels: Int

    /// The channel ids returned for the group in the order produced by the backend.
    public let channelIds: [ChannelId]
    
    let next: String?

    init(
        groupKey: String,
        channelIds: [ChannelId],
        unreadChannels: Int,
        next: String? = nil
    ) {
        self.groupKey = groupKey
        self.channelIds = channelIds
        self.unreadChannels = unreadChannels
        self.next = next
    }
}

struct GroupedChannelsPagination: Sendable {
    let groupKey: String
    let next: String?
}
