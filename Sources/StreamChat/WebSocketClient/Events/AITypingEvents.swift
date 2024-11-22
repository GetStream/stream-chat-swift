//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct AITypingEvent: Event {
    public let state: AITypingState
    public let cid: ChannelId?
    public let messageId: MessageId?
}

class AITypingEventDTO: EventDTO {
    let payload: EventPayload
    
    init(from response: EventPayload) throws {
        payload = response
    }

    func toDomainEvent(session: DatabaseSession) -> Event? {
        if let typingState = payload.state,
           let aiTypingState = AITypingState(rawValue: typingState) {
            return AITypingEvent(state: aiTypingState, cid: payload.cid, messageId: payload.messageId)
        } else {
            return nil
        }
    }
}

public struct AIClearTypingEvent: Event {
    public let cid: ChannelId?
    public let messageId: MessageId?
}

class AIClearTypingEventDTO: EventDTO {
    let payload: EventPayload
        
    init(from response: EventPayload) throws {
        payload = response
    }
    
    func toDomainEvent(session: any DatabaseSession) -> (any Event)? {
        AIClearTypingEvent(cid: payload.cid, messageId: payload.messageId)
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
    
    public static let thinking: Self = "AI_STATE_THINKING"
    public static let checkingExternalSources: Self = "AI_STATE_EXTERNAL_SOURCES"
    public static let generating: Self = "AI_STATE_GENERATING"
    public static let error: Self = "AI_STATE_ERROR"
}
    