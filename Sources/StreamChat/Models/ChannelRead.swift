//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// A type representing a user's last read action on a channel.
public struct ChatChannelRead: Equatable {
    /// The last time the user has read the channel.
    public let lastReadAt: Date

    /// Id for the last message the user has read. Nil means the user has never read this channel
    public let lastReadMessageId: MessageId?

    /// Number of unread messages the user has in this channel.
    public let unreadMessagesCount: Int

    /// The user who read the channel.
    public let user: ChatUser

    init(
        lastReadAt: Date,
        lastReadMessageId: MessageId?,
        unreadMessagesCount: Int,
        user: ChatUser
    ) {
        self.lastReadAt = lastReadAt
        self.lastReadMessageId = lastReadMessageId
        self.unreadMessagesCount = unreadMessagesCount
        self.user = user
    }
}
