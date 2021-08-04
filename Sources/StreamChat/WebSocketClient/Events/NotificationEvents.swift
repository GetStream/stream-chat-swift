//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

public struct NotificationMessageNewEvent: MessageSpecificEvent {
    public let userId: UserId
    public let cid: ChannelId
    public let messageId: MessageId
    public let createdAt: Date
    public let unreadCount: UnreadCount?
    
    var savedData: SavedEventData?
    let payload: Any
    
    init(from response: EventPayload) throws {
        userId = try response.value(at: \.message?.user.id)
        cid = try response.value(at: \.channel?.cid)
        messageId = try response.value(at: \.message?.id)
        createdAt = try response.value(at: \.message?.createdAt)
        unreadCount = try? response.value(at: \.unreadCount)
        payload = response
    }
}

public struct NotificationMarkAllReadEvent: UserSpecificEvent {
    public let userId: UserId
    public let readAt: Date
    
    var savedData: SavedEventData?
    let payload: Any
    
    init(from response: EventPayload) throws {
        userId = try response.value(at: \.user?.id)
        readAt = try response.value(at: \.createdAt)
        payload = response
    }
}

public struct NotificationMarkReadEvent: UserSpecificEvent, ChannelSpecificEvent {
    public let userId: UserId
    public let cid: ChannelId
    public let readAt: Date
    public let unreadCount: UnreadCount
    
    var savedData: SavedEventData?
    let payload: Any
    
    init(from response: EventPayload) throws {
        userId = try response.value(at: \.user?.id)
        cid = try response.value(at: \.channel?.cid)
        readAt = try response.value(at: \.createdAt)
        unreadCount = try response.value(at: \.unreadCount)
        payload = response
    }
}

public struct NotificationMutesUpdatedEvent: CurrentUserEvent {
    public let currentUserId: UserId
    
    var savedData: SavedEventData?
    let payload: Any
    
    init(from response: EventPayload) throws {
        currentUserId = try response.value(at: \.currentUser?.id)
        payload = response
    }
}

public struct NotificationAddedToChannelEvent: ChannelSpecificEvent {
    public let cid: ChannelId
    
    var savedData: SavedEventData?
    let payload: Any
    
    init(from response: EventPayload) throws {
        cid = try response.value(at: \.cid)
        payload = response
    }
}

public struct NotificationRemovedFromChannelEvent: CurrentUserEvent, ChannelSpecificEvent {
    public let currentUserId: UserId
    public let cid: ChannelId

    var savedData: SavedEventData?
    let payload: Any
    
    init(from response: EventPayload) throws {
        cid = try response.value(at: \.cid)
        currentUserId = try response.value(at: \.user?.id)
        payload = response
    }
}

public struct NotificationChannelMutesUpdatedEvent: UserSpecificEvent {
    public let userId: UserId
    
    var savedData: SavedEventData?
    let payload: Any
    
    init(from response: EventPayload) throws {
        userId = try response.value(at: \.currentUser?.id)
        payload = response
    }
}

public struct NotificationInvitedEvent: MemberEvent {
    public let memberUserId: UserId
    public let cid: ChannelId
    
    var savedData: SavedEventData?
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
    
    var savedData: SavedEventData?
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
    
    var savedData: SavedEventData?
    let payload: Any
    
    init(from response: EventPayload) throws {
        cid = try response.value(at: \.cid)
        memberUserId = try response.value(at: \.user?.id)
        payload = response
    }
}
