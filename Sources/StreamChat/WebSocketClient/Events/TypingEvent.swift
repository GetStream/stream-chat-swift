//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// Triggered when user starts/stops typing in a channel.
public struct TypingEvent: ChannelSpecificEvent {
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
}

struct TypingEventDTO: EventWithPayload {
    let user: UserPayload
    let cid: ChannelId
    let isTyping: Bool
    let parentId: MessageId?
    var isThread: Bool { parentId != nil }
    let createdAt: Date
    let payload: Any
    
    init(from response: EventPayload) throws {
        cid = try response.value(at: \.cid)
        user = try response.value(at: \.user)
        createdAt = try response.value(at: \.createdAt)
        isTyping = response.eventType == .userStartTyping
        parentId = try? response.value(at: \.parentId)
        payload = response
    }
    
    func toDomainEvent(session: DatabaseSession) -> Event? {
        guard let userDTO = session.user(id: user.id) else { return nil }
        
        return TypingEvent(
            isTyping: isTyping,
            cid: cid,
            user: userDTO.asModel(),
            parentId: parentId,
            createdAt: createdAt
        )
    }
}

/// A special event type which is only emitted by the SDK and never the backend.
/// This event is emitted by `TypingStartCleanupMiddleware` to signal that a typing event
/// must be cleaned up, due to timeout of that event.
public struct CleanUpTypingEvent: Event {
    public let cid: ChannelId
    public let userId: UserId
    
    init(cid: ChannelId, userId: UserId) {
        self.cid = cid
        self.userId = userId
    }
}
