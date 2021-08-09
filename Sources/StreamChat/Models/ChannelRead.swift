//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// A type representing a user's last read action on a channel.
public struct ChatChannelRead {
    /// The last time the user has read the channel.
    public let lastReadAt: Date
    
    /// Number of unread messages the user has in this channel.
    public let unreadMessagesCount: Int
    
    /// The user who read the channel.
    public let user: ChatUser
    
    init(
        lastReadAt: Date,
        unreadMessagesCount: Int,
        user: ChatUser
    ) {
        self.lastReadAt = lastReadAt
        self.unreadMessagesCount = unreadMessagesCount
        self.user = user
    }
}
