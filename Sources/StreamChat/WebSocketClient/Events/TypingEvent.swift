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

    /// Slim channel-member information attached to the typing event, when available.
    public let memberInfo: ChatMemberInfo?

    /// The typing user together with optional member info from the event.
    public var typingUser: TypingUser {
        TypingUser(user: user, memberInfo: memberInfo)
    }

    /// If typing event happened in the message thread, this field contains thread root message identifier.
    public let parentId: MessageId?

    /// The event timestamp.
    public let createdAt: Date

    /// `true` if typing event happened in the message thread.
    public var isThread: Bool { parentId != nil }

    init(
        isTyping: Bool,
        cid: ChannelId,
        user: ChatUser,
        memberInfo: ChatMemberInfo? = nil,
        parentId: MessageId?,
        createdAt: Date
    ) {
        self.isTyping = isTyping
        self.cid = cid
        self.user = user
        self.memberInfo = memberInfo
        self.parentId = parentId
        self.createdAt = createdAt
    }
}

protocol TypingEventDTO: EventDTO {
    var cid: ChannelId { get }
    var createdAt: Date { get }
    var user: UserPayload? { get }
    var member: MemberInfoPayload? { get }
    var parentId: String? { get }
    var isTyping: Bool { get }
}

extension TypingEventDTO {
    var isThread: Bool { parentId != nil }

    func toDomainEvent(session: DatabaseSession) -> Event? {
        guard let user else { return nil }

        return TypingEvent(
            isTyping: isTyping,
            cid: cid,
            user: user.asModel(),
            memberInfo: member?.asModel(),
            parentId: parentId,
            createdAt: createdAt
        )
    }
}

extension TypingStartEventDTO: TypingEventDTO {
    var isTyping: Bool { true }
}

extension TypingStopEventDTO: TypingEventDTO {
    var isTyping: Bool { false }
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
