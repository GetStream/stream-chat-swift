//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

public struct NotificationMessageNewEvent<ExtraData: ExtraDataTypes>: EventWithMessagePayload, EventWithChannelId {
    public let userId: UserId
    public let cid: ChannelId
    public let messageId: MessageId
    public let createdAt: Date
    public let unreadCount: UnreadCount
    let payload: Any
    
    init(from response: EventPayload<ExtraData>) throws {
        userId = try response.value(at: \.message?.user.id)
        cid = try response.value(at: \.channel?.cid)
        messageId = try response.value(at: \.message?.id)
        createdAt = try response.value(at: \.message?.createdAt)
        unreadCount = try response.value(at: \.unreadCount)
        payload = response
    }
}

public struct NotificationMarkAllReadEvent<ExtraData: ExtraDataTypes>: EventWithUserPayload {
    public let userId: UserId
    public let readAt: Date
    let payload: Any
    
    init(from response: EventPayload<ExtraData>) throws {
        userId = try response.value(at: \.user?.id)
        readAt = try response.value(at: \.createdAt)
        payload = response
    }
}

public struct NotificationMarkReadEvent<ExtraData: ExtraDataTypes>: EventWithUserPayload, EventWithChannelId {
    public let userId: UserId
    public let cid: ChannelId
    public let readAt: Date
    public let unreadCount: UnreadCount
    let payload: Any
    
    init(from response: EventPayload<ExtraData>) throws {
        userId = try response.value(at: \.user?.id)
        cid = try response.value(at: \.channel?.cid)
        readAt = try response.value(at: \.createdAt)
        unreadCount = try response.value(at: \.unreadCount)
        payload = response
    }
}

public struct NotificationMutesUpdatedEvent<ExtraData: ExtraDataTypes>: EventWithCurrentUserPayload {
    public let currentUserId: UserId
    let payload: Any
    
    init(from response: EventPayload<ExtraData>) throws {
        currentUserId = try response.value(at: \.currentUser?.id)
        payload = response
    }
}

public struct NotificationAddedToChannelEvent<ExtraData: ExtraDataTypes>: EventWithChannelId, EventWithPayload {
    public let cid: ChannelId
    public let unreadCount: UnreadCount
    let payload: Any
    
    init(from response: EventPayload<ExtraData>) throws {
        let cid = try response.value(at: \.channel?.cid)
        let unreadCount = try response.value(at: \.unreadCount)
        self.init(cid: cid, unreadCount: unreadCount, eventPayload: response)
    }
    
    init(cid: ChannelId, unreadCount: UnreadCount, eventPayload: EventPayload<ExtraData>) {
        self.cid = cid
        self.unreadCount = unreadCount
        payload = eventPayload
    }
}

public struct NotificationRemovedFromChannelEvent<ExtraData: ExtraDataTypes>: EventWithUserPayload, EventWithChannelId {
    public let cid: ChannelId
    public let userId: UserId
    public let memberRole: MemberRole
    let payload: Any
    
    init(from response: EventPayload<ExtraData>) throws {
        cid = try response.value(at: \.channel?.cid)
        userId = try response.value(at: \.user?.id)
        memberRole = try response.value(at: \.memberContainer?.memberRole?.role)
        payload = response
    }
}

public struct NotificationInvitedEvent<ExtraData: ExtraDataTypes>: EventWithUserPayload, EventWithChannelId {
    public let cid: ChannelId
    public let userId: UserId
    public let memberRole: MemberRole
    let payload: Any
    
    init(from response: EventPayload<ExtraData>) throws {
        guard try response.value(at: \.memberContainer?.invite?.isInvited) == true else {
            throw ClientError.EventDecoding(missingValue: "invited:true", for: Self.self)
        }
        
        cid = try response.value(at: \.channel?.cid)
        userId = try response.value(at: \.user?.id)
        memberRole = try response.value(at: \.memberContainer?.invite?.role)
        payload = response
    }
}

public struct NotificationInviteAcceptedEvent<ExtraData: ExtraDataTypes>: EventWithUserPayload, EventWithChannelId {
    public let cid: ChannelId
    public let userId: UserId
    public let memberRole: MemberRole
    public let acceptedAt: Date
    let payload: Any
    
    init(from response: EventPayload<ExtraData>) throws {
        guard try response.value(at: \.memberContainer?.invite?.isInvited) == true else {
            throw ClientError.EventDecoding(missingValue: "invited:true", for: Self.self)
        }
        
        cid = try response.value(at: \.channel?.cid)
        userId = try response.value(at: \.user?.id)
        memberRole = try response.value(at: \.memberContainer?.invite?.role)
        acceptedAt = try response.value(at: \.memberContainer?.invite?.inviteAcceptedAt)
        payload = response
    }
}

public struct NotificationInviteRejectedEvent<ExtraData: ExtraDataTypes>: EventWithUserPayload, EventWithChannelId {
    public let cid: ChannelId
    public let userId: UserId
    public let memberRole: MemberRole
    public let rejectedAt: Date
    let payload: Any
    
    init(from response: EventPayload<ExtraData>) throws {
        guard try response.value(at: \.memberContainer?.invite?.isInvited) == true else {
            throw ClientError.EventDecoding(missingValue: "invited:true", for: Self.self)
        }
        
        cid = try response.value(at: \.channel?.cid)
        userId = try response.value(at: \.user?.id)
        memberRole = try response.value(at: \.memberContainer?.invite?.role)
        rejectedAt = try response.value(at: \.memberContainer?.invite?.inviteRejectedAt)
        payload = response
    }
}
