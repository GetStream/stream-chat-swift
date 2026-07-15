//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

// The properties below mirror the pre-OpenAPI public API. They should be
// deprecated with `@available(*, deprecated, renamed:)` in the next major version (6).

public extension CurrentUserUnreads {
    /// The total number of unread messages.
    var totalUnreadMessagesCount: Int { totalUnreadCount }

    /// The total number of unread channels.
    var totalUnreadChannelsCount: Int { channels.count }

    /// The unread information per channel.
    var unreadChannels: [UnreadChannel] { channels }

    /// The unread information per thread.
    var unreadThreads: [UnreadThread] { threads }

    /// The unread information per channel type.
    var unreadChannelsByType: [UnreadChannelByType] { channelType }
}

public extension UnreadChannel {
    /// The number of unread messages inside the channel.
    var unreadMessagesCount: Int { unreadCount }
}

public extension UnreadChannelByType {
    /// The number of unread channels of this channel type.
    var unreadChannelCount: Int { channelCount }

    /// The number of unread messages of all the channels with this type.
    var unreadMessagesCount: Int { unreadCount }
}

public extension UnreadThread {
    /// The number of unread replies inside the thread.
    var unreadRepliesCount: Int { unreadCount }
}
