//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

public struct MemberAddedEvent: MemberEvent {
    public let memberUserId: UserId
    public let cid: ChannelId
    
    let payload: Any
    
    init(from response: EventPayload) throws {
        memberUserId = try response.value(at: \.memberContainer?.member?.user.id)
        cid = try response.value(at: \.cid)
        payload = response
    }
}

public struct MemberUpdatedEvent: MemberEvent {
    public let memberUserId: UserId
    public let cid: ChannelId
    
    let payload: Any
    
    init(from response: EventPayload) throws {
        memberUserId = try response.value(at: \.memberContainer?.member?.user.id)
        cid = try response.value(at: \.cid)
        payload = response
    }
}

public struct MemberRemovedEvent: MemberEvent {
    public var memberUserId: UserId
    public let cid: ChannelId
    
    let payload: Any
    
    init(from response: EventPayload) throws {
        memberUserId = try response.value(at: \.user?.id)
        cid = try response.value(at: \.cid)
        payload = response
    }
}
