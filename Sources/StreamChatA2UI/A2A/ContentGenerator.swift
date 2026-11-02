//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// A request sent to an A2UI agent.
///
/// A request carries at most one user message plus any renderer-to-agent A2UI
/// events that accumulated since the last request, together with the metadata
/// the protocol expects on every message: renderer capabilities and, for
/// surfaces that opted in, their data models.
public struct GenerationRequest {
    /// The user's message, when the request was triggered by the user.
    public let userMessage: UserMessage?

    /// A2UI events to deliver to the agent.
    public let rendererMessages: [RendererMessage]

    /// The conversation so far, for stateless agents.
    public let history: [Message]

    /// The catalogs and features this renderer supports.
    public let capabilities: RendererCapabilities?

    /// The data models of surfaces created with `sendDataModel`.
    public let dataModel: RendererDataModel?

    /// Creates a request.
    /// Provide either a user message, renderer messages, or both.
    public init(
        userMessage: UserMessage? = nil,
        rendererMessages: [RendererMessage] = [],
        history: [Message] = [],
        capabilities: RendererCapabilities? = nil,
        dataModel: RendererDataModel? = nil
    ) {
        self.userMessage = userMessage
        self.rendererMessages = rendererMessages
        self.history = history
        self.capabilities = capabilities
        self.dataModel = dataModel
    }

    /// Whether the request has anything to send.
    public var isEmpty: Bool {
        userMessage == nil && rendererMessages.isEmpty
    }
}

/// An error surfaced by a content generator.
public struct ContentGeneratorError: Error {
    /// The underlying failure.
    public let error: Error

    /// An optional description of where the failure happened.
    public let context: String

    /// Wraps an error for delivery through the error stream.
    public init(_ error: Error, context: String = "") {
        self.error = error
        self.context = context
    }

    /// A human-readable description of the failure.
    public var localizedDescription: String {
        let description = A2UIErrorFormatter.describe(error)
        return context.isEmpty ? description : "\(context): \(description)"
    }
}

/// Produces A2UI messages for a renderer.
///
/// Implementations connect the renderer to an agent, whether over A2A, another
/// transport, or a local model.
@MainActor
public protocol ContentGenerator: AnyObject {
    /// A2UI messages streamed by the agent.
    var messages: AnyPublisher<A2UIMessage, Never> { get }

    /// Plain text responses streamed by the agent.
    var textResponses: AnyPublisher<String, Never> { get }

    /// Failures encountered while talking to the agent.
    var errors: AnyPublisher<ContentGeneratorError, Never> { get }

    /// Whether a request is currently in flight.
    var isProcessing: ValueNotifier<Bool> { get }

    /// Sends a request to the agent.
    /// Messages produced by the agent arrive on ``messages``.
    func send(_ request: GenerationRequest) async

    /// Releases the generator's resources.
    func dispose()
}
