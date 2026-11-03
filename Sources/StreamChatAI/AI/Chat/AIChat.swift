//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamCore

/// The state behind an AI conversation, and what the person does in it.
///
/// It holds the conversation's messages, where the latest exchange with the agent is and why it
/// failed, and it sends what the person asks through its ``AIChatTransport``. Give it to
/// ``AIConversationView`` and ``AIComposerView``, which show it and act on it: sending, stopping,
/// regenerating and rating replies, and editing the person's latest message.
///
/// ```swift
/// @StateObject private var chat = AIChat(transport: AgentTransport(channel: channel))
///
/// var body: some View {
///     AIConversationView(chat: chat) {
///         if chat.status == .error {
///             Button("Try again") { chat.retry() }
///         }
///     }
///     .safeAreaInset(edge: .bottom) {
///         AIComposerView(chat: chat)
///     }
/// }
/// ```
///
/// What the person sends shows straight away, and the agent thinks until its reply starts. While
/// a reply is written again, or a message the person edited is answered again, the messages it
/// replaces are left out of ``messages`` until the new reply starts.
@MainActor
public final class AIChat<Message: AIMessage>: ObservableObject {
    /// The conversation as it shows, oldest message first.
    @Published public private(set) var messages: [Message] = []
    /// The message the person sent that is not in the conversation yet, until its reply starts.
    @Published public private(set) var pendingMessage: AIPendingMessage?
    /// Where the latest exchange with the agent is.
    @Published public private(set) var status: AIChatStatus = .ready
    /// Why the latest request failed, or what the agent said when it couldn't answer, as an
    /// ``AIAgentError``. It stays until the next request.
    @Published public private(set) var error: (any Error)?
    /// What the agent says it is doing besides what its reply shows, such as checking sources.
    @Published public private(set) var activity: AIAgentActivity?
    /// Whether the conversation has messages before the first one, which
    /// ``loadOlderMessages()`` loads.
    @Published public private(set) var hasOlderMessages = false
    /// The person's message they are editing in the composer. The next message they send
    /// replaces it.
    @Published public private(set) var editingMessage: Message?
    /// How the person rated replies, by the reply's id.
    @Published public private(set) var ratings: [Message.ID: AIMessageRating] = [:]

    /// What the person is writing: ``AIComposerView`` shows it, and editing a message fills it.
    public let composer: AIComposerViewModel
    /// Who answers tool calls' questions and sign-ins on this device, which the conversation
    /// asks them.
    public let approver: AIToolApprover?

    private let transport: Transport
    // The messages as the transport last told them, including those left out of `messages`.
    private var conversation: [Message] = []
    // The request made, until its reply starts.
    private var exchange: AIChatExchange<Message>?
    // The request that failed, which `retry()` sends again.
    private var failedRequest: AIChatRequest<Message>?
    // Counts the requests and stops, so the outcome of one that was overtaken is ignored.
    private var generation = 0
    // Replies stopped while they were written, which are finished whatever they say.
    private var stopped: Set<AnyHashable> = []
    // Whether what the agent says it is doing is ignored, after it was stopped, until it stops
    // saying anything.
    private var ignoresActivity = false
    private var isLoadingOlderMessages = false

    // Lets the conversation view follow the chat, whichever view holds it.
    lazy var changes = AIObservedChanges(objectWillChange)

    // The transport's requirements, so the chat's type names only its messages.
    private struct Transport {
        let send: @MainActor (AIChatRequest<Message>) async throws -> Void
        let stop: @MainActor () async throws -> Void
        let loadOlderMessages: @MainActor () async throws -> Void
        let rate: @MainActor (Message, AIMessageRating?) async throws -> Void
    }

    /// - Parameters:
    ///   - transport: How the chat reaches the agent and follows the conversation. The chat keeps
    ///     it, and connects to it straight away.
    ///   - composer: What the person writes, such as one with your chat options. A new one by
    ///     default.
    ///   - approver: Who answers tool calls' questions and sign-ins on this device.
    public init<ChatTransport: AIChatTransport>(
        transport: ChatTransport,
        composer: AIComposerViewModel? = nil,
        approver: AIToolApprover? = nil
    ) where ChatTransport.Message == Message {
        self.transport = Transport(
            send: { try await transport.send($0) },
            stop: { try await transport.stop() },
            loadOlderMessages: { try await transport.loadOlderMessages() },
            rate: { try await transport.rate($0, $1) }
        )
        self.composer = composer ?? AIComposerViewModel()
        self.approver = approver
        transport.connect(AIChatFeed(chat: self))
    }

    // MARK: - What the person does

    /// Sends a message, or the person's edit of the message they are editing.
    ///
    /// - Parameters:
    ///   - text: What the person wrote.
    ///   - attachments: The files they picked, on this device.
    ///   - chatOption: The option they picked in the composer.
    public func send(_ text: String, attachments: [URL] = [], chatOption: ChatOption? = nil) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !attachments.isEmpty else { return }
        let edited = editingMessage
        editingMessage = nil
        start(
            AIChatRequest(
                kind: edited == nil ? .message : .edit,
                text: text,
                attachments: attachments,
                chatOption: chatOption,
                message: edited
            )
        )
    }

    /// Sends what the person wrote in the composer.
    public func send(_ message: MessageData) {
        send(message.text, attachments: message.attachments, chatOption: message.chatOption)
    }

    /// Stops the reply the agent is writing. What it wrote so far stays.
    public func stop() {
        guard status.isAnswering else { return }
        generation += 1
        let id = generation
        exchange = nil
        activity = nil
        ignoresActivity = true
        let writing = conversation.last.flatMap { $0.role != .user && $0.isGenerating ? AnyHashable($0.id) : nil }
        if let writing {
            stopped.insert(writing)
        }
        refresh()
        let stop = transport.stop
        Task { [weak self] in
            do {
                try await stop()
            } catch {
                self?.stopFailed(id, writing: writing, error: error)
            }
        }
    }

    /// Asks the agent for a new reply in place of `reply`, and of those after it.
    public func regenerate(_ reply: Message) {
        guard let index = index(of: reply), conversation[index].role != .user else { return }
        let prompt = conversation[..<index].last { $0.role == .user }
        start(AIChatRequest(kind: .regenerate, text: prompt?.text ?? "", message: conversation[index]))
    }

    /// Puts a message of the person's in the composer to edit. The next message they send
    /// replaces it.
    public func edit(_ message: Message) {
        guard message.role == .user else { return }
        editingMessage = message
        composer.text = message.text
        composer.isTextFieldFocused = true
    }

    /// Stops editing a message, and empties the composer.
    public func cancelEditing() {
        guard editingMessage != nil else { return }
        editingMessage = nil
        composer.text = ""
    }

    /// Tries again after ``error``: sends the request that failed again, or, when the agent
    /// couldn't answer, asks it for its reply again.
    public func retry() {
        if var request = failedRequest {
            request.messageID = UUID().uuidString
            start(request)
        } else if error is AIAgentError, let last = conversation.last {
            if last.role == .user {
                start(AIChatRequest(kind: .regenerate, text: last.text))
            } else {
                regenerate(last)
            }
        }
    }

    /// Forgets ``error``.
    public func clearError() {
        error = nil
        failedRequest = nil
        refresh()
    }

    /// Rates a reply, or takes the rating back with nil. The rating goes back to what it was if
    /// the transport can't send it.
    public func rate(_ reply: Message, _ rating: AIMessageRating?) {
        let previous = ratings[reply.id]
        guard previous != rating else { return }
        ratings[reply.id] = rating
        let rate = transport.rate
        Task { [weak self] in
            do {
                try await rate(reply, rating)
            } catch {
                log.error("Couldn't send the rating of a reply", error: error)
                guard let self, self.ratings[reply.id] == rating else { return }
                self.ratings[reply.id] = previous
            }
        }
    }

    /// Loads the messages before the first one, while there are any.
    public func loadOlderMessages() async {
        guard hasOlderMessages, !isLoadingOlderMessages else { return }
        isLoadingOlderMessages = true
        defer { isLoadingOlderMessages = false }
        do {
            try await transport.loadOlderMessages()
        } catch {
            log.error("Couldn't load older messages", error: error)
        }
    }

    // MARK: - What the transport says

    func receive(messages: [Message]) {
        conversation = messages
        if let exchange, exchange.hasReplyStarted(in: messages) {
            self.exchange = nil
        }
        refresh()
    }

    func receive(hasOlderMessages: Bool) {
        guard self.hasOlderMessages != hasOlderMessages else { return }
        self.hasOlderMessages = hasOlderMessages
    }

    func receive(activity: AIAgentActivity?) {
        guard let activity else {
            ignoresActivity = false
            self.activity = nil
            refresh()
            return
        }
        guard !ignoresActivity else { return }
        self.activity = activity
        if activity.state == .error {
            generation += 1
            exchange = nil
            if let last = conversation.last, last.role != .user, last.isGenerating {
                stopped.insert(AnyHashable(last.id))
            }
            error = AIAgentError(message: activity.text)
        }
        refresh()
    }

    // MARK: - What the conversation view offers

    // What the person can do with a finished reply: rate it, and write it again while it is the
    // latest and the agent isn't answering.
    func replyActions(for reply: Message, isLatestReply: Bool) -> AIReplyActions {
        var onRegenerate: (@MainActor () -> Void)?
        if offersRegenerate(isLatestReply: isLatestReply) {
            onRegenerate = { [weak self] in self?.regenerate(reply) }
        }
        return AIReplyActions(
            rating: ratings[reply.id],
            onRegenerate: onRegenerate,
            onRate: { [weak self] rating in self?.rate(reply, rating) }
        )
    }

    func offersRegenerate(isLatestReply: Bool) -> Bool {
        isLatestReply && !status.isAnswering
    }

    // Edits a message of the person's, when it is their latest and the agent isn't answering.
    func editAction(for message: Message) -> (@MainActor () -> Void)? {
        guard offersEdit(message) else { return nil }
        return { [weak self] in self?.edit(message) }
    }

    func offersEdit(_ message: Message) -> Bool {
        guard message.role == .user, !status.isAnswering else { return false }
        return messages.last { $0.role == .user }.map { AnyHashable($0.id) == AnyHashable(message.id) } ?? false
    }

    // MARK: - Private

    private func start(_ request: AIChatRequest<Message>) {
        generation += 1
        let id = generation
        error = nil
        failedRequest = nil
        activity = nil
        ignoresActivity = false
        stopped = []
        exchange = AIChatExchange(id: id, request: request, conversation: conversation)
        refresh()
        let send = transport.send
        Task { [weak self] in
            do {
                try await send(request)
            } catch {
                self?.requestFailed(id, request: request, error: error)
            }
        }
    }

    private func requestFailed(_ id: Int, request: AIChatRequest<Message>, error: any Error) {
        guard id == generation else { return }
        exchange = nil
        if !(error is CancellationError) {
            self.error = error
            failedRequest = request
        }
        refresh()
    }

    private func stopFailed(_ id: Int, writing: AnyHashable?, error: any Error) {
        guard id == generation, !(error is CancellationError) else { return }
        if let writing {
            stopped.remove(writing)
        }
        ignoresActivity = false
        self.error = error
        refresh()
    }

    private func index(of message: Message) -> Int? {
        conversation.firstIndex { AnyHashable($0.id) == AnyHashable(message.id) }
    }

    // Works out what the conversation shows and where it is, after anything changes.
    private func refresh() {
        // A reply stopped before it showed anything has nothing to show, and the conversation
        // would think it is still on its way.
        let hidden = (exchange?.replaced ?? []).union(
            conversation.filter { stopped.contains(AnyHashable($0.id)) && $0.hasEmptyContent }.map { AnyHashable($0.id) }
        )
        messages = hidden.isEmpty ? conversation : conversation.filter { !hidden.contains(AnyHashable($0.id)) }
        if pendingMessage?.id != exchange?.pending?.id {
            pendingMessage = exchange?.pending
        }
        let status = currentStatus
        if self.status != status {
            self.status = status
        }
        if composer.isGenerating != status.isAnswering {
            composer.isGenerating = status.isAnswering
        }
    }

    private var currentStatus: AIChatStatus {
        if exchange != nil {
            return .submitted
        }
        if let last = messages.last, last.role != .user, last.isGenerating, !stopped.contains(AnyHashable(last.id)) {
            return last.hasEmptyContent ? .submitted : .streaming
        }
        // The agent is working on the person's latest message, whose reply isn't here yet.
        if let activity, activity.state != .error, messages.last.map({ $0.role == .user }) ?? true {
            return .submitted
        }
        return error == nil ? .ready : .error
    }
}
