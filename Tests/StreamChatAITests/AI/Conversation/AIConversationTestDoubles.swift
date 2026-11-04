//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChatAI
import XCTest

struct ChatMessage: AIMessage, Equatable {
    var id: String
    var role: AIMessageRole
    var text: String
    var isGenerating = false
    var attachments: [AIMessageAttachment] = []
    var rating: AIMessageRating?
    var uiDocument: AIUIDocument?

    static func user(_ id: String, _ text: String = "Plan a weekend in Lisbon") -> ChatMessage {
        ChatMessage(id: id, role: .user, text: text)
    }

    static func reply(_ id: String, _ text: String = "Here's a plan", generating: Bool = false) -> ChatMessage {
        ChatMessage(id: id, role: .assistant, text: text, isGenerating: generating)
    }
}

struct TransportError: Error, Equatable {}

// Records what the conversation asks of it, and lets a test say what the conversation holds and
// when each request finishes.
@MainActor
final class ConversationTransport: AIConversationTransport {
    private(set) var feed: AIConversationFeed<ChatMessage>?
    private(set) var requests: [AIConversationRequest<ChatMessage>] = []
    private(set) var stops = 0
    private(set) var loads = 0
    private(set) var ratings: [(id: String, rating: AIMessageRating?)] = []

    var initialMessages: [ChatMessage]
    var sendError: (any Error)?
    var stopError: (any Error)?
    var loadError: (any Error)?
    var failsRating: (AIMessageRating?) -> Bool = { _ in false }
    // Holds each send, stop, load and rating until the test finishes it.
    var holdsSends = false
    var holdsStops = false
    var holdsLoads = false
    var holdsRatings = false
    private var heldSends: [CheckedContinuation<Void, any Error>] = []
    private var heldStops: [CheckedContinuation<Void, any Error>] = []
    private var heldLoads: [CheckedContinuation<Void, Never>] = []
    private var heldRatings: [CheckedContinuation<Void, any Error>] = []

    init(messages: [ChatMessage] = []) {
        initialMessages = messages
    }

    var lastRequest: AIConversationRequest<ChatMessage>? {
        requests.last
    }

    func connect(_ feed: AIConversationFeed<ChatMessage>) {
        self.feed = feed
        feed.update(messages: initialMessages)
    }

    func send(_ request: AIConversationRequest<ChatMessage>) async throws {
        requests.append(request)
        if holdsSends {
            try await withCheckedThrowingContinuation { heldSends.append($0) }
        }
        if let sendError {
            throw sendError
        }
    }

    func stop() async throws {
        stops += 1
        if holdsStops {
            try await withCheckedThrowingContinuation { heldStops.append($0) }
        }
        if let stopError {
            throw stopError
        }
    }

    func loadOlderMessages() async throws {
        loads += 1
        if holdsLoads {
            await withCheckedContinuation { heldLoads.append($0) }
        }
        if let loadError {
            throw loadError
        }
    }

    func rate(_ reply: ChatMessage, _ rating: AIMessageRating?) async throws {
        ratings.append((reply.id, rating))
        if holdsRatings {
            try await withCheckedThrowingContinuation { heldRatings.append($0) }
        }
        if failsRating(rating) {
            throw TransportError()
        }
    }

    func finishSend(_ index: Int, throwing error: (any Error)? = nil) {
        if let error {
            heldSends[index].resume(throwing: error)
        } else {
            heldSends[index].resume()
        }
    }

    func finishStop(_ index: Int) {
        heldStops[index].resume()
    }

    func finishRating(_ index: Int, throwing error: (any Error)? = nil) {
        if let error {
            heldRatings[index].resume(throwing: error)
        } else {
            heldRatings[index].resume()
        }
    }

    func finishLoads() {
        heldLoads.forEach { $0.resume() }
        heldLoads = []
    }

    func update(_ messages: [ChatMessage]) {
        feed?.update(messages: messages)
    }

    func update(_ activity: AIAgentActivity?) {
        feed?.update(activity: activity)
    }
}

// A transport that only holds the conversation, which relies on what the protocol does by
// default.
@MainActor
final class MinimalTransport: AIConversationTransport {
    func connect(_ feed: AIConversationFeed<ChatMessage>) { /* Nothing to follow. */ }
    func send(_ request: AIConversationRequest<ChatMessage>) async throws { /* Nowhere to send. */ }
    func stop() async throws { /* Nothing to stop. */ }
}

// Lets the tasks the conversation starts run.
@MainActor
func settle() async {
    for _ in 0..<20 {
        await Task.yield()
    }
}

// Waits for what the conversation does in its own time, such as once its reply timeout ends.
@MainActor
func waitUntil(timeout: TimeInterval = 2, _ condition: () -> Bool) async throws {
    let deadline = Date().addingTimeInterval(timeout)
    while !condition() {
        guard Date() < deadline else {
            XCTFail("The condition wasn't met in time")
            return
        }
        try await Task.sleep(nanoseconds: 10_000_000)
    }
}

extension Array where Element == ChatMessage {
    var ids: [String] {
        map(\.id)
    }
}
