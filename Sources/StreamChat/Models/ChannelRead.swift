//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A type representing a user's last read action on a channel. `ChatChannelRead` is an immutable snapshot
/// of a channel read entity at the given time.
public final class ChatChannelRead: Sendable {
    /// The last time the user has read the channel.
    public let lastReadAt: Date

    /// Id for the last message the user has read. Nil means the user has never read this channel.
    public let lastReadMessageId: MessageId?

    /// Number of unread messages the user has in this channel.
    public let unreadMessagesCount: Int

    /// The user who read the channel.
    public let user: ChatUser

    /// The last time a message has been delivered to this user.
    public let lastDeliveredAt: Date?

    /// The last message ID that has been delivered to this user.
    public let lastDeliveredMessageId: MessageId?

    init(
        lastReadAt: Date,
        lastReadMessageId: MessageId?,
        unreadMessagesCount: Int,
        user: ChatUser,
        lastDeliveredAt: Date?,
        lastDeliveredMessageId: MessageId?
    ) {
        self.lastReadAt = lastReadAt
        self.lastReadMessageId = lastReadMessageId
        self.unreadMessagesCount = unreadMessagesCount
        self.user = user
        self.lastDeliveredAt = lastDeliveredAt
        self.lastDeliveredMessageId = lastDeliveredMessageId
    }
}

extension ChatChannelRead: Equatable {
    public static func == (lhs: ChatChannelRead, rhs: ChatChannelRead) -> Bool {
        lhs.lastReadAt == rhs.lastReadAt &&
            lhs.lastReadMessageId == rhs.lastReadMessageId &&
            lhs.unreadMessagesCount == rhs.unreadMessagesCount &&
            lhs.user == rhs.user &&
            lhs.lastDeliveredAt == rhs.lastDeliveredAt &&
            lhs.lastDeliveredMessageId == rhs.lastDeliveredMessageId
    }
}
