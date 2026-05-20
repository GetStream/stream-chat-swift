//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// The external contract used by ``LivestreamChannelController`` and ``LivestreamChat``
/// when collaborating with a livestream channel handler.
///
/// The protocol exposes a deliberately narrow surface: read-only access to the
/// in-memory state, read-write access to the configuration options, and the
/// lifecycle methods the wrappers need to call. Tests can substitute a mock
/// implementation without having to subclass the concrete
/// ``LivestreamChatHandler``, which keeps the concrete type `final` and its
/// stored state free from external mutation.
protocol LivestreamChatHandling: AnyObject {
    // MARK: - Configuration

    /// Configuration for message limiting behaviour.
    var maxMessageLimitOptions: MaxMessageLimitOptions? { get set }

    /// Whether the controller should count skipped messages while paused.
    var countSkippedMessagesWhenPaused: Bool { get set }

    /// Whether the handler should populate initial messages from the local cache.
    var loadInitialMessagesFromCache: Bool { get set }

    /// The timer scheduler used for the typing cleanup timers.
    var timerType: TimerScheduling.Type { get set }

    // MARK: - State

    /// The channel query backing this handler.
    var channelQuery: ChannelQuery { get }

    /// The channel id this handler observes.
    var cid: ChannelId? { get }

    /// The channel the handler represents.
    var channel: ChatChannel? { get }

    /// The messages of the channel the handler represents.
    var messages: [ChatMessage] { get }

    /// Whether message processing is currently paused.
    var isPaused: Bool { get }

    /// The amount of messages that were skipped during the pause state.
    var skippedMessagesAmount: Int { get }

    // MARK: - Pagination

    /// Whether all previous (older) messages have been loaded.
    var hasLoadedAllPreviousMessages: Bool { get }

    /// Whether all next (newer) messages have been loaded.
    var hasLoadedAllNextMessages: Bool { get }

    /// Whether a previous (older) page is currently loading.
    var isLoadingPreviousMessages: Bool { get }

    /// Whether a next (newer) page is currently loading.
    var isLoadingNextMessages: Bool { get }

    /// Whether a page around a specific message is currently loading.
    var isLoadingMiddleMessages: Bool { get }

    /// Whether the handler is currently in a mid-page state.
    var isJumpingToMessage: Bool { get }

    /// The id of the oldest message fetched so far, if any.
    var oldestFetchedMessageId: MessageId? { get }

    /// The id of the newest message fetched so far, if any.
    var newestFetchedMessageId: MessageId? { get }

    // MARK: - Lifecycle

    /// Registers the closures that are invoked when state changes.
    func setHandlers(_ handlers: LivestreamChatHandler.Handlers)

    /// Loads the initial messages from the data store when enabled.
    func populateFromCacheIfEnabled()

    /// Applies the freshly-fetched channel payload to the in-memory state.
    func handleChannelPayload(_ payload: ChannelPayload, channelQuery: ChannelQuery)

    /// Marks pagination as failed without mutating in-memory data.
    func handlePaginationFailure(channelQuery: ChannelQuery, error: Error)

    /// Begins a pagination request for the given query.
    func beginPagination(for channelQuery: ChannelQuery)

    /// Pauses the collecting of new messages.
    func pause()

    /// Resumes the collecting of new messages.
    func resume()

    /// Resets only the skipped messages counter, leaving the pause state alone.
    func resetSkippedMessagesCountIfNeeded()

    /// Clears the messages array.
    func clearMessages()

    /// Routes an event to the appropriate handler.
    func didReceiveEvent(_ event: Event)

    /// Returns the current cooldown time for the channel, or `0` when slow
    /// mode is not active.
    func currentCooldownTime() -> Int
}

/// Shared in-memory state and event handling for livestream channels.
///
/// This handler encapsulates the logic that is common between
/// ``LivestreamChannelController`` and ``LivestreamChat``:
/// - The in-memory channel and messages state.
/// - Pause / skipped messages bookkeeping.
/// - The typing cleanup timers that compensate for the lack of
///   `TypingStartCleanupMiddleware` on livestream channels.
/// - The handling of channel-specific events (messages, reactions, members,
///   watchers, typing, etc.).
///
/// State changes are surfaced through a ``Handlers`` struct whose closures are
/// always invoked on the main thread, matching the existing controller's
/// delegate dispatching behavior.
///
/// The class is `final` and its stored state is only externally observable via
/// the ``LivestreamChatHandling`` protocol. The remaining `var` properties
/// are intentionally module-internal so the handler's own private logic and
/// its tests can drive the state directly, while public wrappers and mocks
/// interact with the handler exclusively through the protocol's read-only
/// surface.
final class LivestreamChatHandler: LivestreamChatHandling, DataStoreProvider, @unchecked Sendable {
    // MARK: - Configuration

    /// Configuration for message limiting behaviour.
    var maxMessageLimitOptions: MaxMessageLimitOptions?

    /// Whether the controller should count skipped messages while paused.
    var countSkippedMessagesWhenPaused: Bool = false

    /// Whether the handler should populate initial messages from the local cache.
    var loadInitialMessagesFromCache: Bool = true

    /// The timer scheduler used for the typing cleanup timers.
    var timerType: TimerScheduling.Type = DefaultTimer.self

    // MARK: - Stored State

    /// The channel query backing this handler.
    var channelQuery: ChannelQuery

    /// The channel id this handler observes.
    var cid: ChannelId? { channelQuery.cid }

    /// The channel the handler represents.
    var channel: ChatChannel? {
        didSet {
            guard let channel else { return }
            handlerCallback { $0.channelDidChange(channel) }
        }
    }

    /// The messages of the channel the handler represents.
    var messages: [ChatMessage] = [] {
        didSet {
            let captured = messages
            handlerCallback { $0.messagesDidChange(captured) }
        }
    }

    /// Whether message processing is currently paused.
    var isPaused: Bool = false {
        didSet {
            let captured = isPaused
            handlerCallback { $0.pauseDidChange(captured) }
        }
    }

    /// The amount of messages that were skipped during the pause state.
    var skippedMessagesAmount: Int = 0 {
        didSet {
            let captured = skippedMessagesAmount
            handlerCallback { $0.skippedMessagesAmountDidChange(captured) }
        }
    }

    // MARK: - Pagination

    let paginationStateHandler: MessagesPaginationStateHandling

    var hasLoadedAllPreviousMessages: Bool {
        paginationStateHandler.state.hasLoadedAllPreviousMessages
    }

    var hasLoadedAllNextMessages: Bool {
        paginationStateHandler.state.hasLoadedAllNextMessages || messages.isEmpty
    }

    var isLoadingPreviousMessages: Bool {
        paginationStateHandler.state.isLoadingPreviousMessages
    }

    var isLoadingNextMessages: Bool {
        paginationStateHandler.state.isLoadingNextMessages
    }

    var isLoadingMiddleMessages: Bool {
        paginationStateHandler.state.isLoadingMiddleMessages
    }

    var isJumpingToMessage: Bool {
        paginationStateHandler.state.isJumpingToMessage
    }

    var oldestFetchedMessageId: MessageId? {
        paginationStateHandler.state.oldestFetchedMessage?.id
    }

    var newestFetchedMessageId: MessageId? {
        paginationStateHandler.state.newestFetchedMessage?.id
    }

    // MARK: - Dependencies

    let client: ChatClient

    private var currentUserId: UserId? { client.currentUserId }

    /// Per-user typing cleanup timers. Required because livestream channels
    /// bypass `TypingStartCleanupMiddleware`.
    private var typingCleanupTimers: [UserId: TimerControl] = [:]

    // MARK: - Handlers

    /// Closures invoked on the main thread when state changes.
    struct Handlers {
        var channelDidChange: @MainActor (ChatChannel) -> Void
        var messagesDidChange: @MainActor ([ChatMessage]) -> Void
        var pauseDidChange: @MainActor (Bool) -> Void
        var skippedMessagesAmountDidChange: @MainActor (Int) -> Void
        var typingUsersDidChange: @MainActor (Set<ChatUser>) -> Void
    }

    private var handlers: Handlers?

    func setHandlers(_ handlers: Handlers) {
        self.handlers = handlers
    }

    // MARK: - Initialization

    init(
        channelQuery: ChannelQuery,
        client: ChatClient,
        paginationStateHandler: MessagesPaginationStateHandling = MessagesPaginationStateHandler()
    ) {
        self.channelQuery = channelQuery
        self.client = client
        self.paginationStateHandler = paginationStateHandler
    }

    deinit {
        typingCleanupTimers.values.forEach { $0.cancel() }
    }

    // MARK: - Mutation API

    func setChannelQuery(_ query: ChannelQuery) {
        channelQuery = query
    }

    /// Loads the initial messages from the data store when enabled.
    func populateFromCacheIfEnabled() {
        guard loadInitialMessagesFromCache,
              let cid,
              let cachedChannel = dataStore.channel(cid: cid) else {
            return
        }
        channel = cachedChannel
        messages = cachedChannel.latestMessages
    }

    /// Applies the freshly-fetched channel payload to the in-memory state.
    func handleChannelPayload(_ payload: ChannelPayload, channelQuery: ChannelQuery) {
        paginationStateHandler.end(pagination: channelQuery.pagination, with: .success(payload.messages))

        let newChannel = payload.asModel(
            currentUserId: currentUserId,
            currentlyTypingUsers: channel?.currentlyTypingUsers,
            unreadCount: channel?.unreadCount
        )

        channel = newChannel

        let newMessages = payload.messages.compactMap {
            $0.asModel(cid: payload.channel.cid, currentUserId: currentUserId, channelReads: newChannel.reads)
        }

        updateMessagesArray(with: newMessages, pagination: channelQuery.pagination)
    }

    /// Marks pagination as failed without mutating in-memory data.
    func handlePaginationFailure(channelQuery: ChannelQuery, error: Error) {
        paginationStateHandler.end(pagination: channelQuery.pagination, with: .failure(error))
    }

    /// Begins a pagination request for the given query.
    func beginPagination(for channelQuery: ChannelQuery) {
        paginationStateHandler.begin(pagination: channelQuery.pagination)
    }

    /// Pauses the collecting of new messages.
    func pause() {
        guard !isPaused else { return }
        isPaused = true
    }

    /// Resumes the collecting of new messages.
    ///
    /// The caller is responsible for reloading the first page; this method only
    /// flips the pause flag back to false and optionally resets the skipped
    /// messages counter.
    func resume() {
        if countSkippedMessagesWhenPaused {
            skippedMessagesAmount = 0
        }
        isPaused = false
    }

    /// Resets only the skipped messages counter, leaving the pause state alone.
    func resetSkippedMessagesCountIfNeeded() {
        guard countSkippedMessagesWhenPaused, skippedMessagesAmount != 0 else { return }
        skippedMessagesAmount = 0
    }

    /// Clears the messages array.
    func clearMessages() {
        messages = []
    }

    // MARK: - Events

    /// Routes an event to the appropriate handler.
    func didReceiveEvent(_ event: Event) {
        if let channelEvent = event as? ChannelSpecificEvent, channelEvent.cid == cid {
            handleChannelEvent(event)
        }

        // User deleted messages is a global event, not tied to a channel.
        if let userMessagesDeletedEvent = event as? UserMessagesDeletedEvent {
            let userId = userMessagesDeletedEvent.user.id
            if userMessagesDeletedEvent.hardDelete {
                hardDeleteMessages(from: userId)
            } else {
                let deletedAt = userMessagesDeletedEvent.createdAt
                softDeleteMessages(from: userId, deletedAt: deletedAt)
            }
        }
    }

    // MARK: - Private

    private func handlerCallback(_ callback: @escaping @MainActor (Handlers) -> Void) {
        guard let handlers else { return }
        DispatchQueue.main.async {
            callback(handlers)
        }
    }

    private func updateMessagesArray(with newMessages: [ChatMessage], pagination: MessagesPagination?) {
        let newMessages = Array(newMessages.reversed())
        switch pagination?.parameter {
        case .lessThan, .lessThanOrEqual:
            messages.append(contentsOf: newMessages)

        case .greaterThan, .greaterThanOrEqual:
            messages.insert(contentsOf: newMessages, at: 0)

        case .around, .none:
            messages = newMessages
        }
    }

    private func applyMessageLimit() {
        guard let options = maxMessageLimitOptions,
              messages.count > options.maxLimit else {
            return
        }

        let newCount = options.maxLimit - options.discardAmount
        messages = Array(messages.prefix(newCount))
    }

    private func handleChannelEvent(_ event: Event) {
        switch event {
        case let messageNewEvent as MessageNewEvent:
            handleNewMessage(messageNewEvent.message)

            // Apply message limit only when not paused
            if !isPaused {
                applyMessageLimit()
            }

        case let localMessageNewEvent as NewMessagePendingEvent:
            if isPaused {
                break
            }

            handleNewMessage(localMessageNewEvent.message)

        case let messageUpdatedEvent as MessageUpdatedEvent:
            handleUpdatedMessage(messageUpdatedEvent.message)

        case let messageDeletedEvent as MessageDeletedEvent:
            if messageDeletedEvent.isHardDelete {
                handleDeletedMessage(messageDeletedEvent.message)
                return
            }
            let deletedMessage = messageDeletedEvent.message.changing(
                deletedAt: messageDeletedEvent.createdAt
            )
            handleUpdatedMessage(deletedMessage)

        case let newMessageErrorEvent as NewMessageErrorEvent:
            guard let message = messages.first(where: { $0.id == newMessageErrorEvent.messageId }) else {
                return
            }
            let errorMessage = message.changing(state: .sendingFailed)
            handleUpdatedMessage(errorMessage)

        case let reactionNewEvent as ReactionNewEvent:
            updateMessage(reactionNewEvent.message)

        case let reactionUpdatedEvent as ReactionUpdatedEvent:
            updateMessage(reactionUpdatedEvent.message)

        case let reactionDeletedEvent as ReactionDeletedEvent:
            updateMessage(reactionDeletedEvent.message)

        case let channelUpdatedEvent as ChannelUpdatedEvent:
            handleChannelUpdated(channelUpdatedEvent)

        case let notificationAddedToChannelEvent as NotificationAddedToChannelEvent:
            var members = Set(channel?.lastActiveMembers ?? [])
            members.insert(notificationAddedToChannelEvent.member)
            let memberCount = channel?.memberCount ?? 0
            channel = channel?.changing(
                members: Array(members),
                membership: notificationAddedToChannelEvent.member,
                memberCount: memberCount + 1
            )

        case let notificationRemovedFromChannelEvent as NotificationRemovedFromChannelEvent:
            var members = channel?.lastActiveMembers ?? []
            members.removeAll(where: { $0.id == notificationRemovedFromChannelEvent.user.id })
            let memberCount = channel?.memberCount ?? 0

            channel = channel?.changing(members: members, memberCount: memberCount - 1)
            channel?.membership = nil

        case let memberAddedEvent as MemberAddedEvent:
            var members = Set(channel?.lastActiveMembers ?? [])
            members.insert(memberAddedEvent.member)
            let memberCount = channel?.memberCount ?? 0

            var membership: ChatChannelMember?
            if memberAddedEvent.member.id == currentUserId {
                membership = memberAddedEvent.member
            }
            channel = channel?.changing(
                members: Array(members),
                membership: membership,
                memberCount: memberCount + 1
            )

        case let memberRemovedEvent as MemberRemovedEvent:
            var members = channel?.lastActiveMembers ?? []
            members.removeAll(where: { $0.id == memberRemovedEvent.user.id })
            let memberCount = channel?.memberCount ?? 0

            var membership: ChatChannelMember? = channel?.membership
            if memberRemovedEvent.user.id == currentUserId {
                membership = nil
            }
            channel = channel?.changing(members: members, memberCount: memberCount - 1)
            channel?.membership = membership

        case let userWatchingEvent as UserWatchingEvent:
            var watchers = channel?.lastActiveWatchers ?? []
            if userWatchingEvent.isStarted {
                watchers.append(userWatchingEvent.user)
            } else {
                watchers.removeAll(where: { $0.id == userWatchingEvent.user.id })
            }
            channel = channel?.changing(watchers: watchers, watcherCount: userWatchingEvent.watcherCount)

        case let memberUpdatedEvent as MemberUpdatedEvent:
            var members = channel?.lastActiveMembers ?? []
            if let index = members.firstIndex(where: { $0.id == memberUpdatedEvent.member.id }) {
                members[index] = memberUpdatedEvent.member
            }

            var membership: ChatChannelMember? = channel?.membership
            if memberUpdatedEvent.member.id == currentUserId {
                membership = memberUpdatedEvent.member
            }

            channel = channel?.changing(members: members, membership: membership)

        case is UserBannedEvent,
             is UserUnbannedEvent:
            updateChannelFromDataStore()

        case let channelTruncatedEvent as ChannelTruncatedEvent:
            channel = channelTruncatedEvent.channel
            if let message = channelTruncatedEvent.message {
                messages = [message]
            } else {
                messages = []
            }

        case let typingEvent as TypingEvent:
            handleTypingEvent(typingEvent)

        default:
            break
        }
    }

    private func handleTypingEvent(_ event: TypingEvent) {
        // The current user's typing state is sent over the wire, but we don't want to render
        // ourselves in our own typing indicator. This matches `TypingStartCleanupMiddleware`.
        guard event.user.id != currentUserId else { return }

        // Thread typing events should not affect the channel-level typing indicator.
        guard event.parentId == nil else { return }

        let currentTypingUsers = channel?.currentlyTypingUsers ?? []
        let userId = event.user.id

        if event.isTyping {
            scheduleTypingCleanup(for: event.user)
            var nextTypingUsers = currentTypingUsers.filter { $0.id != userId }
            nextTypingUsers.insert(event.user)
            updateCurrentlyTypingUsers(nextTypingUsers)
        } else {
            cancelTypingCleanup(for: userId)
            // No-op when the user wasn't tracked locally (e.g. we joined mid-typing).
            // Avoids allocating a filtered copy of the set for every spurious stop event.
            guard currentTypingUsers.contains(where: { $0.id == userId }) else { return }
            updateCurrentlyTypingUsers(currentTypingUsers.filter { $0.id != userId })
        }
    }

    private func scheduleTypingCleanup(for user: ChatUser) {
        let userId = user.id
        cancelTypingCleanup(for: userId)
        // Capture only `userId` so the timer doesn't retain a full `ChatUser` value
        // (and the strings/dates it references) for up to 30 seconds.
        typingCleanupTimers[userId] = timerType.schedule(
            timeInterval: .incomingTypingStartEventTimeout,
            queue: .main
        ) { [weak self] in
            self?.removeTypingUser(withId: userId)
        }
    }

    private func cancelTypingCleanup(for userId: UserId) {
        typingCleanupTimers[userId]?.cancel()
        typingCleanupTimers[userId] = nil
    }

    private func removeTypingUser(withId userId: UserId) {
        cancelTypingCleanup(for: userId)
        guard let currentTypingUsers = channel?.currentlyTypingUsers,
              currentTypingUsers.contains(where: { $0.id == userId }) else { return }
        let typingUsers = currentTypingUsers.filter { $0.id != userId }
        updateCurrentlyTypingUsers(typingUsers)
    }

    private func updateCurrentlyTypingUsers(_ typingUsers: Set<ChatUser>) {
        let previousIds = Set((channel?.currentlyTypingUsers ?? []).map(\.id))
        let newIds = Set(typingUsers.map(\.id))
        guard previousIds != newIds else { return }
        channel = channel?.changing(currentlyTypingUsers: typingUsers)
        let captured = typingUsers
        handlerCallback { $0.typingUsersDidChange(captured) }
    }

    private func handleNewMessage(_ message: ChatMessage) {
        // If message already exists, update it instead
        if messages.contains(where: { $0.id == message.id }) {
            handleUpdatedMessage(message)
            return
        }

        // If paused and the message is not from the current user, skip processing
        if countSkippedMessagesWhenPaused, isPaused && message.author.id != currentUserId {
            skippedMessagesAmount += 1
            return
        }

        // If we don't have the first page loaded, do not insert new messages
        // they will be inserted once we load the first page again.
        if !hasLoadedAllNextMessages {
            return
        }

        messages.insert(message, at: 0)
    }

    private func handleUpdatedMessage(_ updatedMessage: ChatMessage) {
        if let index = messages.firstIndex(where: { $0.id == updatedMessage.id }) {
            let existingMessage = messages[index]
            messages[index] = updatedMessage

            if existingMessage.isPinned != updatedMessage.isPinned {
                updatePinnedMessages(for: updatedMessage)
            }
        } else if updatedMessage.isPinned || channel?.pinnedMessages.contains(where: { $0.id == updatedMessage.id }) == true {
            updatePinnedMessages(for: updatedMessage)
        }
    }

    private func updatePinnedMessages(for message: ChatMessage) {
        var pinnedMessages = channel?.pinnedMessages ?? []
        if message.isPinned {
            if !pinnedMessages.contains(where: { $0.id == message.id }) {
                pinnedMessages.append(message)
            }
        } else {
            pinnedMessages.removeAll(where: { $0.id == message.id })
        }
        channel = channel?.changing(pinnedMessages: pinnedMessages)
    }

    private func handleDeletedMessage(_ deletedMessage: ChatMessage) {
        messages.removeAll { $0.id == deletedMessage.id }
    }

    private func softDeleteMessages(from userId: UserId, deletedAt: Date) {
        let messagesWithDeletedMessages = messages.map { message in
            if message.author.id == userId {
                return message.changing(
                    deletedAt: deletedAt
                )
            }
            return message
        }
        messages = messagesWithDeletedMessages
    }

    private func hardDeleteMessages(from userId: UserId) {
        messages.removeAll { message in
            message.author.id == userId
        }
    }

    private func updateMessage(_ updatedMessage: ChatMessage) {
        if let messageIndex = messages.firstIndex(where: { $0.id == updatedMessage.id }) {
            messages[messageIndex] = updatedMessage
        }
    }

    private func handleChannelUpdated(_ event: ChannelUpdatedEvent) {
        channel = channel?.changing(
            name: event.channel.name,
            imageURL: event.channel.imageURL,
            lastMessageAt: event.channel.lastMessageAt,
            createdAt: event.channel.createdAt,
            deletedAt: event.channel.deletedAt,
            updatedAt: event.channel.updatedAt,
            truncatedAt: event.channel.truncatedAt,
            isHidden: event.channel.isHidden,
            createdBy: event.channel.createdBy,
            config: event.channel.config,
            filterTags: event.channel.filterTags,
            ownCapabilities: event.channel.ownCapabilities,
            isFrozen: event.channel.isFrozen,
            isDisabled: event.channel.isDisabled,
            isBlocked: event.channel.isBlocked,
            reads: event.channel.reads,
            members: event.channel.lastActiveMembers,
            membership: event.channel.membership,
            memberCount: event.channel.memberCount,
            watchers: event.channel.lastActiveWatchers,
            watcherCount: event.channel.watcherCount,
            team: event.channel.team,
            cooldownDuration: event.channel.cooldownDuration,
            extraData: event.channel.extraData
        )
    }

    /// For events that do not have the channel data, and still go through the
    /// middleware, fetch the channel from the DB and update it.
    private func updateChannelFromDataStore() {
        guard let cid = cid, let updatedChannel = dataStore.channel(cid: cid) else {
            return
        }
        channel = updatedChannel
    }

    // MARK: - Cooldown

    /// Returns the current cooldown time for the channel. Returns 0 in case
    /// there is no cooldown active.
    func currentCooldownTime() -> Int {
        guard let cooldownDuration = channel?.cooldownDuration, cooldownDuration > 0,
              let currentUserLatestMessage = messages.first(where: { $0.author.id == currentUserId }),
              channel?.ownCapabilities.contains(.skipSlowMode) == false else {
            return 0
        }

        let currentTime = Date().timeIntervalSince(currentUserLatestMessage.createdAt)
        return max(0, cooldownDuration - Int(currentTime))
    }
}
