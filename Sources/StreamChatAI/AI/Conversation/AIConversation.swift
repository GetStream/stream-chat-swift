//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamCore

/// The state behind an AI conversation, and what the person does in it.
///
/// It holds the conversation's messages, where the latest exchange with the agent is and why it
/// failed, and it sends what the person asks through its ``AIConversationTransport``. Give it to
/// ``AIConversationView`` and ``AIComposerView``, which show it and act on it: sending, stopping,
/// regenerating and rating replies, and editing the person's latest message.
///
/// ```swift
/// @StateObject private var conversation = AIConversation(transport: AgentTransport(channel: channel))
///
/// var body: some View {
///     AIConversationView(conversation: conversation) {
///         if conversation.status == .error {
///             Button("Try again") { conversation.retry() }
///         }
///     }
///     .safeAreaInset(edge: .bottom) {
///         AIComposerView(conversation: conversation)
///     }
/// }
/// ```
///
/// What the person sends shows straight away, and the agent thinks until its reply starts. While
/// a reply is written again, or a message the person edited is answered again, the messages it
/// replaces are left out of ``messages`` until the new reply starts.
@available(iOS 15.0, macOS 12.0, *)
@MainActor
public final class AIConversation<Message: AIMessage>: ObservableObject {
    /// The conversation as it shows, oldest message first.
    @Published public private(set) var messages: [Message] = []
    /// The message the person sent last that is not in the conversation yet. It stays until its
    /// reply starts, and after it was stopped or failed, while ``retry()`` can send it again.
    @Published public private(set) var pendingMessage: AIPendingMessage?
    /// Where the latest exchange with the agent is.
    @Published public private(set) var status: AIConversationStatus = .ready
    /// Why the latest request failed, or, as an ``AIAgentError``, what the agent said when it
    /// couldn't answer or that it didn't answer in time. It stays until the next request, or
    /// until a reply starts after all.
    @Published public private(set) var error: (any Error)?
    /// What the agent says it is doing besides what its reply shows, such as checking sources.
    @Published public private(set) var activity: AIAgentActivity?
    /// Whether the conversation has messages before the first one, which
    /// ``loadOlderMessages()`` loads.
    @Published public private(set) var hasOlderMessages = false
    /// How the person rated replies, by the reply's id: the rating they gave on this device, or
    /// else the reply's own ``AIMessage/rating``.
    @Published public private(set) var ratings: [Message.ID: AIMessageRating] = [:]

    /// What the person is writing: ``AIComposerView`` shows it, and editing a message fills it.
    public let composerViewModel: AIComposerViewModel
    /// Who answers tool calls' questions and sign-ins on this device, which the conversation
    /// asks them.
    public let approver: AIToolApprover?
    /// What the conversation's views offer the person to do with its messages.
    public let actions: AIConversationActions

    /// The person's message they are editing in the composer, which the next message they send
    /// replaces. The composer shows that they are editing it, with a button that cancels it.
    public var editingMessage: Message? {
        composerViewModel.isEditing ? edited : nil
    }

    private let transport: TransportCalls
    private let replyTimeout: TimeInterval?
    // The messages as the transport last told them, including those left out of `messages`.
    private var received: [Message] = []
    // The latest request, until its reply starts or another request takes its place.
    private var exchange: AIConversationExchange<Message>?
    // Counts the requests and stops, so the outcome of one that was overtaken is ignored.
    private var generation = 0
    // Replies stopped while they were written, which are finished whatever they say.
    private var stopped: Set<AnyHashable> = []
    // Whether what the agent says it is doing is ignored, after it was stopped, until it stops
    // saying anything.
    private var ignoresActivity = false
    // The latest stop, which the next request waits for: the agent would stop that one too.
    private var stopping: Task<Void, Never>?
    // Ends the wait for the latest request's reply when the agent says nothing for too long.
    private var replyTimer: Task<Void, Never>?
    private var edited: Message?
    private var ratingChanges: [Message.ID: RatingChange] = [:]
    private var ratingAttempts = 0
    private var isLoadingOlderMessages = false

    // Lets the conversation view follow the conversation, whichever view holds it.
    lazy var changes = AIObservedChanges(objectWillChange)

    // The transport's requirements, so the conversation's type names only its messages.
    private struct TransportCalls {
        let send: @MainActor (AIConversationRequest<Message>) async throws -> Void
        let stop: @MainActor () async throws -> Void
        let loadOlderMessages: @MainActor () async throws -> Void
        let rate: @MainActor (Message, AIMessageRating?) async throws -> Void
    }

    // A rating the person gave a reply on this device, shown in place of the reply's own.
    private struct RatingChange {
        var shown: AIMessageRating?
        // What the transport has, which the rating goes back to when it can't take a new one.
        var sent: AIMessageRating?
        // Tells the latest rating of the reply apart from those before it.
        var attempt = 0
        // Sends the latest rating, after those before it.
        var sending: Task<Void, Never>?
    }

    /// - Parameters:
    ///   - transport: How the conversation reaches the agent and learns what it holds. The
    ///     conversation keeps it, and connects to it straight away.
    ///   - composerViewModel: What the person writes, such as one with your chat options. A new
    ///     one by default.
    ///   - approver: Who answers tool calls' questions and sign-ins on this device.
    ///   - actions: What the conversation's views offer: editing the person's latest message,
    ///     regenerating the latest reply and rating replies. All of them by default.
    ///   - replyTimeout: How many seconds the conversation waits, once the agent has the request,
    ///     for the agent to start its reply or say what it is doing, before it shows an
    ///     ``AIAgentError``. While the agent says it is working, such as thinking, it waits as long
    ///     as that takes. Five minutes by default; nil or `.infinity` waits as long as it takes.
    public init<Transport: AIConversationTransport>(
        transport: Transport,
        composerViewModel: AIComposerViewModel? = nil,
        approver: AIToolApprover? = nil,
        actions: AIConversationActions = .all,
        replyTimeout: TimeInterval? = 300
    ) where Transport.Message == Message {
        self.transport = TransportCalls(
            send: { try await transport.send($0) },
            stop: { try await transport.stop() },
            loadOlderMessages: { try await transport.loadOlderMessages() },
            rate: { try await transport.rate($0, $1) }
        )
        self.composerViewModel = composerViewModel ?? AIComposerViewModel()
        self.approver = approver
        self.actions = actions
        self.replyTimeout = replyTimeout
        transport.connect(AIConversationFeed(conversation: self))
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
        let editing = editingMessage
        edited = nil
        composerViewModel.isEditing = false
        start(
            AIConversationRequest(
                kind: editing == nil ? .message : .edit,
                text: text,
                attachments: attachments,
                chatOption: chatOption,
                message: editing
            )
        )
    }

    /// Sends what the person wrote in the composer.
    public func send(_ message: MessageData) {
        send(message.text, attachments: message.attachments, chatOption: message.chatOption)
    }

    /// Stops the reply the agent is writing. What it wrote so far stays. When the reply hasn't
    /// started yet, the person's message stays, and a reply that still arrives is finished
    /// whatever it says.
    public func stop() {
        guard status.isAnswering else { return }
        generation += 1
        let id = generation
        activity = nil
        ignoresActivity = true
        if exchange?.state == .waiting {
            exchange?.state = .stopped
        }
        let writing = writingReply
        if let writing {
            stopped.insert(writing)
        }
        refresh()
        let stop = transport.stop
        stopping = Task { [weak self] in
            do {
                try await stop()
            } catch {
                self?.stopFailed(id, writing: writing, error: error)
            }
        }
    }

    /// Asks the agent for a new reply in place of `reply`, and of those after it.
    public func regenerate(_ reply: Message) {
        guard let index = index(of: reply), received[index].role != .user else { return }
        start(regenerateRequest(at: index))
    }

    /// Puts a message of the person's in the composer to edit. The next message they send
    /// replaces it.
    public func edit(_ message: Message) {
        guard message.role == .user else { return }
        edited = message
        composerViewModel.text = message.text
        composerViewModel.isEditing = true
        composerViewModel.isTextFieldFocused = true
    }

    /// Stops editing a message, and empties the composer.
    public func cancelEditing() {
        guard editingMessage != nil else { return }
        edited = nil
        composerViewModel.cancelEditing()
    }

    /// Tries again after ``error``: sends the request that failed again, with the same message
    /// id, or asks the agent again for the reply it couldn't write.
    public func retry() {
        guard let exchange, exchange.hasFailed else { return }
        start(exchange.retryRequest(in: received))
    }

    /// Forgets ``error``, and the request that failed.
    public func clearError() {
        error = nil
        if exchange?.hasFailed == true {
            exchange = nil
        }
        refresh()
    }

    /// Rates a reply, or takes the rating back with nil. Ratings reach the transport in the
    /// order the person gives them, and the reply's rating goes back to the one the transport
    /// has if it can't take the new one.
    public func rate(_ reply: Message, _ rating: AIMessageRating?) {
        let current = ratings[reply.id]
        guard current != rating else { return }
        ratingAttempts += 1
        let attempt = ratingAttempts
        var change = ratingChanges[reply.id] ?? RatingChange(shown: current, sent: current)
        let earlier = change.sending
        change.shown = rating
        change.attempt = attempt
        change.sending = Task { [weak self] in
            await earlier?.value
            await self?.sendRating(rating, of: reply, attempt: attempt)
        }
        ratingChanges[reply.id] = change
        refresh()
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
        received = messages
        if let exchange, let reply = exchange.reply(in: messages) {
            receive(reply, to: exchange)
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
            // The agent stopped saying it is working without starting its reply.
            if let exchange, exchange.state == .waiting {
                waitForReply(to: exchange.id)
            }
            refresh()
            return
        }
        guard !ignoresActivity else { return }
        self.activity = activity
        if activity.state == .error {
            agentCouldNotAnswer(AIAgentError(message: activity.text))
        } else {
            // The agent is working on it, however long it thinks.
            replyTimer?.cancel()
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
        var onRate: (@MainActor (AIMessageRating?) -> Void)?
        if actions.contains(.rate) {
            onRate = { [weak self] rating in self?.rate(reply, rating) }
        }
        return AIReplyActions(rating: ratings[reply.id], onRegenerate: onRegenerate, onRate: onRate)
    }

    func offersRegenerate(isLatestReply: Bool) -> Bool {
        actions.contains(.regenerate) && isLatestReply && !status.isAnswering
    }

    // Edits a message of the person's, when it is their latest and the agent isn't answering.
    func editAction(for message: Message) -> (@MainActor () -> Void)? {
        guard offersEdit(message) else { return nil }
        return { [weak self] in self?.edit(message) }
    }

    func offersEdit(_ message: Message) -> Bool {
        guard actions.contains(.edit), message.role == .user, !status.isAnswering else { return false }
        return messages.last { $0.role == .user }.map { AnyHashable($0.id) == AnyHashable(message.id) } ?? false
    }

    // MARK: - Private

    private func start(_ request: AIConversationRequest<Message>) {
        generation += 1
        let id = generation
        error = nil
        activity = nil
        ignoresActivity = false
        stopped = []
        exchange = AIConversationExchange(id: id, request: request, conversation: received)
        refresh()
        let send = transport.send
        let previousStop = stopping
        Task { [weak self] in
            // The agent would stop a request that reaches it before the stop made before it.
            await previousStop?.value
            do {
                try await send(request)
                self?.requestSent(id)
            } catch {
                self?.requestFailed(id, error: error)
            }
        }
    }

    // The reply to the latest request arrived: once it shows something, or as soon as it
    // arrives after the person stopped the request.
    private func receive(_ reply: Message, to exchange: AIConversationExchange<Message>) {
        let id = AnyHashable(reply.id)
        if exchange.state == .stopped {
            if reply.isGenerating {
                stopped.insert(id)
            }
            self.exchange = nil
        } else if !reply.hasEmptyContent || !reply.isGenerating {
            self.exchange = nil
            if exchange.hasFailed {
                // The agent answered after all.
                error = nil
                stopped.remove(id)
            }
        }
    }

    private func requestSent(_ id: Int) {
        // The agent may already say it is working on it.
        guard let exchange, exchange.id == id, exchange.state == .waiting, activity == nil else { return }
        waitForReply(to: id)
    }

    private func requestFailed(_ id: Int, error: any Error) {
        // Its reply started, so the agent had it, another request took its place, or it
        // already failed.
        guard let exchange, exchange.id == id, !exchange.hasFailed else { return }
        if error is CancellationError {
            self.exchange = nil
        } else {
            self.exchange?.state = .failed
            self.error = error
        }
        refresh()
    }

    // The agent goes on answering, and the composer offers to stop it again.
    private func stopFailed(_ id: Int, writing: AnyHashable?, error: any Error) {
        guard id == generation, !(error is CancellationError) else { return }
        log.error("Couldn't stop the agent", error: error)
        if let writing {
            stopped.remove(writing)
        }
        if let exchange, exchange.state == .stopped {
            self.exchange?.state = .waiting
            waitForReply(to: exchange.id)
        }
        ignoresActivity = false
        refresh()
    }

    // The agent couldn't answer the latest request, or the latest message: what it was writing
    // is finished, and `retry()` asks it again.
    private func agentCouldNotAnswer(_ error: AIAgentError) {
        if let writing = writingReply {
            stopped.insert(writing)
        }
        if exchange == nil, let request = answerAgainRequest {
            generation += 1
            exchange = AIConversationExchange(id: generation, request: request, conversation: received)
        }
        exchange?.state = .unanswered
        self.error = error
    }

    private func waitForReply(to id: Int) {
        replyTimer?.cancel()
        guard let replyTimeout, replyTimeout.isFinite else { return }
        // Within what a UInt64 of nanoseconds holds, about 584 years.
        let nanoseconds = UInt64(min(max(replyTimeout, 0), 1_000_000_000) * 1_000_000_000)
        replyTimer = Task { [weak self] in
            try? await Task.sleep(nanoseconds: nanoseconds)
            guard !Task.isCancelled else { return }
            self?.replyTimedOut(id)
        }
    }

    private func replyTimedOut(_ id: Int) {
        guard let exchange, exchange.id == id, exchange.state == .waiting else { return }
        agentCouldNotAnswer(AIAgentError())
        refresh()
    }

    // Sends the latest rating of a reply. Those it replaced while one was on its way aren't.
    private func sendRating(_ rating: AIMessageRating?, of reply: Message, attempt: Int) async {
        guard ratingChanges[reply.id]?.attempt == attempt else { return }
        do {
            try await transport.rate(reply, rating)
            ratingChanges[reply.id]?.sent = rating
        } catch {
            log.error("Couldn't send the rating of a reply", error: error)
            guard let change = ratingChanges[reply.id], change.attempt == attempt else { return }
            ratingChanges[reply.id]?.shown = change.sent
            refresh()
        }
    }

    // Asks for a new reply in place of the one at `index`, to the person's message before it.
    private func regenerateRequest(at index: Int) -> AIConversationRequest<Message> {
        let prompt = received[..<index].last { $0.role == .user }
        return AIConversationRequest(kind: .regenerate, text: prompt?.text ?? "", message: received[index])
    }

    // Asks again for the latest message's reply: the reply written again, or one to the
    // person's message, which has none.
    private var answerAgainRequest: AIConversationRequest<Message>? {
        guard let last = received.indices.last else { return nil }
        guard received[last].role == .user else { return regenerateRequest(at: last) }
        return AIConversationRequest(kind: .regenerate, text: received[last].text)
    }

    // The latest reply, while the agent writes it.
    private var writingReply: AnyHashable? {
        guard let last = received.last, last.role != .user, last.isGenerating else { return nil }
        return AnyHashable(last.id)
    }

    private func index(of message: Message) -> Int? {
        received.firstIndex { AnyHashable($0.id) == AnyHashable(message.id) }
    }

    // Works out what the conversation shows and where it is, after anything changes.
    private func refresh() {
        let replaced = exchange?.state == .waiting ? exchange?.replaced : nil
        if replaced == nil && stopped.isEmpty {
            messages = received
        } else {
            messages = received.filter { message in
                let id = AnyHashable(message.id)
                // A reply stopped before it showed anything has nothing to show, and the
                // conversation would think it is still on its way.
                return replaced?[id] == nil && !(stopped.contains(id) && message.hasEmptyContent)
            }
        }
        let pending = exchange?.shownPending
        if pendingMessage?.id != pending?.id {
            pendingMessage = pending
        }
        let ratings = currentRatings
        if self.ratings != ratings {
            self.ratings = ratings
        }
        let status = currentStatus
        if self.status != status {
            self.status = status
        }
        if composerViewModel.isGenerating != status.isAnswering {
            composerViewModel.isGenerating = status.isAnswering
        }
    }

    private var currentRatings: [Message.ID: AIMessageRating] {
        var ratings: [Message.ID: AIMessageRating] = [:]
        for message in received where message.role != .user {
            ratings[message.id] = message.rating
        }
        for (id, change) in ratingChanges {
            ratings[id] = change.shown
        }
        return ratings
    }

    private var currentStatus: AIConversationStatus {
        if exchange?.state == .waiting {
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
