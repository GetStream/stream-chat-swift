//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

public protocol MemberEvent: Event {
    var memberUserId: UserId { get }
    var cid: ChannelId { get }
}

public struct MemberAddedEvent: EventWithMemberPayload, EventWithChannelId, MemberEvent {
    public let memberUserId: UserId
    public let cid: ChannelId
    
    let payload: Any
    
    init<ExtraData: ExtraDataTypes>(from response: EventPayload<ExtraData>) throws {
        memberUserId = try response.value(at: \.memberContainer?.member?.user.id)
        cid = try response.value(at: \.cid)
        payload = response
    }
}

public struct MemberUpdatedEvent: EventWithMemberPayload, EventWithChannelId, MemberEvent {
    public let memberUserId: UserId
    public let cid: ChannelId
    
    let payload: Any
    
    init<ExtraData: ExtraDataTypes>(from response: EventPayload<ExtraData>) throws {
        memberUserId = try response.value(at: \.memberContainer?.member?.user.id)
        cid = try response.value(at: \.cid)
        payload = response
    }
}

public struct MemberRemovedEvent: MemberEvent, EventWithChannelId {
    public var memberUserId: UserId
    public let cid: ChannelId
    
    let payload: Any
    
    init<ExtraData: ExtraDataTypes>(from response: EventPayload<ExtraData>) throws {
        memberUserId = try response.value(at: \.user?.id)
        cid = try response.value(at: \.cid)
        payload = response
    }
}
