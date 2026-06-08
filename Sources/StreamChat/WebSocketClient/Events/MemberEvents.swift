//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Triggered when a new member is added to a channel.
public final class MemberAddedEvent: MemberEvent, ChannelSpecificEvent {
    /// The user who added a member to a channel.
    public let user: ChatUser

    /// The channel identifier a member was added to.
    public let cid: ChannelId

    /// The memeber that was added to a channel.
    public let member: ChatChannelMember

    /// The event timestamp.
    public let createdAt: Date

    init(user: ChatUser, cid: ChannelId, member: ChatChannelMember, createdAt: Date) {
        self.user = user
        self.cid = cid
        self.member = member
        self.createdAt = createdAt
    }
}

extension MemberAddedEventDTO: EventDTO {
    func toDomainEvent(session: any DatabaseSession) -> (any Event)? {
        guard let user = user, let userDTO = session.user(id: user.id) else { return nil }
        guard let cidString = cid, let channelId = try? ChannelId(cid: cidString) else { return nil }
        guard let userId = member.userId,
              let memberDTO = session.member(userId: userId, cid: channelId) else { return nil }

        return try? MemberAddedEvent(
            user: userDTO.asModel(),
            cid: channelId,
            member: memberDTO.asModel(),
            createdAt: createdAt
        )
    }
}

/// Triggered when a channel member is updated.
public final class MemberUpdatedEvent: MemberEvent, ChannelSpecificEvent {
    /// The user who updated a member.
    public let user: ChatUser

    /// The channel identifier a member was updated in.
    public let cid: ChannelId

    /// The updated member.
    public let member: ChatChannelMember

    /// The event timestamp.
    public let createdAt: Date

    init(user: ChatUser, cid: ChannelId, member: ChatChannelMember, createdAt: Date) {
        self.user = user
        self.cid = cid
        self.member = member
        self.createdAt = createdAt
    }
}

extension MemberUpdatedEventDTO: EventDTO {
    func toDomainEvent(session: any DatabaseSession) -> (any Event)? {
        guard let user = user, let userDTO = session.user(id: user.id) else { return nil }
        guard let cidString = cid, let channelId = try? ChannelId(cid: cidString) else { return nil }
        guard let userId = member.userId,
              let memberDTO = session.member(userId: userId, cid: channelId) else { return nil }

        return try? MemberUpdatedEvent(
            user: userDTO.asModel(),
            cid: channelId,
            member: memberDTO.asModel(),
            createdAt: createdAt
        )
    }
}

/// Triggered when a member is removed from a channel.
public final class MemberRemovedEvent: MemberEvent, ChannelSpecificEvent {
    /// The user who stopped being a member.
    public let user: ChatUser

    /// The channel identifier a member was removed from.
    public let cid: ChannelId

    /// The event timestamp.
    public let createdAt: Date

    init(user: ChatUser, cid: ChannelId, createdAt: Date) {
        self.user = user
        self.cid = cid
        self.createdAt = createdAt
    }
}

extension MemberRemovedEventDTO: EventDTO {
    func toDomainEvent(session: any DatabaseSession) -> (any Event)? {
        guard let user = user, let userDTO = session.user(id: user.id) else { return nil }
        guard let cidString = cid, let channelId = try? ChannelId(cid: cidString) else { return nil }

        return try? MemberRemovedEvent(
            user: userDTO.asModel(),
            cid: channelId,
            createdAt: createdAt
        )
    }
}
