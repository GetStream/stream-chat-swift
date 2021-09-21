//
// Copyright © 2021 Stream.io Inc. All rights reserved.
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

struct MemberAddedEventDTO: EventWithPayload {
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
        
        return MemberAddedEvent(
            user: userDTO.asModel(),
            cid: cid,
            member: memberDTO.asModel(),
            createdAt: createdAt
        )
    }
}

public struct MemberUpdatedEvent: MemberEvent, ChannelSpecificEvent, EventWithPayload {
    public let memberUserId: UserId
    public let cid: ChannelId
    
    let payload: Any
    
    init(from response: EventPayload) throws {
        memberUserId = try response.value(at: \.memberContainer?.member?.user.id)
        cid = try response.value(at: \.cid)
        payload = response
    }
}

public struct MemberRemovedEvent: MemberEvent, ChannelSpecificEvent, EventWithPayload {
    public var memberUserId: UserId
    public let cid: ChannelId
    
    let payload: Any
    
    init(from response: EventPayload) throws {
        memberUserId = try response.value(at: \.user?.id)
        cid = try response.value(at: \.cid)
        payload = response
    }
}
