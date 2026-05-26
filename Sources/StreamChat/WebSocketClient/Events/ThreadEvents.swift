//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Triggered when a new message is sent to a thread.
public final class ThreadMessageNewEvent: Event {
    /// The reply that was sent.
    public let message: ChatMessage

    /// The channel identifier the message was sent to.
    public var cid: ChannelId { channel.cid }

    /// The channel a message was sent to.
    public let channel: ChatChannel

    /// The unread count information of the current user.
    public let unreadCount: UnreadCount

    /// The event timestamp.
    public let createdAt: Date

    init(message: ChatMessage, channel: ChatChannel, unreadCount: UnreadCount, createdAt: Date) {
        self.message = message
        self.channel = channel
        self.unreadCount = unreadCount
        self.createdAt = createdAt
    }
}

extension NotificationThreadMessageNewEventDTO: EventDTO {
    func toDomainEvent(session: any DatabaseSession) -> (any Event)? {
        guard let cidString = cid, let channelId = try? ChannelId(cid: cidString) else { return nil }
        guard
            let messageDTO = session.message(id: message.id),
            let channelDTO = session.channel(cid: channelId),
            let currentUser = session.currentUser
        else { return nil }

        return try? ThreadMessageNewEvent(
            message: messageDTO.asModel(),
            channel: channelDTO.asModel(),
            unreadCount: UnreadCount(currentUserDTO: currentUser),
            createdAt: createdAt
        )
    }
}

/// Triggered when a thread is updated
public final class ThreadUpdatedEvent: Event {
    /// The updated user
    public let thread: ChatThread

    /// The event timestamp
    public let createdAt: Date?

    init(thread: ChatThread, createdAt: Date?) {
        self.thread = thread
        self.createdAt = createdAt
    }
}

extension ThreadUpdatedEventDTO: EventDTO {
    func toDomainEvent(session: any DatabaseSession) -> (any Event)? {
        guard let thread = thread else { return nil }
        guard let threadDTO = session.thread(parentMessageId: thread.parentMessageId, cache: nil) else { return nil }

        return try? ThreadUpdatedEvent(
            thread: threadDTO.asModel(),
            createdAt: createdAt
        )
    }
}
