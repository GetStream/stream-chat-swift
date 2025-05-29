//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

/// A formatter that generates a name for the given channel.
public protocol ChannelNameFormatter {
    @preconcurrency @MainActor func format(channel: ChatChannel, forCurrentUserId currentUserId: UserId?) -> String?
}

/// The default channel name formatter.
open class DefaultChannelNameFormatter: ChannelNameFormatter {
    public init() {}

    /// Internal static property to add backwards compatibility to `Components.channelNamer`
    @MainActor static var channelNamer: (
        _ channel: ChatChannel,
        _ currentUserId: UserId?
    ) -> String? = DefaultChatChannelNamer()

    open func format(channel: ChatChannel, forCurrentUserId currentUserId: UserId?) -> String? {
        Self.channelNamer(channel, currentUserId)
    }
}
