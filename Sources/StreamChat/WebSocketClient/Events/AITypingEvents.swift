//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct AITypingEvent: Event {
    public let typingState: AITypingState
    public let cid: ChannelId?
}

class AITypingEventDTO: EventDTO {
    let payload: EventPayload
    
    init(from response: EventPayload) throws {
        payload = response
    }

    func toDomainEvent(session: DatabaseSession) -> Event? {
        if let typingState = payload.typingState,
           let aITypingState = AITypingState(rawValue: typingState) {
            return AITypingEvent(typingState: aITypingState, cid: payload.cid)
        } else {
            return nil
        }
    }
}

public struct AITypingState: ExpressibleByStringLiteral, Hashable {
    public var rawValue: String
    
    public init?(rawValue: String) {
        self.rawValue = rawValue
    }
    
    public init(stringLiteral value: String) {
        rawValue = value
    }
    
    public static let thinking: Self = "io.getstream.ai.thinking"
    public static let checkingExternalSources: Self = "io.getstream.ai.external_sources"
    public static let generating: Self = "io.getstream.ai.generating"
    public static let clear: Self = "io.getstream.ai.clear"
}
    