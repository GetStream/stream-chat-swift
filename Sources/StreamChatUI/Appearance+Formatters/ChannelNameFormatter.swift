//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

/// A formatter that generates a name for the given channel.
public protocol ChannelNameFormatter {
    func format(channel: ChatChannel, forCurrentUserId currentUserId: UserId?) -> String?
}

/// The default channel name formatter.
open class DefaultChannelNameFormatter: ChannelNameFormatter {
    open func format(channel: ChatChannel, forCurrentUserId currentUserId: UserId?) -> String? {
        Components.default.channelNamer(channel, currentUserId)
    }
}
