//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A channel group returned by ``ChatClient/queryGroupedChannels(groups:limit:presence:watch:)``.
///
/// To observe and read the channels that belong to a group, create a
/// ``ChannelList`` with ``ChatClient/makeChannelList(with:)-(String)`` and read
/// ``ChannelListState/channels`` from its ``ChannelList/state``.
public struct ChannelGroup: Sendable {
    /// The group key as returned by the backend (e.g. `"all"`, `"new"`, `"old"`, `"current"`).
    public let groupKey: String

    /// The total unread channel count in the group.
    public let unreadChannels: Int

    /// Channels returned by the request.
    public let channels: [ChatChannel]
    
    let next: String?

    init(
        groupKey: String,
        channels: [ChatChannel],
        unreadChannels: Int,
        next: String? = nil
    ) {
        self.groupKey = groupKey
        self.channels = channels
        self.unreadChannels = unreadChannels
        self.next = next
    }
}

/// Constants used by the grouped channels feature.
enum GroupedChannelKey {
    /// Special group key whose list contains channels from every other group.
    static let all = "all"
    /// `ChatChannel.extraData` field that carries the channel's group membership.
    static let group = "group"
}
