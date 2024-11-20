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
    let typingState: String
    
    init(from response: EventPayload, typingState: String) throws {
        payload = response
        self.typingState = typingState
    }

    func toDomainEvent(session: DatabaseSession) -> Event? {
        if let typingState = AITypingState(rawValue: typingState) {
            return AITypingEvent(typingState: typingState, cid: payload.cid)
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
    