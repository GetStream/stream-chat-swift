//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// Triggered when a new message is sent to a channel the current user is member of.
public struct NotificationMessageNewEvent: ChannelSpecificEvent {
    /// The identifier of a channel a message is sent to.
    public var cid: ChannelId { channel.cid }
    
    /// The channel a message was sent to.
    public let channel: ChatChannel
    
    /// The sent message.
    public let message: ChatMessage
    
    /// The event timestamp.
    public let createdAt: Date
    
    /// The unread counts of the current user.
    public let unreadCount: UnreadCount?
}

struct NotificationMessageNewEventDTO: EventWithPayload {
    let channel: ChannelDetailPayload
    let message: MessagePayload
    let unreadCount: UnreadCount?
    let createdAt: Date
    let payload: Any
    
    init(from response: EventPayload) throws {
        channel = try response.value(at: \.channel)
        message = try response.value(at: \.message)
        createdAt = try response.value(at: \.createdAt)
        unreadCount = try? response.value(at: \.unreadCount)
        payload = response
    }
    
    func toDomainEvent(session: DatabaseSession) -> Event? {
        guard
            let channelDTO = session.channel(cid: channel.cid),
            let messageDTO = session.message(id: message.id)
        else { return nil }
        
        return NotificationMessageNewEvent(
            channel: channelDTO.asModel(),
            message: messageDTO.asModel(),
            createdAt: createdAt,
            unreadCount: unreadCount
        )
    }
}

/// Triggered when all channels the current user is member of are marked as read.
public struct NotificationMarkAllReadEvent: Event {
    /// The current user.
    public let user: ChatUser
    
    /// The event timestamp.
    public let createdAt: Date
}

struct NotificationMarkAllReadEventDTO: EventWithPayload {
    let user: UserPayload
    let createdAt: Date
    let payload: Any
    
    init(from response: EventPayload) throws {
        user = try response.value(at: \.user)
        createdAt = try response.value(at: \.createdAt)
        payload = response
    }
    
    func toDomainEvent(session: DatabaseSession) -> Event? {
        guard let userDTO = session.user(id: user.id) else { return nil }
        
        return NotificationMarkAllReadEvent(
            user: userDTO.asModel(),
            createdAt: createdAt
        )
    }
}

/// Triggered when a channel the current user is member of is marked as read.
public struct NotificationMarkReadEvent: ChannelSpecificEvent {
    /// The current user.
    public let user: ChatUser
    
    /// The read channel identifier.
    public let cid: ChannelId
    
    /// The unread counts of the current user.
    public let unreadCount: UnreadCount
    
    /// The event timestamp.
    public let createdAt: Date
}

struct NotificationMarkReadEventDTO: EventWithPayload {
    let user: UserPayload
    let cid: ChannelId
    let unreadCount: UnreadCount
    let createdAt: Date
    let payload: Any
    
    init(from response: EventPayload) throws {
        user = try response.value(at: \.user)
        cid = try response.value(at: \.cid)
        createdAt = try response.value(at: \.createdAt)
        unreadCount = try response.value(at: \.unreadCount)
        payload = response
    }
    
    func toDomainEvent(session: DatabaseSession) -> Event? {
        guard let userDTO = session.user(id: user.id) else { return nil }
        
        return NotificationMarkReadEvent(
            user: userDTO.asModel(),
            cid: cid,
            unreadCount: unreadCount,
            createdAt: createdAt
        )
    }
}

/// Triggered when current user mutes/unmutes a user.
public struct NotificationMutesUpdatedEvent: Event {
    /// The current user.
    public let currentUser: CurrentChatUser
    
    /// The event timestamp.
    public let createdAt: Date
}

struct NotificationMutesUpdatedEventDTO: EventWithPayload {
    let currentUser: CurrentUserPayload
    let createdAt: Date
    let payload: Any
    
    init(from response: EventPayload) throws {
        currentUser = try response.value(at: \.currentUser)
        createdAt = try response.value(at: \.createdAt)
        payload = response
    }
    
    func toDomainEvent(session: DatabaseSession) -> Event? {
        guard let currentUserDTO = session.currentUser else { return nil }

        return NotificationMutesUpdatedEvent(
            currentUser: currentUserDTO.asModel(),
            createdAt: createdAt
        )
    }
}

public struct NotificationAddedToChannelEvent: ChannelSpecificEvent {
    public let cid: ChannelId
    let payload: Any
    
    init(from response: EventPayload) throws {
        cid = try response.value(at: \.cid)
        payload = response
    }
}

public struct NotificationRemovedFromChannelEvent: CurrentUserEvent, ChannelSpecificEvent {
    public let currentUserId: UserId
    public let cid: ChannelId

    let payload: Any
    
    init(from response: EventPayload) throws {
        cid = try response.value(at: \.cid)
        currentUserId = try response.value(at: \.user?.id)
        payload = response
    }
}

public struct NotificationChannelMutesUpdatedEvent: UserSpecificEvent {
    public let userId: UserId
    let payload: Any
    
    init(from response: EventPayload) throws {
        userId = try response.value(at: \.currentUser?.id)
        payload = response
    }
}

public struct NotificationInvitedEvent: MemberEvent {
    public let memberUserId: UserId
    public let cid: ChannelId
    
    let payload: Any
    
    init(from response: EventPayload) throws {
        cid = try response.value(at: \.cid)
        memberUserId = try response.value(at: \.user?.id)
        payload = response
    }
}

public struct NotificationInviteAccepted: MemberEvent {
    public let memberUserId: UserId
    public let cid: ChannelId
    
    let payload: Any
    
    init(from response: EventPayload) throws {
        cid = try response.value(at: \.cid)
        memberUserId = try response.value(at: \.user?.id)
        payload = response
    }
}

public struct NotificationInviteRejected: MemberEvent {
    public let memberUserId: UserId
    public let cid: ChannelId
    
    let payload: Any
    
    init(from response: EventPayload) throws {
        cid = try response.value(at: \.cid)
        memberUserId = try response.value(at: \.user?.id)
        payload = response
    }
}
