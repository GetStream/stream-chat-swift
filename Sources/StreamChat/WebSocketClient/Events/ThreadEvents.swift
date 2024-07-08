//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// Triggered when a new message is sent to a thread.
public struct ThreadMessageNewEvent: Event {
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
}

class ThreadMessageNewEventDTO: EventDTO {
    let cid: ChannelId
    let message: MessagePayload
    let channel: ChannelDetailPayload
    let unreadCount: UnreadCountPayload?
    let createdAt: Date
    let payload: EventPayload

    init(from response: EventPayload) throws {
        cid = try response.value(at: \.cid)
        message = try response.value(at: \.message)
        createdAt = try response.value(at: \.createdAt)
        channel = try response.value(at: \.channel)
        unreadCount = try? response.value(at: \.unreadCount)
        payload = response
    }

    func toDomainEvent(session: DatabaseSession) -> Event? {
        guard
            let messageDTO = session.message(id: message.id),
            let channelDTO = session.channel(cid: cid),
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
public struct ThreadUpdatedEvent: Event {
    /// The updated user
    public let thread: ChatThread

    /// The event timestamp
    public let createdAt: Date?
}

class ThreadUpdatedEventDTO: EventDTO {
    let thread: ThreadPartialPayload
    let createdAt: Date
    let payload: EventPayload

    init(from response: EventPayload) throws {
        thread = try response.value(at: \.threadPartial)
        createdAt = try response.value(at: \.createdAt)
        payload = response
    }

    func toDomainEvent(session: DatabaseSession) -> Event? {
        guard let threadDTO = session.thread(parentMessageId: thread.parentMessageId, cache: nil) else { return nil }

        return try? ThreadUpdatedEvent(
            thread: threadDTO.asModel(),
            createdAt: createdAt
        )
    }
}
