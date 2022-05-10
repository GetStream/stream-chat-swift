//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

/// Triggered when a new member is added to a channel.
public struct MemberAddedEvent: MemberEvent, ChannelSpecificEvent {
    /// The user who added a member to a channel.
    public let user: ChatUser
    
    /// The channel identifier a member was added to.
    public let cid: ChannelId
    
    /// The memeber that was added to a channel.
    public let member: ChatChannelMember
    
    /// The event timestamp.
    public let createdAt: Date
}

class MemberAddedEventDTO: EventDTO {
    let user: UserPayload
    let cid: ChannelId
    let member: MemberPayload
    let createdAt: Date
    let payload: EventPayload
    
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
        
        return try? MemberAddedEvent(
            user: userDTO.asModel(),
            cid: cid,
            member: memberDTO.asModel(),
            createdAt: createdAt
        )
    }
}

/// Triggered when a channel member is updated.
public struct MemberUpdatedEvent: MemberEvent, ChannelSpecificEvent {
    /// The user who updated a member.
    public let user: ChatUser
    
    /// The channel identifier a member was updated in.
    public let cid: ChannelId
    
    /// The updated member.
    public let member: ChatChannelMember
    
    /// The event timestamp.
    public let createdAt: Date
}

class MemberUpdatedEventDTO: EventDTO {
    let user: UserPayload
    let cid: ChannelId
    let member: MemberPayload
    let createdAt: Date
    let payload: EventPayload
    
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
        
        return try? MemberUpdatedEvent(
            user: userDTO.asModel(),
            cid: cid,
            member: memberDTO.asModel(),
            createdAt: createdAt
        )
    }
}

/// Triggered when a member is removed from a channel.
public struct MemberRemovedEvent: MemberEvent, ChannelSpecificEvent {
    /// The user who stopped being a member.
    public let user: ChatUser
    
    /// The channel identifier a member was removed from.
    public let cid: ChannelId
    
    /// The event timestamp.
    public let createdAt: Date
}

class MemberRemovedEventDTO: EventDTO {
    let user: UserPayload
    let cid: ChannelId
    let createdAt: Date
    let payload: EventPayload
    
    init(from response: EventPayload) throws {
        user = try response.value(at: \.user)
        cid = try response.value(at: \.cid)
        createdAt = try response.value(at: \.createdAt)
        payload = response
    }
    
    func toDomainEvent(session: DatabaseSession) -> Event? {
        guard let userDTO = session.user(id: user.id) else { return nil }
        
        return try? MemberRemovedEvent(
            user: userDTO.asModel(),
            cid: cid,
            createdAt: createdAt
        )
    }
}
