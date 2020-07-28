//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

public struct MemberAddedEvent<ExtraData: ExtraDataTypes>: EventWithMemberPayload, EventWithChannelId {
    public let userId: UserId
    public let cid: ChannelId
    
    let payload: Any
    
    init(from response: EventPayload<ExtraData>) throws {
        userId = try response.value(at: \.memberContainer?.member?.user.id)
        cid = try response.value(at: \.cid)
        payload = response
    }
}

public struct MemberUpdatedEvent<ExtraData: ExtraDataTypes>: EventWithMemberPayload, EventWithChannelId {
    public let userId: UserId
    public let cid: ChannelId
    
    let payload: Any
    
    init(from response: EventPayload<ExtraData>) throws {
        userId = try response.value(at: \.memberContainer?.member?.user.id)
        cid = try response.value(at: \.cid)
        payload = response
    }
}

public struct MemberRemovedEvent<ExtraData: ExtraDataTypes>: EventWithUserPayload, EventWithChannelId {
    public let userId: UserId
    public let cid: ChannelId
    
    let payload: Any
    
    init(from response: EventPayload<ExtraData>) throws {
        userId = try response.value(at: \.user?.id)
        cid = try response.value(at: \.cid)
        payload = response
    }
}
