//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// How an ``AIConversation`` reaches the agent and learns what it holds: it sends what the
/// person asks, stops the agent, and tells the conversation its messages as they change.
///
/// With Stream Chat, the conversation is a channel: the transport follows its messages and AI
/// indicator events, and sends each request through the channel or your agent's own API.
///
/// ```swift
/// final class AgentTransport: AIConversationTransport {
///     private var feed: AIConversationFeed<AgentMessage>?
///
///     func connect(_ feed: AIConversationFeed<AgentMessage>) {
///         self.feed = feed
///         feed.update(messages: channel.messages.reversed().map(AgentMessage.init))
///     }
///
///     func send(_ request: AIConversationRequest<AgentMessage>) async throws {
///         try await agent.respond(to: request.text, files: request.attachments)
///     }
///
///     func stop() async throws {
///         try await agent.interrupt()
///     }
/// }
/// ```
@available(iOS 15.0, macOS 12.0, *)
@MainActor
public protocol AIConversationTransport<Message> {
    /// The messages of the conversation.
    associatedtype Message: AIMessage

    /// Starts telling `feed` what the conversation holds: its messages each time they change,
    /// whether there are older ones to load, and what the agent says it is doing. The
    /// conversation calls it once, as it is made.
    func connect(_ feed: AIConversationFeed<Message>)

    /// Sends what the person asks. Return once the agent has the request: its reply arrives
    /// through the feed. A thrown error shows as the conversation's error, and the person can
    /// retry, which sends the same request again with the same
    /// ``AIConversationRequest/messageID``: if the first attempt reached your backend, or you
    /// keep a copy of the failed message, use the id so the message isn't added twice.
    ///
    /// The conversation leaves out the messages a ``AIConversationRequestKind/regenerate`` or an
    /// ``AIConversationRequestKind/edit`` replaces only until the new reply starts. From then on
    /// it shows the messages as the feed has them, so update the conversation before the new reply
    /// arrives:
    /// - For a regenerate, remove the request's `message` and the messages after it, or write
    ///   the new reply in place of `message`, under its id.
    /// - For an edit, change the person's `message` to say the request's `text`, under its id, and
    ///   remove the messages after it.
    func send(_ request: AIConversationRequest<Message>) async throws

    /// Stops the reply the agent is writing. What it wrote so far stays.
    func stop() async throws

    /// Loads the messages before the first one, which arrive through the feed. Does nothing
    /// by default.
    func loadOlderMessages() async throws

    /// Tells your backend how the person rated a reply, or that they took their rating back
    /// with nil. Does nothing by default: the conversation keeps the ratings on this device.
    /// Ratings your backend has show through each message's ``AIMessage/rating``.
    func rate(_ reply: Message, _ rating: AIMessageRating?) async throws
}

@available(iOS 15.0, macOS 12.0, *)
public extension AIConversationTransport {
    func loadOlderMessages() async throws { /* No older messages to load. */ }

    func rate(_ reply: Message, _ rating: AIMessageRating?) async throws { /* Kept on this device. */ }
}

/// Where an ``AIConversationTransport`` tells its ``AIConversation`` what the conversation holds.
///
/// It holds the conversation weakly, so keep it for as long as the transport follows what the
/// conversation holds: once the conversation is released, its updates go nowhere.
@available(iOS 15.0, macOS 12.0, *)
@MainActor
public struct AIConversationFeed<Message: AIMessage> {
    private weak var conversation: AIConversation<Message>?

    init(conversation: AIConversation<Message>) {
        self.conversation = conversation
    }

    /// Whether the conversation it updates is still there. Stop following what it holds once it
    /// isn't.
    public var isConnected: Bool {
        conversation != nil
    }

    /// The conversation's messages, oldest first, each time they change.
    public func update(messages: [Message]) {
        conversation?.receive(messages: messages)
    }

    /// Whether there are messages before the first one, which the transport's
    /// ``AIConversationTransport/loadOlderMessages()`` loads.
    public func update(hasOlderMessages: Bool) {
        conversation?.receive(hasOlderMessages: hasOlderMessages)
    }

    /// What the agent says it is doing, or nil once it stops saying.
    public func update(activity: AIAgentActivity?) {
        conversation?.receive(activity: activity)
    }
}
