//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

public struct TypingEvent: EventWithUserPayload, EventWithChannelId {
    public let isTyping: Bool
    public let cid: ChannelId
    public let userId: UserId
    
    let payload: Any
    
    init(isTyping: Bool, cid: ChannelId, userId: UserId, payload: Any = 0) {
        self.isTyping = isTyping
        self.cid = cid
        self.userId = userId
        self.payload = payload
    }
    
    init<ExtraData: ExtraDataTypes>(from response: EventPayload<ExtraData>) throws {
        cid = try response.value(at: \.cid)
        userId = try response.value(at: \.user?.id)
        isTyping = response.eventType == .userStartTyping
        payload = response
    }
}
