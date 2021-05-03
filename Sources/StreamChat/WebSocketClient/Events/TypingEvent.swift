//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

public struct TypingEvent: UserSpecificEvent, ChannelSpecificEvent {
    public let isTyping: Bool
    public let cid: ChannelId
    public let userId: UserId
    
    let payload: Any
    
    init<ExtraData: ExtraDataTypes>(from response: EventPayload<ExtraData>) throws {
        cid = try response.value(at: \.cid)
        userId = try response.value(at: \.user?.id)
        isTyping = response.eventType == .userStartTyping
        payload = response
    }
}

/// A special event type which is only emitted by the SDK and never the backend.
/// This event is emitted by `TypingStartCleanupMiddleware` to signal that a typing event
/// must be cleaned up, due to timeout of that event.
public struct CleanUpTypingEvent: Event {
    public let cid: ChannelId
    public let userId: UserId
    
    init(cid: ChannelId, userId: UserId) {
        self.cid = cid
        self.userId = userId
    }
}
