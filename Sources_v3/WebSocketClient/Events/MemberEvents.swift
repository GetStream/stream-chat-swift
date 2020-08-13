//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

public struct MemberAddedEvent: EventWithMemberPayload, EventWithChannelId {
    public let userId: UserId
    public let cid: ChannelId
    
    let payload: Any
    
    init<ExtraData: ExtraDataTypes>(from response: EventPayload<ExtraData>) throws {
        userId = try response.value(at: \.memberContainer?.member?.user.id)
        cid = try response.value(at: \.cid)
        payload = response
    }
}

public struct MemberUpdatedEvent: EventWithMemberPayload, EventWithChannelId {
    public let userId: UserId
    public let cid: ChannelId
    
    let payload: Any
    
    init<ExtraData: ExtraDataTypes>(from response: EventPayload<ExtraData>) throws {
        userId = try response.value(at: \.memberContainer?.member?.user.id)
        cid = try response.value(at: \.cid)
        payload = response
    }
}

public struct MemberRemovedEvent: EventWithUserPayload, EventWithChannelId {
    public let userId: UserId
    public let cid: ChannelId
    
    let payload: Any
    
    init<ExtraData: ExtraDataTypes>(from response: EventPayload<ExtraData>) throws {
        userId = try response.value(at: \.user?.id)
        cid = try response.value(at: \.cid)
        payload = response
    }
}
