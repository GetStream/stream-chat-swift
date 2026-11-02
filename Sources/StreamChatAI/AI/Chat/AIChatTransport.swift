//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// How an ``AIChat`` reaches the agent and follows the conversation: it sends what the person
/// asks, stops the agent, and tells the chat what the conversation holds as it changes.
///
/// With Stream Chat, the conversation is a channel: the transport follows its messages and AI
/// indicator events, and sends each request through the channel or your agent's own API.
///
/// ```swift
/// final class AgentTransport: AIChatTransport {
///     private var feed: AIChatFeed<AgentMessage>?
///
///     func connect(_ feed: AIChatFeed<AgentMessage>) {
///         self.feed = feed
///         feed.update(messages: channel.messages.reversed().map(AgentMessage.init))
///     }
///
///     func send(_ request: AIChatRequest<AgentMessage>) async throws {
///         try await agent.respond(to: request.text, files: request.attachments)
///     }
///
///     func stop() async throws {
///         try await agent.interrupt()
///     }
/// }
/// ```
@MainActor
public protocol AIChatTransport<Message> {
    /// The messages of the conversation.
    associatedtype Message: AIMessage

    /// Starts telling `feed` what the conversation holds: its messages each time they change,
    /// whether there are older ones to load, and what the agent says it is doing. The chat
    /// calls it once, as it is made.
    func connect(_ feed: AIChatFeed<Message>)

    /// Sends what the person asks. Return once the agent has the request: its reply arrives
    /// through the feed. A thrown error shows as the chat's error, and the person can retry.
    func send(_ request: AIChatRequest<Message>) async throws

    /// Stops the reply the agent is writing. What it wrote so far stays.
    func stop() async throws

    /// Loads the messages before the first one, which arrive through the feed. Does nothing
    /// by default.
    func loadOlderMessages() async throws

    /// Tells your backend how the person rated a reply, or that they took their rating back
    /// with nil. Does nothing by default: the chat keeps the ratings on this device.
    func rate(_ reply: Message, _ rating: AIMessageRating?) async throws
}

public extension AIChatTransport {
    func loadOlderMessages() async throws { /* No older messages to load. */ }

    func rate(_ reply: Message, _ rating: AIMessageRating?) async throws { /* Kept on this device. */ }
}

/// Where an ``AIChatTransport`` tells its ``AIChat`` what the conversation holds.
///
/// It holds the chat weakly, so keep it for as long as the transport follows the conversation:
/// once the chat is released, its updates go nowhere.
@MainActor
public struct AIChatFeed<Message: AIMessage> {
    private weak var chat: AIChat<Message>?

    init(chat: AIChat<Message>) {
        self.chat = chat
    }

    /// Whether the chat it updates is still there. Stop following the conversation once it
    /// isn't.
    public var isConnected: Bool {
        chat != nil
    }

    /// The conversation's messages, oldest first, each time they change.
    public func update(messages: [Message]) {
        chat?.receive(messages: messages)
    }

    /// Whether there are messages before the first one, which the transport's
    /// ``AIChatTransport/loadOlderMessages()`` loads.
    public func update(hasOlderMessages: Bool) {
        chat?.receive(hasOlderMessages: hasOlderMessages)
    }

    /// What the agent says it is doing, or nil once it stops saying.
    public func update(activity: AIAgentActivity?) {
        chat?.receive(activity: activity)
    }
}
