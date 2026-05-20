//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// An object which represents a livestream ``ChatChannel`` and its state.
///
/// Unlike ``Chat``, ``LivestreamChat`` operates without local database persistence.
/// It manages channel state in memory and communicates directly with the API. It
/// is more performant for high-throughput livestream channels but has fewer
/// features than ``Chat``, like for example:
/// - Read updates are not tracked.
/// - Replies / threads are not exposed.
public class LivestreamChat: AppStateObserverDelegate, @unchecked Sendable {
    private let client: ChatClient
    private let channelUpdater: ChannelUpdater
    private let apiClient: APIClient
    private let typingEventsSender: TypingEventsSender
    private let appStateObserver: AppStateObserving
    private let handler: LivestreamChannelHandler
    private var eventObserver: AnyCancellable?
    @MainActor private var stateBuilder: StateBuilder<LivestreamChatState>

    init(
        channelQuery: ChannelQuery,
        client: ChatClient,
        environment: Environment = .init()
    ) {
        self.client = client
        apiClient = client.apiClient
        appStateObserver = environment.appStateObserverBuilder()
        channelUpdater = environment.channelUpdaterBuilder(
            client.channelRepository,
            client.messageRepository,
            client.makeMessagesPaginationStateHandler(),
            client.databaseContainer,
            client.apiClient
        )
        typingEventsSender = environment.typingEventsSenderBuilder(
            client.databaseContainer,
            client.apiClient
        )
        handler = environment.handlerBuilder(
            channelQuery,
            client,
            client.makeMessagesPaginationStateHandler()
        )

        let handler = handler
        stateBuilder = StateBuilder { @MainActor in
            environment.livestreamChatStateBuilder(handler, client)
        }

        configureHandlerCallbacks()

        eventObserver = client.subscribe { [weak self] event in
            self?.didReceiveEvent(event)
        }
        appStateObserver.subscribe(self)

        if let cid = channelQuery.cid {
            client.eventNotificationCenter.registerManualEventHandling(for: cid)
        }
    }

    deinit {
        if let cid = handler.cid {
            client.eventNotificationCenter.unregisterManualEventHandling(for: cid)
        }
        appStateObserver.unsubscribe(self)
    }

    private func configureHandlerCallbacks() {
        handler.setHandlers(
            LivestreamChannelHandler.Handlers(
                channelDidChange: { [weak self] channel in
                    self?.stateBuilder.state.channel = channel
                },
                messagesDidChange: { [weak self] messages in
                    self?.stateBuilder.state.messages = messages
                },
                pauseDidChange: { [weak self] isPaused in
                    self?.stateBuilder.state.isPaused = isPaused
                },
                skippedMessagesAmountDidChange: { [weak self] skipped in
                    self?.stateBuilder.state.skippedMessagesAmount = skipped
                },
                typingUsersDidChange: { [weak self] typingUsers in
                    self?.stateBuilder.state.typingUsers = typingUsers
                }
            )
        )
    }

    func didReceiveEvent(_ event: Event) {
        handler.didReceiveEvent(event)

        if let notificationAddedToChannelEvent = event as? NotificationAddedToChannelEvent,
           notificationAddedToChannelEvent.cid == handler.cid {
            Task { try? await self.watch() }
        }
    }

    // MARK: - Accessing the State

    /// An observable object representing the current state of the livestream channel.
    @MainActor public var state: LivestreamChatState { stateBuilder.state }

    // MARK: - Configuration

    /// A Boolean value that indicates whether to load initial messages from the cache.
    ///
    /// Only the initial page will be loaded from cache, to avoid an initial blank screen.
    public var loadInitialMessagesFromCache: Bool {
        get { handler.loadInitialMessagesFromCache }
        set { handler.loadInitialMessagesFromCache = newValue }
    }

    /// A boolean value indicating if the controller should count the number of skipped messages when in pause state.
    public var countSkippedMessagesWhenPaused: Bool {
        get { handler.countSkippedMessagesWhenPaused }
        set { handler.countSkippedMessagesWhenPaused = newValue }
    }

    /// Configuration for message limiting behaviour.
    ///
    /// Disabled by default. If enabled, older messages will be automatically
    /// discarded once the limit is reached. The
    /// ``MaxMessageLimitOptions/recommended`` configuration is a sensible starting
    /// point with 200 max messages and a 50 messages discard amount.
    ///
    /// - Note: When using this option together with ``loadOlderMessages(before:limit:)``,
    /// call ``pause()`` before loading older messages so the pagination is not capped.
    /// Call ``resume()`` afterwards to start collecting new messages again. Sending a
    /// new message resumes automatically.
    public var maxMessageLimitOptions: MaxMessageLimitOptions? {
        get { handler.maxMessageLimitOptions }
        set { handler.maxMessageLimitOptions = newValue }
    }

    // MARK: - Watching the Channel

    /// Fetches the most recent state from the server and updates the in-memory state.
    ///
    /// - Important: Resets ``LivestreamChatState/messages`` and ``LivestreamChatState/channel``.
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func get() async throws {
        handler.populateFromCacheIfEnabled()
        client.syncRepository.startTrackingLivestreamChat(self)
        try await updateChannelData(channelQuery: handler.channelQuery)
    }

    /// Start watching the channel which enables server-side events.
    ///
    /// Watching queries the channel state and notifies the server to start sending events when anything in this channel changes.
    ///
    /// Please refer to [Watching a Channel](https://getstream.io/chat/docs/ios-swift/watch_channel/?language=swift) for additional information.
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func watch() async throws {
        let cid = try self.cid
        client.syncRepository.startTrackingLivestreamChat(self)
        try await channelUpdater.startWatching(cid: cid, isInRecoveryMode: false)
    }

    /// Stop watching the channel which disables server-side events.
    ///
    /// Please refer to [Watching a Channel](https://getstream.io/chat/docs/ios-swift/watch_channel/?language=swift) for additional information.
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func stopWatching() async throws {
        let cid = try self.cid
        client.syncRepository.stopTrackingLivestreamChat(self)
        try await channelUpdater.stopWatching(cid: cid)
    }

    // MARK: - Message Pagination

    /// Loads older messages before the specified message into ``LivestreamChatState/messages``.
    ///
    /// - Parameters:
    ///   - messageId: The message id of the message from which older messages are loaded. If nil, the id of the oldest loaded message is used.
    ///   - limit: The limit for the page size. The default limit is 25.
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func loadOlderMessages(before messageId: MessageId? = nil, limit: Int? = nil) async throws {
        let messageId = messageId
            ?? handler.paginationStateHandler.state.oldestFetchedMessage?.id
            ?? handler.messages.last?.id

        guard let messageId else { throw ClientError.ChannelEmptyMessages() }
        guard !handler.hasLoadedAllPreviousMessages, !handler.isLoadingPreviousMessages else { return }

        let limit = limit ?? handler.channelQuery.pagination?.pageSize ?? .messagesPageSize
        var query = handler.channelQuery
        query.pagination = MessagesPagination(pageSize: limit, parameter: .lessThan(messageId))

        try await updateChannelData(channelQuery: query)
    }

    /// Loads newer messages after the specified message into ``LivestreamChatState/messages``.
    ///
    /// - Parameters:
    ///   - messageId: The message id of the message from which newer messages are loaded. If nil, the id of the newest loaded message is used.
    ///   - limit: The limit for the page size. The default limit is 25.
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func loadNewerMessages(after messageId: MessageId? = nil, limit: Int? = nil) async throws {
        let messageId = messageId
            ?? handler.paginationStateHandler.state.newestFetchedMessage?.id
            ?? handler.messages.first?.id

        guard let messageId else { throw ClientError.ChannelEmptyMessages() }
        guard !handler.hasLoadedAllNextMessages, !handler.isLoadingNextMessages else { return }

        let limit = limit ?? handler.channelQuery.pagination?.pageSize ?? .messagesPageSize
        var query = handler.channelQuery
        query.pagination = MessagesPagination(pageSize: limit, parameter: .greaterThan(messageId))

        try await updateChannelData(channelQuery: query)
    }

    /// Loads messages around the given message id into ``LivestreamChatState/messages``.
    ///
    /// Useful for jumping to a message which hasn't been loaded yet.
    ///
    /// - Important: Jumping to a message resets ``LivestreamChatState/messages``.
    ///
    /// - Parameters:
    ///   - messageId: The message id of the middle message in the loaded list of messages.
    ///   - limit: The number of messages to load in total, including the message to jump to. The default limit is 25.
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func loadMessages(around messageId: MessageId, limit: Int? = nil) async throws {
        guard !handler.isLoadingMiddleMessages else { return }
        let limit = limit ?? handler.channelQuery.pagination?.pageSize ?? .messagesPageSize
        var query = handler.channelQuery
        query.pagination = MessagesPagination(pageSize: limit, parameter: .around(messageId))
        try await updateChannelData(channelQuery: query)
    }

    /// Cleans the current state and loads the first page again.
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func loadFirstPage() async throws {
        var query = handler.channelQuery
        query.pagination = MessagesPagination(
            pageSize: handler.channelQuery.pagination?.pageSize ?? .messagesPageSize,
            parameter: nil
        )
        try await updateChannelData(channelQuery: query)
    }

    // MARK: - Pause / Resume

    /// Pauses the collecting of new messages.
    ///
    /// When paused, new messages from other users will not be added to ``LivestreamChatState/messages``.
    public func pause() {
        handler.pause()
    }

    /// Resumes the collecting of new messages.
    ///
    /// This will load the first page, resetting ``LivestreamChatState/messages`` to the
    /// latest messages. After resuming, new messages will be added to
    /// ``LivestreamChatState/messages`` again.
    ///
    /// - Throws: An error while communicating with the Stream API.
    @MainActor public func resume() async throws {
        guard handler.isPaused, !state.isResuming else { return }

        handler.resetSkippedMessagesCountIfNeeded()

        state.isResuming = true
        defer { state.isResuming = false }
        defer { handler.resume() }
        try await loadFirstPage()
    }

    // MARK: - Sending Messages

    /// Sends a message to the channel.
    ///
    /// The send message method returns once the network request has been
    /// scheduled. The local message is added to ``LivestreamChatState/messages``
    /// optimistically while the request is in flight.
    ///
    /// - Parameters:
    ///   - text: Text of the message.
    ///   - attachments: An array of the attachments for the message.
    ///   - quotedMessageId: The id of the quoted message.
    ///   - mentions: An array of mentioned user ids.
    ///   - pinning: If pinning configuration is set, the message is pinned to the channel.
    ///   - silent: If true, the message doesn't increase the unread messages count and mark a channel as unread.
    ///   - skipPushNotification: If true, skips sending push notification to channel members.
    ///   - skipEnrichURL: If true, the url preview won't be attached to the message.
    ///   - restrictedVisibility: The list of user ids that should be able to see the message.
    ///   - extraData: Additional extra data of the message object.
    ///   - messageId: A custom id for the sent message. By default, it is automatically generated by Stream.
    ///
    /// - Throws: An error while sending a message to the Stream API.
    /// - Returns: The id of the message that was sent.
    @discardableResult
    public func sendMessage(
        with text: String,
        attachments: [AnyAttachmentPayload] = [],
        quote quotedMessageId: MessageId? = nil,
        mentions: [UserId] = [],
        pinning: MessagePinning? = nil,
        silent: Bool = false,
        skipPushNotification: Bool = false,
        skipEnrichURL: Bool = false,
        restrictedVisibility: [UserId] = [],
        extraData: [String: RawJSON] = [:],
        messageId: MessageId? = nil
    ) async throws -> MessageId {
        let cid = try self.cid

        var transformableInfo = NewMessageTransformableInfo(
            text: text,
            attachments: attachments,
            extraData: extraData
        )
        if let transformer = client.config.modelsTransformer {
            transformableInfo = transformer.transform(newMessageInfo: transformableInfo)
        }

        let localMessage = try await channelUpdater.createNewMessage(
            in: cid,
            messageId: messageId,
            text: transformableInfo.text,
            pinning: pinning,
            isSilent: silent,
            isSystem: false,
            command: nil,
            arguments: nil,
            attachments: transformableInfo.attachments,
            mentionedUserIds: mentions,
            quotedMessageId: quotedMessageId,
            skipPush: skipPushNotification,
            skipEnrichUrl: skipEnrichURL,
            restrictedVisibility: restrictedVisibility,
            extraData: transformableInfo.extraData
        )
        client.eventNotificationCenter.process(
            NewMessagePendingEvent(message: localMessage, cid: cid)
        )
        return localMessage.id
    }

    // MARK: - Message Actions

    /// Deletes the specified message.
    ///
    /// - Parameters:
    ///   - messageId: The id of the message to delete.
    ///   - hard: True, if the message should be permanently deleted. The default value is false.
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func deleteMessage(_ messageId: MessageId, hard: Bool = false) async throws {
        try await apiClient.request(endpoint: .deleteMessage(messageId: messageId, hard: hard))
    }

    /// Flags the specified message and forwards it for moderation.
    ///
    /// - Parameters:
    ///   - messageId: The id of the message to flag.
    ///   - reason: A reason why the message was flagged.
    ///   - extraData: Additional data associated with the flag request.
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func flagMessage(
        _ messageId: MessageId,
        reason: String? = nil,
        extraData: [String: RawJSON]? = nil
    ) async throws {
        try await apiClient.request(
            endpoint: .flagMessage(true, with: messageId, reason: reason, extraData: extraData)
        )
    }

    /// Removes the flag from the specified message.
    ///
    /// - Parameter messageId: The id of the message to be unflagged.
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func unflagMessage(_ messageId: MessageId) async throws {
        try await apiClient.request(
            endpoint: .flagMessage(false, with: messageId, reason: nil, extraData: nil)
        )
    }

    // MARK: - Message Reactions

    /// Adds a reaction to the specified message.
    ///
    /// - Parameters:
    ///   - messageId: The id of the message to send the reaction.
    ///   - type: The type that describes a message reaction.
    ///   - score: The score of the reaction for cumulative reactions.
    ///   - enforceUnique: If `true`, the added reaction will replace all reactions the user has on this message.
    ///   - skipPush: If set to `true`, skips sending push notification when reacting a message.
    ///   - pushEmojiCode: The emoji code for the reaction when a push notification is received.
    ///   - extraData: The reaction's extra data.
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func sendReaction(
        to messageId: MessageId,
        with type: MessageReactionType,
        score: Int = 1,
        enforceUnique: Bool = false,
        skipPush: Bool = false,
        pushEmojiCode: String? = nil,
        extraData: [String: RawJSON] = [:]
    ) async throws {
        try await apiClient.request(
            endpoint: .addReaction(
                type,
                score: score,
                enforceUnique: enforceUnique,
                extraData: extraData,
                skipPush: skipPush,
                emojiCode: pushEmojiCode,
                messageId: messageId
            )
        )
    }

    /// Removes a reaction with a specified type from a message.
    ///
    /// - Parameters:
    ///   - messageId: The id of the message to remove the reaction from.
    ///   - type: The reaction type to remove.
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func deleteReaction(from messageId: MessageId, with type: MessageReactionType) async throws {
        try await apiClient.request(endpoint: .deleteReaction(type, messageId: messageId))
    }

    /// Loads reactions for the specified message.
    ///
    /// - Parameters:
    ///   - messageId: The id of the message to load reactions for.
    ///   - limit: The number of reactions to load. Default is 25.
    ///   - offset: The starting position of the desired range to be fetched. Default is 0.
    ///
    /// - Throws: An error while communicating with the Stream API.
    /// - Returns: An array of reactions for the specified message.
    public func loadReactions(
        for messageId: MessageId,
        limit: Int = 25,
        offset: Int = 0
    ) async throws -> [ChatMessageReaction] {
        let pagination = Pagination(pageSize: limit, offset: offset)
        let payload: MessageReactionsPayload = try await apiClient.request(
            endpoint: .loadReactions(messageId: messageId, pagination: pagination)
        )
        return payload.reactions.compactMap { $0.asModel(messageId: messageId) }
    }

    // MARK: - Message Pinning

    /// Pins the message to the channel.
    ///
    /// - Parameter messageId: The id of the message to be pinned.
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func pinMessage(_ messageId: MessageId) async throws {
        try await apiClient.request(
            endpoint: .pinMessage(messageId: messageId, request: .init(set: .init(pinned: true)))
        )
    }

    /// Removes the message from the channel's pinned messages.
    ///
    /// - Parameter messageId: The id of the message to be unpinned.
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func unpinMessage(_ messageId: MessageId) async throws {
        try await apiClient.request(
            endpoint: .pinMessage(messageId: messageId, request: .init(set: .init(pinned: false)))
        )
    }

    /// Loads the pinned messages of the current channel.
    ///
    /// - Parameters:
    ///   - pageSize: The number of pinned messages to load. Default is 25.
    ///   - sorting: The sorting options. By default, results are sorted descending by `pinned_at` field.
    ///   - pagination: The pagination parameter. If `nil`, the most recently pinned messages are fetched.
    ///
    /// - Throws: An error while communicating with the Stream API.
    /// - Returns: The list of pinned messages.
    public func loadPinnedMessages(
        pageSize: Int = .messagesPageSize,
        sorting: [Sorting<PinnedMessagesSortingKey>] = [],
        pagination: PinnedMessagesPagination? = nil
    ) async throws -> [ChatMessage] {
        let cid = try self.cid
        let query = PinnedMessagesQuery(
            pageSize: pageSize,
            sorting: sorting,
            pagination: pagination
        )
        return try await channelUpdater.loadPinnedMessages(in: cid, query: query)
    }

    // MARK: - Slow Mode

    /// Enables slow mode which limits how often members can post new messages to the channel.
    ///
    /// - Parameter cooldownDuration: The time interval in seconds.
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func enableSlowMode(cooldownDuration: Int) async throws {
        let cid = try self.cid
        try await channelUpdater.enableSlowMode(cid: cid, cooldownDuration: cooldownDuration)
    }

    /// Disables slow mode for the channel.
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func disableSlowMode() async throws {
        let cid = try self.cid
        try await channelUpdater.enableSlowMode(cid: cid, cooldownDuration: 0)
    }

    // MARK: - Freezing the Channel

    /// Freezes the channel.
    ///
    /// Freezing a channel will disallow sending new messages and sending / deleting reactions.
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func freeze() async throws {
        let cid = try self.cid
        try await channelUpdater.freezeChannel(true, cid: cid)
    }

    /// Removes the frozen channel restriction.
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func unfreeze() async throws {
        let cid = try self.cid
        try await channelUpdater.freezeChannel(false, cid: cid)
    }

    // MARK: - Typing Indicator

    /// Sends a `typing.start` event in this channel to the server.
    ///
    /// Keystroke events are throttled and `stopTyping(parentMessageId:)` is automatically called after a couple of seconds from the last keystroke event.
    ///
    /// - Parameter parentMessageId: A message id of the message in a thread the user is replying to.
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func keystroke(parentMessageId: MessageId? = nil) async throws {
        let cid = try self.cid
        guard handler.channel?.canSendTypingEvents ?? false else { return }
        try await typingEventsSender.keystroke(in: cid, parentMessageId: parentMessageId)
    }

    /// Sends a `typing.stop` event in this channel to the server.
    ///
    /// - Parameter parentMessageId: A message id of the message in a thread the user is replying to.
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func stopTyping(parentMessageId: MessageId? = nil) async throws {
        let cid = try self.cid
        guard handler.channel?.canSendTypingEvents ?? false else { return }
        try await typingEventsSender.stopTyping(in: cid, parentMessageId: parentMessageId)
    }

    // MARK: - AppStateObserverDelegate

    public func applicationDidReceiveMemoryWarning() {
        Task { try? await loadFirstPage() }
    }

    public func applicationDidMoveToForeground() {
        if client.connectionStatus != .connected {
            Task { try? await loadFirstPage() }
        }
    }

    // MARK: - Private

    private func updateChannelData(channelQuery: ChannelQuery) async throws {
        handler.beginPagination(for: channelQuery)
        do {
            let payload = try await channelUpdater.update(channelQuery: channelQuery)
            handler.handleChannelPayload(payload, channelQuery: channelQuery)
        } catch {
            handler.handlePaginationFailure(channelQuery: channelQuery, error: error)
            throw error
        }
    }
}

// MARK: - Internal

extension LivestreamChat {
    var cid: ChannelId {
        get throws {
            guard let cid = handler.cid else { throw ClientError.ChannelNotCreatedYet() }
            return cid
        }
    }
}

// MARK: - Environment

extension LivestreamChat {
    struct Environment: Sendable {
        var livestreamChatStateBuilder: @Sendable @MainActor (
            _ handler: LivestreamChannelHandler,
            _ client: ChatClient
        ) -> LivestreamChatState = { @MainActor in
            LivestreamChatState(handler: $0, client: $1)
        }

        var channelUpdaterBuilder: @Sendable (
            _ channelRepository: ChannelRepository,
            _ messageRepository: MessageRepository,
            _ paginationStateHandler: MessagesPaginationStateHandling,
            _ database: DatabaseContainer,
            _ apiClient: APIClient
        ) -> ChannelUpdater = {
            ChannelUpdater(
                channelRepository: $0,
                messageRepository: $1,
                paginationStateHandler: $2,
                database: $3,
                apiClient: $4
            )
        }

        var typingEventsSenderBuilder: @Sendable (
            _ database: DatabaseContainer,
            _ apiClient: APIClient
        ) -> TypingEventsSender = { TypingEventsSender(database: $0, apiClient: $1) }

        var handlerBuilder: @Sendable (
            _ channelQuery: ChannelQuery,
            _ client: ChatClient,
            _ paginationStateHandler: MessagesPaginationStateHandling
        ) -> LivestreamChannelHandler = {
            LivestreamChannelHandler(
                channelQuery: $0,
                client: $1,
                paginationStateHandler: $2
            )
        }

        var appStateObserverBuilder: @Sendable () -> AppStateObserving = {
            StreamAppStateObserver()
        }
    }
}
