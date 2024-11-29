//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// An event that provides updates about the state of the AI typing indicator.
public struct AITypingUpdateEvent: Event {
    /// The state of the AI typing indicator.
    public let state: AITypingState
    /// The channel ID this event is related to.
    public let cid: ChannelId?
    /// The message ID this event is related to.
    public let messageId: MessageId?
    /// Optional server message, usually when an error occurs.
    public let message: String?
}

class AITypingUpdateEventDTO: EventDTO {
    let payload: EventPayload
    
    init(from response: EventPayload) throws {
        payload = response
    }

    func toDomainEvent(session: DatabaseSession) -> Event? {
        if let typingState = payload.aiState,
           let aiTypingState = AITypingState(rawValue: typingState) {
            return AITypingUpdateEvent(
                state: aiTypingState,
                cid: payload.cid,
                messageId: payload.messageId,
                message: payload.aiMessage
            )
        } else {
            return nil
        }
    }
}

/// An event that clears the AI typing indicator.
public struct AIClearTypingEvent: Event {
    /// The channel ID this event is related to.
    public let cid: ChannelId?
}

class AIClearTypingEventDTO: EventDTO {
    let payload: EventPayload
        
    init(from response: EventPayload) throws {
        payload = response
    }
    
    func toDomainEvent(session: any DatabaseSession) -> (any Event)? {
        AIClearTypingEvent(cid: payload.cid)
    }
}

/// An event that indicates the AI has stopped generating the message.
public struct AIStopTypingEvent: Event {
    /// The channel ID this event is related to.
    public let cid: ChannelId?
}

class AIStopTypingEventDTO: EventDTO {
    let payload: EventPayload
        
    init(from response: EventPayload) throws {
        payload = response
    }
    
    func toDomainEvent(session: any DatabaseSession) -> (any Event)? {
        AIStopTypingEvent(cid: payload.cid)
    }
}

/// The state of the AI typing indicator.
public struct AITypingState: ExpressibleByStringLiteral, Hashable {
    public var rawValue: String
    
    public init?(rawValue: String) {
        self.rawValue = rawValue
    }
    
    public init(stringLiteral value: String) {
        rawValue = value
    }
}

public extension AITypingState {
    /// The AI is thinking.
    static let thinking: Self = "AI_STATE_THINKING"
    /// The AI is checking external sources.
    static let checkingExternalSources: Self = "AI_STATE_EXTERNAL_SOURCES"
    /// The AI is generating the message.
    static let generating: Self = "AI_STATE_GENERATING"
    /// There's an error with the message generation.
    static let error: Self = "AI_STATE_ERROR"
}
