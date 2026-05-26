//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// An event that provides updates about the state of the AI typing indicator.
public final class AIIndicatorUpdateEvent: Event {
    /// The state of the AI typing indicator.
    public let state: AITypingState
    /// The channel ID this event is related to.
    public let cid: ChannelId?
    /// The message ID this event is related to.
    public let messageId: MessageId?
    /// Optional server message, usually when an error occurs.
    public let aiMessage: String?

    init(state: AITypingState, cid: ChannelId?, messageId: MessageId?, aiMessage: String?) {
        self.state = state
        self.cid = cid
        self.messageId = messageId
        self.aiMessage = aiMessage
    }
}

extension AIIndicatorUpdateEventDTO: EventDTO {
    func toDomainEvent(session: any DatabaseSession) -> (any Event)? {
        guard let aiTypingState = AITypingState(rawValue: aiState) else { return nil }
        let channelId = cid.flatMap { try? ChannelId(cid: $0) }
        return AIIndicatorUpdateEvent(
            state: aiTypingState,
            cid: channelId,
            messageId: messageId,
            aiMessage: aiMessage
        )
    }
}

/// An event that clears the AI typing indicator.
public final class AIIndicatorClearEvent: Event {
    /// The channel ID this event is related to.
    public let cid: ChannelId?

    init(cid: ChannelId?) {
        self.cid = cid
    }
}

extension AIIndicatorClearEventDTO: EventDTO {
    func toDomainEvent(session: any DatabaseSession) -> (any Event)? {
        let channelId = cid.flatMap { try? ChannelId(cid: $0) }
        return AIIndicatorClearEvent(cid: channelId)
    }
}

/// An event that indicates the AI has stopped generating the message.
public final class AIIndicatorStopEvent: CustomEventPayload, Event {
    public static let eventType: EventType = .aiTypingIndicatorStop
    
    /// The channel ID this event is related to.
    public let cid: ChannelId?
    
    public init(cid: ChannelId?) {
        self.cid = cid
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(cid)
    }

    public static func == (lhs: AIIndicatorStopEvent, rhs: AIIndicatorStopEvent) -> Bool {
        lhs.cid == rhs.cid
    }
}

extension AIIndicatorStopEventDTO: EventDTO {
    func toDomainEvent(session: any DatabaseSession) -> (any Event)? {
        let channelId = cid.flatMap { try? ChannelId(cid: $0) }
        return AIIndicatorStopEvent(cid: channelId)
    }
}

/// The state of the AI typing indicator.
public struct AITypingState: ExpressibleByStringLiteral, Hashable, Sendable {
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
