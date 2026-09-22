//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension Endpoint {
    static func startTypingEvent(cid: ChannelId, parentMessageId: MessageId?) -> Endpoint<EmptyResponse> {
        .sendEvent(
            type: cid.type.rawValue,
            id: cid.id,
            sendEventRequest: SendEventRequest(event: EventRequest(parentId: parentMessageId, type: EventType.userStartTyping.rawValue))
        )
    }

    static func stopTypingEvent(cid: ChannelId, parentMessageId: MessageId?) -> Endpoint<EmptyResponse> {
        .sendEvent(
            type: cid.type.rawValue,
            id: cid.id,
            sendEventRequest: SendEventRequest(event: EventRequest(parentId: parentMessageId, type: EventType.userStopTyping.rawValue))
        )
    }
}
