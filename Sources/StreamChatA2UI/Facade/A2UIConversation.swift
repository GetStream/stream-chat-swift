//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// Wires an A2UI agent to a renderer and keeps the conversation together.
///
/// The conversation owns the two halves of an A2UI client: a
/// ``ContentGenerator`` that talks to the agent, and an
/// ``A2UIMessageProcessor`` that turns the agent's messages into rendered
/// surfaces. It also closes the loop in the other direction, forwarding user
/// actions, function calls and renderer errors back to the agent with the
/// metadata the protocol requires.
///
/// ```swift
/// let conversation = A2UIConversation(
///     contentGenerator: A2UIContentGenerator(serverUrl: url),
///     processor: A2UIMessageProcessor(catalogs: [BasicCatalog.catalog])
/// )
/// await conversation.send(UserMessage.text("Order a pizza"))
/// ```
///
/// All members must be used from the main thread.
@MainActor
public final class A2UIConversation {
    /// The generator used to talk to the agent.
    public let contentGenerator: ContentGenerator

    /// The processor that owns renderer state.
    public let processor: A2UIMessageProcessor

    /// Called when the agent creates a surface.
    public var onSurfaceAdded: ((SurfaceAdded) -> Void)?

    /// Called when a surface's components or data change.
    public var onSurfaceUpdated: ((SurfaceUpdated) -> Void)?

    /// Called when a surface is deleted.
    public var onSurfaceRemoved: ((SurfaceRemoved) -> Void)?

    /// Called for every text response from the agent.
    public var onTextResponse: ((String) -> Void)?

    /// Called for every failure while talking to the agent.
    public var onError: ((ContentGeneratorError) -> Void)?

    /// Called for every user action, before it is sent to the agent.
    public var onAction: ((RendererAction) -> Void)?

    private let conversationNotifier = ValueNotifier<[Message]>([])
    private let customCapabilities: RendererCapabilities?
    private let forwardsRendererMessages: Bool
    private var pendingRendererMessages: [RendererMessage] = []
    private var isFlushScheduled = false
    private var cancellables: Set<AnyCancellable> = []

    /// Creates a conversation.
    ///
    /// Set `forwardsRendererMessages` to `false` to take over delivery of user
    /// actions, for example to clear surfaces before sending the next request.
    /// Pass `capabilities` to send inline catalogs to an agent that accepts them.
    public init(
        contentGenerator: ContentGenerator,
        processor: A2UIMessageProcessor,
        capabilities: RendererCapabilities? = nil,
        forwardsRendererMessages: Bool = true
    ) {
        self.contentGenerator = contentGenerator
        self.processor = processor
        self.customCapabilities = capabilities
        self.forwardsRendererMessages = forwardsRendererMessages

        contentGenerator.messages
            .sink { [weak self] message in
                self?.processor.handle(message)
            }
            .store(in: &cancellables)

        contentGenerator.textResponses
            .sink { [weak self] text in
                self?.append(AiTextMessage.text(text))
                self?.onTextResponse?(text)
            }
            .store(in: &cancellables)

        contentGenerator.errors
            .sink { [weak self] error in
                if let failure = error.error as? A2UIDecodingFailure {
                    self?.processor.send(.error(failure.rendererError))
                }
                self?.onError?(error)
            }
            .store(in: &cancellables)

        processor.surfaceUpdates
            .sink { [weak self] update in
                self?.handle(update)
            }
            .store(in: &cancellables)

        processor.rendererMessages
            .sink { [weak self] message in
                self?.enqueue(message)
            }
            .store(in: &cancellables)
    }

    /// The host that ``A2UISurface`` views bind to.
    public var host: A2UIHost {
        processor
    }

    /// The conversation so far, including rendered surfaces.
    public var conversation: ValueNotifier<[Message]> {
        conversationNotifier
    }

    /// Whether a request is currently in flight.
    public var isProcessing: ValueNotifier<Bool> {
        contentGenerator.isProcessing
    }

    /// The renderer capabilities advertised to the agent.
    ///
    /// Defaults to the processor's catalogs, unless capabilities were passed
    /// to the initializer.
    public var capabilities: RendererCapabilities {
        customCapabilities ?? RendererCapabilities(supportedCatalogIds: processor.catalogs.supportedCatalogIds)
    }

    /// Sends a user message to the agent.
    /// Pending renderer events are delivered with the same request.
    public func send(_ message: UserMessage) async {
        append(message)
        await send(userMessage: message, rendererMessages: takePendingMessages())
    }

    /// Sends a plain text prompt to the agent.
    public func send(text: String) async {
        await send(UserMessage.text(text))
    }

    /// Sends renderer-to-agent events without a user message.
    /// Use this when taking over event delivery.
    public func send(rendererMessages: [RendererMessage]) async {
        guard !rendererMessages.isEmpty else { return }
        await send(userMessage: nil, rendererMessages: rendererMessages)
    }

    /// Removes every rendered surface and its data.
    /// Call before a new request when the UI should start clean.
    public func clearSurfaces() {
        processor.clearSurfaces()
    }

    /// Releases the conversation's resources.
    public func dispose() {
        cancellables.removeAll()
        contentGenerator.dispose()
        processor.dispose()
    }

    // MARK: - Private

    private func send(userMessage: UserMessage?, rendererMessages: [RendererMessage]) async {
        let request = GenerationRequest(
            userMessage: userMessage,
            rendererMessages: rendererMessages,
            history: conversationNotifier.value,
            capabilities: capabilities,
            dataModel: processor.synchronizedDataModel()
        )
        await contentGenerator.send(request)
    }

    private func enqueue(_ message: RendererMessage) {
        if case let .action(action) = message {
            onAction?(action)
            if let text = action.userMessage {
                append(UiInteractionMessage(rendererMessages: [message], text: text))
            }
        }
        guard forwardsRendererMessages else { return }

        pendingRendererMessages.append(message)
        guard !isFlushScheduled else { return }
        isFlushScheduled = true

        // Coalesce everything produced in the same run loop turn into one
        // request, so a burst of events does not wake the agent repeatedly.
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.isFlushScheduled = false
            let messages = self.takePendingMessages()
            guard !messages.isEmpty else { return }
            Task { await self.send(userMessage: nil, rendererMessages: messages) }
        }
    }

    private func takePendingMessages() -> [RendererMessage] {
        defer { pendingRendererMessages.removeAll() }
        return pendingRendererMessages
    }

    private func handle(_ update: A2UIUpdate) {
        switch update {
        case let added as SurfaceAdded:
            append(AiUiMessage(definition: added.definition))
            onSurfaceAdded?(added)
        case let updated as SurfaceUpdated:
            replaceSurfaceMessage(with: updated.definition)
            onSurfaceUpdated?(updated)
        case let removed as SurfaceRemoved:
            conversationNotifier.value = conversationNotifier.value.filter { message in
                (message as? AiUiMessage)?.surfaceId != removed.surfaceId
            }
            onSurfaceRemoved?(removed)
        default:
            break
        }
    }

    private func append(_ message: Message) {
        conversationNotifier.value = conversationNotifier.value + [message]
    }

    private func replaceSurfaceMessage(with definition: UiDefinition) {
        var messages = conversationNotifier.value
        if let index = messages.lastIndex(where: { ($0 as? AiUiMessage)?.surfaceId == definition.surfaceId }) {
            messages[index] = AiUiMessage(definition: definition)
        } else {
            messages.append(AiUiMessage(definition: definition))
        }
        conversationNotifier.value = messages
    }
}
