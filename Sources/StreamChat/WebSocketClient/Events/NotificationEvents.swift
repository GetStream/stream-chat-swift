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

struct NotificationMessageNewEventDTO: EventDTO {
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

struct NotificationMarkAllReadEventDTO: EventDTO {
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

struct NotificationMarkReadEventDTO: EventDTO {
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

struct NotificationMutesUpdatedEventDTO: EventDTO {
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

/// Triggered when the current user is added to the channel member list.
public struct NotificationAddedToChannelEvent: Event {
    /// The channel the current user was added to.
    public let channel: ChatChannel
    
    /// The event timestamp.
    public let createdAt: Date
}

struct NotificationAddedToChannelEventDTO: EventDTO {
    let channel: ChannelDetailPayload
    let createdAt: Date
    let payload: Any
    
    init(from response: EventPayload) throws {
        channel = try response.value(at: \.channel)
        createdAt = try response.value(at: \.createdAt)
        payload = response
    }
    
    func toDomainEvent(session: DatabaseSession) -> Event? {
        guard let channelDTO = session.channel(cid: channel.cid) else { return nil }

        return NotificationAddedToChannelEvent(
            channel: channelDTO.asModel(),
            createdAt: createdAt
        )
    }
}

/// Triggered when the current user is removed from a channel member list.
public struct NotificationRemovedFromChannelEvent: ChannelSpecificEvent {
    /// The user who removed the current user from channel members.
    public let user: ChatUser
    
    /// The channel identifier the current user was removed from.
    public let cid: ChannelId
    
    /// The current user.
    public let member: ChatChannelMember
    
    /// The event timestamp.
    public let createdAt: Date
}

struct NotificationRemovedFromChannelEventDTO: EventDTO {
    let cid: ChannelId
    let user: UserPayload
    let member: MemberPayload
    let createdAt: Date
    let payload: Any
    
    init(from response: EventPayload) throws {
        cid = try response.value(at: \.cid)
        user = try response.value(at: \.user)
        member = try response.value(at: \.memberContainer?.member)
        createdAt = try response.value(at: \.createdAt)
        payload = response
    }
    
    func toDomainEvent(session: DatabaseSession) -> Event? {
        guard
            let userDTO = session.user(id: user.id),
            let memberDTO = session.member(userId: member.user.id, cid: cid)
        else { return nil }
        
        return NotificationRemovedFromChannelEvent(
            user: userDTO.asModel(),
            cid: cid,
            member: memberDTO.asModel(),
            createdAt: createdAt
        )
    }
}

/// Triggered when current user mutes/unmutes a channel.
public struct NotificationChannelMutesUpdatedEvent: Event {
    /// The current user.
    public let currentUser: CurrentChatUser
    
    /// The event timestamp.
    public let createdAt: Date
}

struct NotificationChannelMutesUpdatedEventDTO: EventDTO {
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
        
        return NotificationChannelMutesUpdatedEvent(
            currentUser: currentUserDTO.asModel(),
            createdAt: createdAt
        )
    }
}

/// Triggered when current user is invited to a channel.
public struct NotificationInvitedEvent: MemberEvent, ChannelSpecificEvent {
    /// The inviter.
    public let user: ChatUser
    
    /// The channel identifier the current user was invited to.
    public let cid: ChannelId
    
    /// The membership information of the current user.
    public let member: ChatChannelMember
    
    /// The event timestamp.
    public let createdAt: Date
}

struct NotificationInvitedEventDTO: EventDTO {
    let user: UserPayload
    let cid: ChannelId
    let member: MemberPayload
    let createdAt: Date
    let payload: Any
    
    init(from response: EventPayload) throws {
        user = try response.value(at: \.user)
        cid = try response.value(at: \.cid)
        member = try response.value(at: \.memberContainer?.member)
        createdAt = try response.value(at: \.createdAt)
        payload = response
    }
    
    func toDomainEvent(session: DatabaseSession) -> Event? {
        guard
            let userDTO = session.user(id: user.id),
            let memberDTO = session.member(userId: member.user.id, cid: cid)
        else { return nil }
        
        return NotificationInvitedEvent(
            user: userDTO.asModel(),
            cid: cid,
            member: memberDTO.asModel(),
            createdAt: createdAt
        )
    }
}

/// Triggered when the current user accepts an invite to a channel.
public struct NotificationInviteAcceptedEvent: MemberEvent, ChannelSpecificEvent {
    /// The inviter.
    public let user: ChatUser
    
    /// The channel identifier the current user has become a member of.
    public var cid: ChannelId { channel.cid }
    
    /// The channel the current user has become a member of.
    public let channel: ChatChannel
        
    /// The membership information of the current user.
    public let member: ChatChannelMember
    
    /// The event timestamp.
    public let createdAt: Date
}

struct NotificationInviteAcceptedEventDTO: EventDTO {
    let user: UserPayload
    let channel: ChannelDetailPayload
    let member: MemberPayload
    let createdAt: Date
    let payload: Any
    
    init(from response: EventPayload) throws {
        user = try response.value(at: \.user)
        channel = try response.value(at: \.channel)
        member = try response.value(at: \.memberContainer?.member)
        createdAt = try response.value(at: \.createdAt)
        payload = response
    }
    
    func toDomainEvent(session: DatabaseSession) -> Event? {
        guard
            let userDTO = session.user(id: user.id),
            let channelDTO = session.channel(cid: channel.cid),
            let memberDTO = session.member(userId: member.user.id, cid: channel.cid)
        else { return nil }
        
        return NotificationInviteAcceptedEvent(
            user: userDTO.asModel(),
            channel: channelDTO.asModel(),
            member: memberDTO.asModel(),
            createdAt: createdAt
        )
    }
}

/// Triggered when the current user rejects an invite to a channel.
public struct NotificationInviteRejectedEvent: MemberEvent, ChannelSpecificEvent {
    /// The inviter.
    public let user: ChatUser
    
    /// The channel identifier the current user has rejected an intivation to.
    public var cid: ChannelId { channel.cid }
    
    /// The channel the current user has rejected an intivation to.
    public let channel: ChatChannel
        
    /// The membership information of the current user.
    public let member: ChatChannelMember
    
    /// The event timestamp.
    public let createdAt: Date
}

struct NotificationInviteRejectedEventDTO: EventDTO {
    let user: UserPayload
    let channel: ChannelDetailPayload
    let member: MemberPayload
    let createdAt: Date
    let payload: Any
    
    init(from response: EventPayload) throws {
        user = try response.value(at: \.user)
        channel = try response.value(at: \.channel)
        member = try response.value(at: \.memberContainer?.member)
        createdAt = try response.value(at: \.createdAt)
        payload = response
    }
    
    func toDomainEvent(session: DatabaseSession) -> Event? {
        guard
            let userDTO = session.user(id: user.id),
            let channelDTO = session.channel(cid: channel.cid),
            let memberDTO = session.member(userId: member.user.id, cid: channel.cid)
        else { return nil }
        
        return NotificationInviteRejectedEvent(
            user: userDTO.asModel(),
            channel: channelDTO.asModel(),
            member: memberDTO.asModel(),
            createdAt: createdAt
        )
    }
}
