//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Triggered when user starts/stops typing in a channel.
public final class TypingEvent: ChannelSpecificEvent {
    /// The flag saying if typing is started/stopped.
    public let isTyping: Bool

    /// The channel the typing event happened.
    public let cid: ChannelId

    /// The user who changed the typing state.
    public let user: ChatUser

    /// If typing event happened in the message thread, this field contains thread root message identifier.
    public let parentId: MessageId?

    /// The event timestamp.
    public let createdAt: Date

    /// `true` if typing event happened in the message thread.
    public var isThread: Bool { parentId != nil }

    init(isTyping: Bool, cid: ChannelId, user: ChatUser, parentId: MessageId?, createdAt: Date) {
        self.isTyping = isTyping
        self.cid = cid
        self.user = user
        self.parentId = parentId
        self.createdAt = createdAt
    }
}

extension TypingStartEventDTO: EventDTO {
    func toDomainEvent(session: any DatabaseSession) -> (any Event)? {
        guard let user = user, let userDTO = session.user(id: user.id) else { return nil }
        guard let cidString = cid, let channelId = try? ChannelId(cid: cidString) else { return nil }

        return try? TypingEvent(
            isTyping: true,
            cid: channelId,
            user: userDTO.asModel(),
            parentId: parentId,
            createdAt: createdAt
        )
    }
}

extension TypingStopEventDTO: EventDTO {
    func toDomainEvent(session: any DatabaseSession) -> (any Event)? {
        guard let user = user, let userDTO = session.user(id: user.id) else { return nil }
        guard let cidString = cid, let channelId = try? ChannelId(cid: cidString) else { return nil }

        return try? TypingEvent(
            isTyping: false,
            cid: channelId,
            user: userDTO.asModel(),
            parentId: parentId,
            createdAt: createdAt
        )
    }
}

/// A special event type which is only emitted by the SDK and never the backend.
/// This event is emitted by `TypingStartCleanupMiddleware` to signal that a typing event
/// must be cleaned up, due to timeout of that event.
public final class CleanUpTypingEvent: Event {
    public let cid: ChannelId
    public let userId: UserId

    init(cid: ChannelId, userId: UserId) {
        self.cid = cid
        self.userId = userId
    }
}
