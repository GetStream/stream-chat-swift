//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

public extension ChatClient {
    /// Creates a new `LivestreamChannelController` for the given channel query.
    /// - Parameter channelQuery: The query to observe the channel.
    /// - Returns: A new `LivestreamChannelController` instance.
    func livestreamChannelController(for channelQuery: ChannelQuery) -> LivestreamChannelController {
        LivestreamChannelController(channelQuery: channelQuery, client: self)
    }
}

/// A controller for managing livestream channels that operates without local database persistence.
///
/// Unlike `ChatChannelController`, this controller manages all data in memory and communicates directly with the API.
/// It is more performant than `ChatChannelController` but is more simpler and it has less features, like for example:
/// - Read updates
/// - etc..
public class LivestreamChannelController: AppStateObserverDelegate, @unchecked Sendable {
    public typealias Delegate = LivestreamChannelControllerDelegate

    // MARK: - Public Properties

    /// The ChannelQuery this controller observes.
    public var channelQuery: ChannelQuery { handler.channelQuery }

    /// The identifier of a channel this controller observes.
    public var cid: ChannelId? { handler.cid }

    /// The `ChatClient` instance this controller belongs to.
    public let client: ChatClient

    /// The channel the controller represents.
    public var channel: ChatChannel? { handler.channel }

    /// The messages of the channel the controller represents.
    public var messages: [ChatMessage] { handler.messages }

    /// A Boolean value that indicates whether message processing is paused.
    ///
    /// When paused, new messages from other users will not be added to the messages array.
    /// This is useful when loading previous messages to prevent the array from being modified.
    public var isPaused: Bool { handler.isPaused }

    private var isResuming: Bool = false

    /// The amount of messages that were skipped during the pause state.
    public var skippedMessagesAmount: Int { handler.skippedMessagesAmount }

    /// A Boolean value that returns whether the oldest messages have all been loaded or not.
    public var hasLoadedAllPreviousMessages: Bool { handler.hasLoadedAllPreviousMessages }

    /// A Boolean value that returns whether the newest messages have all been loaded or not.
    public var hasLoadedAllNextMessages: Bool { handler.hasLoadedAllNextMessages }

    /// A Boolean value that returns whether the channel is currently loading previous (old) messages.
    public var isLoadingPreviousMessages: Bool { handler.isLoadingPreviousMessages }

    /// A Boolean value that returns whether the channel is currently loading next (new) messages.
    public var isLoadingNextMessages: Bool { handler.isLoadingNextMessages }

    /// A Boolean value that returns whether the channel is currently loading a page around a message.
    public var isLoadingMiddleMessages: Bool { handler.isLoadingMiddleMessages }

    /// A Boolean value that returns whether the channel is currently in a mid-page.
    public var isJumpingToMessage: Bool { handler.isJumpingToMessage }

    /// A Boolean value that indicates whether to load initial messages from the cache.
    ///
    /// Only the initial page will be loaded from cache, to avoid an initial blank screen.
    public var loadInitialMessagesFromCache: Bool {
        get { handler.loadInitialMessagesFromCache }
        set { handler.loadInitialMessagesFromCache = newValue }
    }

    /// A boolean value indicating if the controller should count the number o skipped messages when in pause state.
    public var countSkippedMessagesWhenPaused: Bool {
        get { handler.countSkippedMessagesWhenPaused }
        set { handler.countSkippedMessagesWhenPaused = newValue }
    }

    /// Configuration for message limiting behaviour.
    ///
    /// Disabled by default. If enabled, older messages will be automatically discarded
    /// once the limit is reached. The `MaxMessageLimitOptions.recommended` is the recommended
    /// configuration which uses 200 max messages with 50 discard amount.
    /// This can be used to further improve the memory usage of the controller.
    ///
    /// - Note: In order to use this, if you want to support loading previous messages,
    /// you will need to use `pause()` method before loading older messages. Otherwise the
    /// pagination will also be capped. Once the user scrolls back to the newest messages, you
    /// can call `resume()`. Whenever the user creates a new message, the controller will
    /// automatically resume.
    public var maxMessageLimitOptions: MaxMessageLimitOptions? {
        get { handler.maxMessageLimitOptions }
        set { handler.maxMessageLimitOptions = newValue }
    }

    /// Set the delegate to observe the changes in the system.
    public var delegate: LivestreamChannelControllerDelegate? {
        get { multicastDelegate.mainDelegate }
        set { multicastDelegate.set(mainDelegate: newValue) }
    }

    /// A type-erased multicast delegate.
    internal var multicastDelegate: MulticastDelegate<LivestreamChannelControllerDelegate> = .init()

    // MARK: - Private Properties

    /// The handler encapsulating the shared livestream state and event handling.
    let handler: LivestreamChannelHandler

    /// The API client for making direct API calls.
    private let apiClient: APIClient

    /// The channel updater to reuse actions from channel controller which is safe to use without DB.
    private let updater: ChannelUpdater

    /// The app state observer for monitoring memory warnings and app state changes.
    private let appStateObserver: AppStateObserving

    /// The current user id.
    private var currentUserId: UserId? { client.currentUserId }

    /// Sends typing events (keystroke/start/stop) for the current user.
    private lazy var typingEventsSender: TypingEventsSender = TypingEventsSender(
        database: client.databaseContainer,
        apiClient: client.apiClient
    )

    /// The timer scheduler used for the auto-stop typing cleanup.
    var timerType: TimerScheduling.Type {
        get { handler.timerType }
        set { handler.timerType = newValue }
    }

    /// An internal backing object for all publicly available Combine publishers.
    var basePublishers: BasePublishers {
        if let value = _basePublishers as? BasePublishers {
            return value
        }
        _basePublishers = BasePublishers(controller: self)
        return _basePublishers as? BasePublishers ?? .init(controller: self)
    }

    var _basePublishers: Any?
    private var eventObserver: AnyCancellable?

    // MARK: - Initialization

    /// Creates a new `LivestreamChannelController`
    /// - Parameters:
    ///   - channelQuery: channel query for observing changes
    ///   - client: The `Client` this controller belongs to.
    init(
        channelQuery: ChannelQuery,
        client: ChatClient,
        updater: ChannelUpdater? = nil,
        paginationStateHandler: MessagesPaginationStateHandling = MessagesPaginationStateHandler()
    ) {
        self.client = client
        apiClient = client.apiClient
        appStateObserver = StreamAppStateObserver()
        self.updater = updater ?? ChannelUpdater(
            channelRepository: client.channelRepository,
            messageRepository: client.messageRepository,
            paginationStateHandler: client.makeMessagesPaginationStateHandler(),
            database: client.databaseContainer,
            apiClient: client.apiClient
        )
        handler = LivestreamChannelHandler(
            channelQuery: channelQuery,
            client: client,
            paginationStateHandler: paginationStateHandler
        )

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
        if let cid {
            client.eventNotificationCenter.unregisterManualEventHandling(for: cid)
        }
        appStateObserver.unsubscribe(self)
    }

    private func configureHandlerCallbacks() {
        handler.setHandlers(
            LivestreamChannelHandler.Handlers(
                channelDidChange: { [weak self] channel in
                    guard let self else { return }
                    self.multicastDelegate.invoke {
                        $0.livestreamChannelController(self, didUpdateChannel: channel)
                    }
                },
                messagesDidChange: { [weak self] messages in
                    guard let self else { return }
                    self.multicastDelegate.invoke {
                        $0.livestreamChannelController(self, didUpdateMessages: messages)
                    }
                },
                pauseDidChange: { [weak self] isPaused in
                    guard let self else { return }
                    self.multicastDelegate.invoke {
                        $0.livestreamChannelController(self, didChangePauseState: isPaused)
                    }
                },
                skippedMessagesAmountDidChange: { [weak self] skipped in
                    guard let self else { return }
                    self.multicastDelegate.invoke {
                        $0.livestreamChannelController(self, didChangeSkippedMessagesAmount: skipped)
                    }
                },
                typingUsersDidChange: { [weak self] typingUsers in
                    guard let self else { return }
                    self.multicastDelegate.invoke {
                        $0.livestreamChannelController(self, didChangeTypingUsers: typingUsers)
                    }
                }
            )
        )
    }

    // MARK: - Public Methods

    /// Synchronizes the controller with the backend data.
    /// - Parameter completion: Called when the synchronization is finished.
    public func synchronize(_ completion: (@MainActor (_ error: Error?) -> Void)? = nil) {
        handler.populateFromCacheIfEnabled()
        client.syncRepository.startTrackingLivestreamController(self)

        updateChannelData(
            channelQuery: channelQuery,
            completion: completion
        )
    }

    /// Start watching a channel
    ///
    /// - Parameter completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    public func startWatching(isInRecoveryMode: Bool, completion: (@MainActor (Error?) -> Void)? = nil) {
        guard let cid = cid else {
            let error = ClientError.ChannelNotCreatedYet()
            callback {
                completion?(error)
            }
            return
        }

        client.syncRepository.startTrackingLivestreamController(self)

        updater.startWatching(cid: cid, isInRecoveryMode: isInRecoveryMode) { error in
            self.callback {
                completion?(error)
            }
        }
    }

    /// Stop watching a channel
    ///
    /// - Parameter completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    public func stopWatching(completion: (@MainActor (Error?) -> Void)? = nil) {
        guard let cid = cid else {
            let error = ClientError.ChannelNotCreatedYet()
            callback {
                completion?(error)
            }
            return
        }

        client.syncRepository.stopTrackingLivestreamController(self)

        updater.stopWatching(cid: cid) { error in
            self.callback {
                completion?(error)
            }
        }
    }

    /// Loads previous (older) messages from backend.
    /// - Parameters:
    ///   - messageId: ID of the last fetched message. You will get messages `older` than the provided ID.
    ///   - limit: Limit for page size. By default it is 25.
    ///   - completion: Called when the network request is finished.
    public func loadPreviousMessages(
        before messageId: MessageId? = nil,
        limit: Int? = nil,
        completion: (@MainActor (Error?) -> Void)? = nil
    ) {
        guard cid != nil else {
            callback {
                completion?(ClientError.ChannelNotCreatedYet())
            }
            return
        }

        let messageId = messageId
            ?? handler.paginationStateHandler.state.oldestFetchedMessage?.id
            ?? messages.last?.id

        guard let messageId = messageId else {
            callback {
                completion?(ClientError.ChannelEmptyMessages())
            }
            return
        }

        guard !hasLoadedAllPreviousMessages && !isLoadingPreviousMessages else {
            callback {
                completion?(nil)
            }
            return
        }

        let limit = limit ?? channelQuery.pagination?.pageSize ?? .messagesPageSize
        var query = channelQuery
        query.pagination = MessagesPagination(pageSize: limit, parameter: .lessThan(messageId))

        updateChannelData(channelQuery: query, completion: completion)
    }

    /// Loads next messages from backend.
    /// - Parameters:
    ///   - messageId: ID of the current first message. You will get messages `newer` than the provided ID.
    ///   - limit: Limit for page size. By default it is 25.
    ///   - completion: Called when the network request is finished.
    public func loadNextMessages(
        after messageId: MessageId? = nil,
        limit: Int? = nil,
        completion: (@MainActor (Error?) -> Void)? = nil
    ) {
        guard cid != nil else {
            callback {
                completion?(ClientError.ChannelNotCreatedYet())
            }
            return
        }

        let messageId = messageId
            ?? handler.paginationStateHandler.state.newestFetchedMessage?.id
            ?? messages.first?.id

        guard let messageId = messageId else {
            callback {
                completion?(ClientError.ChannelEmptyMessages())
            }
            return
        }

        guard !hasLoadedAllNextMessages && !isLoadingNextMessages else {
            callback {
                completion?(nil)
            }
            return
        }

        let limit = limit ?? channelQuery.pagination?.pageSize ?? .messagesPageSize
        var query = channelQuery
        query.pagination = MessagesPagination(pageSize: limit, parameter: .greaterThan(messageId))

        updateChannelData(channelQuery: query, completion: completion)
    }

    /// Load messages around the given message id.
    /// - Parameters:
    ///   - messageId: The message id of the message to jump to.
    ///   - limit: The number of messages to load in total, including the message to jump to.
    ///   - completion: Callback when the API call is completed.
    public func loadPageAroundMessageId(
        _ messageId: MessageId,
        limit: Int? = nil,
        completion: (@MainActor (Error?) -> Void)? = nil
    ) {
        guard !isLoadingMiddleMessages else {
            callback {
                completion?(nil)
            }
            return
        }

        let limit = limit ?? channelQuery.pagination?.pageSize ?? .messagesPageSize
        var query = channelQuery
        query.pagination = MessagesPagination(pageSize: limit, parameter: .around(messageId))

        updateChannelData(channelQuery: query, completion: completion)
    }

    /// Cleans the current state and loads the first page again.
    /// - Parameter completion: Callback when the API call is completed.
    public func loadFirstPage(_ completion: (@MainActor (_ error: Error?) -> Void)? = nil) {
        var query = channelQuery
        query.pagination = .init(
            pageSize: channelQuery.pagination?.pageSize ?? .messagesPageSize,
            parameter: nil
        )

        updateChannelData(channelQuery: query, completion: completion)
    }

    /// Creates a new message and schedules it for send.
    ///
    /// This is the only method that still uses the DB to create data.
    /// This is mostly to reuse the complex logic of the Message Sender.
    ///
    /// - Parameters:
    ///   - messageId: The id for the sent message. By default, it is automatically generated by Stream.
    ///   - text: Text of the message.
    ///   - pinning: Pins the new message. `nil` if should not be pinned.
    ///   - isSilent: A flag indicating whether the message is a silent message. Silent messages are special messages that don't increase the unread messages count nor mark a channel as unread.
    ///   - attachments: An array of the attachments for the message.
    ///     `Note`: can be built-in types, custom attachment types conforming to `AttachmentEnvelope` protocol
    ///     and `ChatMessageAttachmentSeed`s.
    ///   - quotedMessageId: An id of the message new message quotes. (inline reply)
    ///   - skipPush: If true, skips sending push notification to channel members.
    ///   - skipEnrichUrl: If true, the url preview won't be attached to the message.
    ///   - restrictedVisibility: The list of user ids that should be able to see the message.
    ///   - location: The new location information of the message.
    ///   - extraData: Additional extra data of the message object.
    ///   - completion: Called when saving the message to the local DB finishes.
    public func createNewMessage(
        messageId: MessageId? = nil,
        text: String,
        pinning: MessagePinning? = nil,
        isSilent: Bool = false,
        attachments: [AnyAttachmentPayload] = [],
        mentionedUserIds: [UserId] = [],
        quotedMessageId: MessageId? = nil,
        skipPush: Bool = false,
        skipEnrichUrl: Bool = false,
        restrictedVisibility: [UserId] = [],
        location: NewLocationInfo? = nil,
        extraData: [String: RawJSON] = [:],
        completion: (@MainActor (Result<MessageId, Error>) -> Void)? = nil
    ) {
        var transformableInfo = NewMessageTransformableInfo(
            text: text,
            attachments: attachments,
            extraData: extraData
        )
        if let transformer = client.config.modelsTransformer {
            transformableInfo = transformer.transform(newMessageInfo: transformableInfo)
        }

        createNewMessage(
            messageId: messageId,
            text: transformableInfo.text,
            pinning: pinning,
            isSilent: isSilent,
            attachments: transformableInfo.attachments,
            mentionedUserIds: mentionedUserIds,
            quotedMessageId: quotedMessageId,
            skipPush: skipPush,
            skipEnrichUrl: skipEnrichUrl,
            restrictedVisibility: restrictedVisibility,
            location: location,
            extraData: transformableInfo.extraData,
            poll: nil,
            completion: completion
        )
    }

    /// Deletes a message from the channel.
    /// - Parameters:
    ///   - messageId: The message identifier to delete.
    ///   - hard: A Boolean value to determine if the message will be delete permanently on the backend. By default it is `false`.
    ///   - completion: Called when the network request is finished.
    ///   If request fails, the completion will be called with an error.
    public func deleteMessage(
        messageId: MessageId,
        hard: Bool = false,
        completion: (@MainActor (Error?) -> Void)? = nil
    ) {
        apiClient.request(
            endpoint: .deleteMessage(
                messageId: messageId,
                hard: hard
            )
        ) { [weak self] result in
            self?.callback {
                completion?(result.error)
            }
        }
    }

    /// Loads reactions for a specific message.
    /// - Parameters:
    ///   - messageId: The message identifier to load reactions for.
    ///   - limit: The number of reactions to load. Default is 25.
    ///   - offset: The starting position from the desired range to be fetched. Default is 0.
    ///   - completion: Called when the network request is finished. Returns reactions array or error.
    public func loadReactions(
        for messageId: MessageId,
        limit: Int = 25,
        offset: Int = 0,
        completion: @escaping @MainActor (Result<[ChatMessageReaction], Error>) -> Void
    ) {
        let pagination = Pagination(pageSize: limit, offset: offset)
        apiClient.request(
            endpoint: .loadReactions(messageId: messageId, pagination: pagination)
        ) { [weak self] result in
            self?.callback {
                switch result {
                case .success(let payload):
                    let reactions = payload.reactions.compactMap {
                        $0.asModel(messageId: messageId)
                    }
                    completion(.success(reactions))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }

    /// Flags a message.
    /// - Parameters:
    ///   - messageId: The message identifier to flag.
    ///   - reason: The flag reason.
    ///   - extraData: Additional data associated with the flag request.
    ///   - completion: Called when the network request is finished.
    ///   If request fails, the completion will be called with an error.
    public func flag(
        messageId: MessageId,
        reason: String? = nil,
        extraData: [String: RawJSON]? = nil,
        completion: (@MainActor (Error?) -> Void)? = nil
    ) {
        apiClient.request(
            endpoint: .flagMessage(
                true,
                with: messageId,
                reason: reason,
                extraData: extraData
            )
        ) { [weak self] result in
            self?.callback {
                completion?(result.error)
            }
        }
    }

    /// Unflags a message.
    /// - Parameters:
    ///   - messageId: The message identifier to unflag.
    ///   - completion: Called when the network request is finished.
    ///   If request fails, the completion will be called with an error.
    public func unflag(
        messageId: MessageId,
        completion: (@MainActor (Error?) -> Void)? = nil
    ) {
        apiClient.request(
            endpoint: .flagMessage(
                false,
                with: messageId,
                reason: nil,
                extraData: nil
            )
        ) { [weak self] result in
            self?.callback {
                completion?(result.error)
            }
        }
    }

    /// Adds a new reaction to a message.
    /// - Parameters:
    ///   - type: The reaction type.
    ///   - messageId: The message identifier to add the reaction to.
    ///   - score: The reaction score.
    ///   - enforceUnique: If set to `true`, new reaction will replace all reactions the user has (if any) on this message.
    ///   - skipPush: If set to `true`, skips sending push notification when reacting a message.
    ///   - pushEmojiCode: The emoji code when receiving a reaction push notification.
    ///   - extraData: The reaction extra data.
    ///   - completion: The completion. Will be called when the network request is finished.
    public func addReaction(
        _ type: MessageReactionType,
        to messageId: MessageId,
        score: Int = 1,
        enforceUnique: Bool = false,
        skipPush: Bool = false,
        pushEmojiCode: String? = nil,
        extraData: [String: RawJSON] = [:],
        completion: (@MainActor (Error?) -> Void)? = nil
    ) {
        apiClient.request(
            endpoint: .addReaction(
                type,
                score: score,
                enforceUnique: enforceUnique,
                extraData: extraData,
                skipPush: skipPush,
                emojiCode: pushEmojiCode,
                messageId: messageId
            )
        ) { [weak self] result in
            self?.callback {
                completion?(result.error)
            }
        }
    }

    /// Deletes a reaction from a message.
    /// - Parameters:
    ///   - type: The reaction type to delete.
    ///   - messageId: The message identifier to delete the reaction from.
    ///   - completion: Called when the network request is finished. If request fails, the completion will be called with an error.
    public func deleteReaction(
        _ type: MessageReactionType,
        from messageId: MessageId,
        completion: (@MainActor (Error?) -> Void)? = nil
    ) {
        apiClient.request(endpoint: .deleteReaction(type, messageId: messageId)) { [weak self] result in
            self?.callback {
                completion?(result.error)
            }
        }
    }

    /// Pins a message.
    /// - Parameters:
    ///   - messageId: The message identifier to pin.
    ///   - completion: Called when the network request is finished. If request fails, the completion will be called with an error.
    public func pin(
        messageId: MessageId,
        completion: (@MainActor (Error?) -> Void)? = nil
    ) {
        apiClient.request(endpoint: .pinMessage(
            messageId: messageId,
            request: .init(set: .init(pinned: true))
        )) { [weak self] result in
            self?.callback {
                completion?(result.error)
            }
        }
    }

    /// Pins a message.
    /// - Parameters:
    ///   - messageId: The message identifier to pin.
    ///   - pinning: This parameter is ignored. `LivestreamChannelController` does not persist messages locally, so pin expirations have no effect.
    ///   - completion: Called when the network request is finished. If request fails, the completion will be called with an error.
    @available(*, deprecated, message: "The pinning parameter has no effect. Use pin(messageId:completion:) instead.")
    public func pin(
        messageId: MessageId,
        pinning: MessagePinning,
        completion: (@MainActor (Error?) -> Void)? = nil
    ) {
        pin(messageId: messageId, completion: completion)
    }

    /// Unpins a message.
    /// - Parameters:
    ///   - messageId: The message identifier to unpin.
    ///   - completion: Called when the network request is finished. If request fails, the completion will be called with an error.
    public func unpin(
        messageId: MessageId,
        completion: (@MainActor (Error?) -> Void)? = nil
    ) {
        apiClient.request(
            endpoint: .pinMessage(
                messageId: messageId,
                request: .init(set: .init(pinned: false))
            )
        ) { [weak self] result in
            self?.callback {
                completion?(result.error)
            }
        }
    }

    /// Loads the pinned messages of the current channel.
    ///
    /// - Parameters:
    ///   - pageSize: The number of pinned messages to load. Equals to `25` by default.
    ///   - sorting: The sorting options. By default, results are sorted descending by `pinned_at` field.
    ///   - pagination: The pagination parameter. If `nil` is provided, most recently pinned messages are fetched.
    public func loadPinnedMessages(
        pageSize: Int = .messagesPageSize,
        sorting: [Sorting<PinnedMessagesSortingKey>] = [],
        pagination: PinnedMessagesPagination? = nil,
        completion: @escaping @MainActor (Result<[ChatMessage], Error>) -> Void
    ) {
        guard let cid else {
            callback {
                completion(.failure(ClientError.ChannelNotCreatedYet()))
            }
            return
        }

        let query = PinnedMessagesQuery(
            pageSize: pageSize,
            sorting: sorting,
            pagination: pagination
        )

        apiClient.request(endpoint: .pinnedMessages(cid: cid, query: query)) { [weak self] result in
            self?.callback {
                switch result {
                case .success(let payload):
                    let reads = self?.channel?.reads ?? []
                    let currentUserId = self?.client.currentUserId
                    let messages = payload.messages.map {
                        $0.asModel(
                            cid: cid,
                            currentUserId: currentUserId,
                            channelReads: reads
                        )
                    }
                    completion(.success(messages))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }

    // Returns the current cooldown time for the channel. Returns 0 in case there is no cooldown active.
    public func currentCooldownTime() -> Int {
        handler.currentCooldownTime()
    }

    /// Enables slow mode for the channel
    ///
    /// When slow mode is enabled, users can only send a message every `cooldownDuration` time interval.
    /// `cooldownDuration` is specified in seconds, and should be between 1-120.
    /// For more information, please check [documentation](https://getstream.io/chat/docs/javascript/slow_mode/?language=swift).
    ///
    /// - Parameters:
    ///   - cooldownDuration: Duration of the time interval users have to wait between messages.
    ///   Specified in seconds. Should be between 1-120.
    ///   - completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    public func enableSlowMode(cooldownDuration: Int, completion: (@MainActor (Error?) -> Void)? = nil) {
        guard let cid else {
            callback {
                completion?(ClientError.ChannelNotCreatedYet())
            }
            return
        }

        apiClient.request(
            endpoint: .enableSlowMode(cid: cid, cooldownDuration: cooldownDuration)
        ) { result in
            self.callback {
                completion?(result.error)
            }
        }
    }

    /// Freezes the channel.
    ///
    /// Freezing a channel will disallow sending new messages and sending / deleting reactions.
    /// For more information, see https://getstream.io/chat/docs/ios-swift/freezing_channels/?language=swift
    ///
    /// - Parameter completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    public func freezeChannel(completion: (@MainActor (Error?) -> Void)? = nil) {
        guard let cid else {
            callback {
                completion?(ClientError.ChannelNotCreatedYet())
            }
            return
        }

        updater.freezeChannel(true, cid: cid) { error in
            self.callback {
                completion?(error)
            }
        }
    }

    /// Unfreezes the channel.
    ///
    /// Unfreezing a channel will allow sending new messages and sending / deleting reactions again.
    /// For more information, see https://getstream.io/chat/docs/ios-swift/freezing_channels/?language=swift
    ///
    /// - Parameter completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    public func unfreezeChannel(completion: (@MainActor (Error?) -> Void)? = nil) {
        guard let cid else {
            callback {
                completion?(ClientError.ChannelNotCreatedYet())
            }
            return
        }

        updater.freezeChannel(false, cid: cid) { error in
            self.callback {
                completion?(error)
            }
        }
    }

    /// Disables slow mode for the channel
    ///
    /// For more information, please check [documentation](https://getstream.io/chat/docs/javascript/slow_mode/?language=swift).
    ///
    /// - Parameters:
    ///   - completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    public func disableSlowMode(completion: (@MainActor (Error?) -> Void)? = nil) {
        guard let cid else {
            callback {
                completion?(ClientError.ChannelNotCreatedYet())
            }
            return
        }

        updater.disableSlowMode(cid: cid) { error in
            self.callback {
                completion?(error)
            }
        }
    }

    // MARK: - Typing

    /// Sends the start typing event and schedules a timer to send the stop typing event.
    ///
    /// This method is meant to be called every time the user presses a key. The method will manage requests and timer as needed.
    ///
    /// - Parameters:
    ///   - parentMessageId: A message id of the message in a thread the user is replying to.
    ///   - completion: a completion block with an error if the request was failed.
    public func sendKeystrokeEvent(
        parentMessageId: MessageId? = nil,
        completion: (@MainActor (Error?) -> Void)? = nil
    ) {
        sendTypingEvent(failsWhenDisabled: false, completion: completion) { cid, sendCompletion in
            typingEventsSender.keystroke(in: cid, parentMessageId: parentMessageId, completion: sendCompletion)
        }
    }

    /// Sends the start typing event.
    ///
    /// For the majority of cases, you don't need to call `sendStartTypingEvent` directly. Instead, use `sendKeystrokeEvent`
    /// method and call it every time the user presses a key. The controller will manage
    /// `sendStartTypingEvent`/`sendStopTypingEvent` calls automatically.
    ///
    /// - Parameters:
    ///   - parentMessageId: A message id of the message in a thread the user is replying to.
    ///   - completion: a completion block with an error if the request was failed.
    public func sendStartTypingEvent(
        parentMessageId: MessageId? = nil,
        completion: (@MainActor (Error?) -> Void)? = nil
    ) {
        sendTypingEvent(failsWhenDisabled: true, completion: completion) { cid, sendCompletion in
            typingEventsSender.startTyping(in: cid, parentMessageId: parentMessageId, completion: sendCompletion)
        }
    }

    /// Sends the stop typing event.
    ///
    /// For the majority of cases, you don't need to call `sendStopTypingEvent` directly. Instead, use `sendKeystrokeEvent`
    /// method and call it every time the user presses a key. The controller will manage
    /// `sendStartTypingEvent`/`sendStopTypingEvent` calls automatically.
    ///
    /// - Parameters:
    ///   - parentMessageId: A message id of the message in a thread the user is replying to.
    ///   - completion: a completion block with an error if the request was failed.
    public func sendStopTypingEvent(
        parentMessageId: MessageId? = nil,
        completion: (@MainActor (Error?) -> Void)? = nil
    ) {
        sendTypingEvent(failsWhenDisabled: true, completion: completion) { cid, sendCompletion in
            typingEventsSender.stopTyping(in: cid, parentMessageId: parentMessageId, completion: sendCompletion)
        }
    }

    /// Shared boilerplate for the three public typing-event entry points.
    ///
    /// - Parameters:
    ///   - failsWhenDisabled: When `true`, the completion receives a
    ///     `ChannelFeatureDisabled` error if typing events are disabled. When `false`
    ///     (used by `sendKeystrokeEvent`) the completion is invoked with `nil` so a
    ///     disabled channel is treated as a silent no-op.
    ///   - completion: The caller's completion handler.
    ///   - send: Performs the underlying send once a valid `cid` and an enabled
    ///     channel have been confirmed.
    private func sendTypingEvent(
        failsWhenDisabled: Bool,
        completion: (@MainActor (Error?) -> Void)?,
        send: (ChannelId, @escaping @Sendable (Error?) -> Void) -> Void
    ) {
        guard let cid = cid else {
            callback { completion?(ClientError.ChannelNotCreatedYet()) }
            return
        }
        guard canSendTypingEvents else {
            callback {
                completion?(failsWhenDisabled
                    ? ClientError.ChannelFeatureDisabled("Channel feature: typing events is disabled for this channel.")
                    : nil)
            }
            return
        }
        send(cid) { [weak self] error in
            self?.callback { completion?(error) }
        }
    }

    /// A boolean value indicating if typing events can be sent.
    private var canSendTypingEvents: Bool {
        channel?.canSendTypingEvents ?? false
    }

    /// Pauses the collecting of new messages.
    ///
    /// When paused, new messages from other users will not be added to the messages array.
    /// This is useful for the loading of previous message to not conflict with the max limit of the messages array.
    public func pause() {
        handler.pause()
    }

    /// Resumes the collecting of new messages.
    ///
    /// This will load the first page, reseting the current messages  and returning to the latest messages.
    /// After resuming, new messages will be added to the messages array again.
    public func resume(completion: (@MainActor (Error?) -> Void)? = nil) {
        guard isPaused, !isResuming else {
            callback {
                completion?(nil)
            }
            return
        }

        handler.resetSkippedMessagesCountIfNeeded()

        isResuming = true
        loadFirstPage { [weak self] error in
            self?.handler.resume()
            self?.isResuming = false
            completion?(error)
        }
    }

    // MARK: - Events

    func didReceiveEvent(_ event: Event) {
        handler.didReceiveEvent(event)

        if let notificationAddedToChannelEvent = event as? NotificationAddedToChannelEvent,
           notificationAddedToChannelEvent.cid == cid {
            startWatching(isInRecoveryMode: false)
        }
    }

    // MARK: - AppStateObserverDelegate

    public func applicationDidReceiveMemoryWarning() {
        // Reset the channel to free up memory by loading the first page
        loadFirstPage()
    }

    public func applicationDidMoveToForeground() {
        // The livestream controller is not impacted by the syncing of missing events.
        // Since it won't get notified about messages updated from the DB.
        // So we need to manually reset the channel once the user is connected again.
        if client.connectionStatus != .connected {
            loadFirstPage()
        }
    }

    // MARK: - Private Methods

    private func updateChannelData(
        channelQuery: ChannelQuery,
        completion: (@MainActor (Error?) -> Void)? = nil
    ) {
        handler.beginPagination(for: channelQuery)

        let requestCompletion: @Sendable (Result<ChannelPayload, Error>) -> Void = { [weak self] result in
            self?.callback { [weak self] in
                guard let self = self else { return }

                switch result {
                case .success(let payload):
                    self.handler.handleChannelPayload(payload, channelQuery: channelQuery)
                    completion?(nil)

                case .failure(let error):
                    self.handler.handlePaginationFailure(channelQuery: channelQuery, error: error)
                    completion?(error)
                }
            }
        }

        updater.update(
            channelQuery: channelQuery,
            isInRecoveryMode: false,
            completion: requestCompletion
        )
    }

    /// Helper method to execute the callbacks on the main thread.
    private func callback(_ action: @MainActor @escaping () -> Void) {
        DispatchQueue.main.async {
            action()
        }
    }

    private func createNewMessage(
        messageId: MessageId? = nil,
        text: String,
        pinning: MessagePinning? = nil,
        isSilent: Bool = false,
        attachments: [AnyAttachmentPayload] = [],
        mentionedUserIds: [UserId] = [],
        quotedMessageId: MessageId? = nil,
        skipPush: Bool = false,
        skipEnrichUrl: Bool = false,
        restrictedVisibility: [UserId] = [],
        location: NewLocationInfo? = nil,
        extraData: [String: RawJSON] = [:],
        poll: PollPayload?,
        completion: (@MainActor (Result<MessageId, Error>) -> Void)? = nil
    ) {
        /// Perform action only if channel is already created on backend side and have a valid `cid`.
        guard let cid = cid else {
            let error = ClientError.ChannelNotCreatedYet()
            callback {
                completion?(.failure(error))
            }
            return
        }

        updater.createNewMessage(
            in: cid,
            messageId: messageId,
            text: text,
            pinning: pinning,
            isSilent: isSilent,
            isSystem: false,
            command: nil,
            arguments: nil,
            attachments: attachments,
            mentionedUserIds: mentionedUserIds,
            quotedMessageId: quotedMessageId,
            skipPush: skipPush,
            skipEnrichUrl: skipEnrichUrl,
            restrictedVisibility: restrictedVisibility,
            poll: poll,
            location: location,
            extraData: extraData
        ) { result in
            if let newMessage = try? result.get() {
                self.client.eventNotificationCenter.process(
                    NewMessagePendingEvent(
                        message: newMessage,
                        cid: cid
                    )
                )
            }
            self.callback {
                completion?(result.map(\.id))
            }
        }
    }
}

// MARK: - Delegate Protocol

/// Delegate protocol for `LivestreamChannelController`
@MainActor
public protocol LivestreamChannelControllerDelegate: AnyObject {
    /// Called when the channel data is updated.
    /// - Parameters:
    ///   - controller: The controller that updated.
    ///   - channel: The updated channel the controller manages.
    func livestreamChannelController(
        _ controller: LivestreamChannelController,
        didUpdateChannel channel: ChatChannel
    )

    /// Called when the messages are updated.
    /// - Parameters:
    ///   - controller: The controller that updated.
    ///   - messages: The current messages array.
    func livestreamChannelController(
        _ controller: LivestreamChannelController,
        didUpdateMessages messages: [ChatMessage]
    )

    /// Called when the pause state changes.
    /// - Parameters:
    ///   - controller: The controller that updated.
    ///   - isPaused: The new pause state.
    func livestreamChannelController(
        _ controller: LivestreamChannelController,
        didChangePauseState isPaused: Bool
    )

    /// Called when the skipped messages amount changes.
    func livestreamChannelController(
        _ controller: LivestreamChannelController,
        didChangeSkippedMessagesAmount skippedMessagesAmount: Int
    )

    /// Called when the set of currently typing users in the channel changes.
    /// - Parameters:
    ///   - controller: The controller that updated.
    ///   - typingUsers: The current set of users typing in the channel (excludes thread typing events).
    func livestreamChannelController(
        _ controller: LivestreamChannelController,
        didChangeTypingUsers typingUsers: Set<ChatUser>
    )
}

// MARK: - Default Implementations

public extension LivestreamChannelControllerDelegate {
    func livestreamChannelController(
        _ controller: LivestreamChannelController,
        didUpdateChannel channel: ChatChannel
    ) {}

    func livestreamChannelController(
        _ controller: LivestreamChannelController,
        didUpdateMessages messages: [ChatMessage]
    ) {}

    func livestreamChannelController(
        _ controller: LivestreamChannelController,
        didChangePauseState isPaused: Bool
    ) {}

    func livestreamChannelController(
        _ controller: LivestreamChannelController,
        didChangeSkippedMessagesAmount skippedMessagesAmount: Int
    ) {}

    func livestreamChannelController(
        _ controller: LivestreamChannelController,
        didChangeTypingUsers typingUsers: Set<ChatUser>
    ) {}
}

/// Configuration options for message limiting in LivestreamChannelController.
public struct MaxMessageLimitOptions: Sendable {
    /// The maximum number of messages to keep in memory.
    /// When this limit is reached, older messages will be discarded.
    public let maxLimit: Int

    /// The number of messages to discard when the maximum limit is reached.
    /// This should be less than maxLimit to avoid discarding all messages.
    public let discardAmount: Int

    /// Creates a new MaxMessageLimitOptions configuration.
    /// - Parameters:
    ///   - maxLimit: The maximum number of messages to keep. Default is 200.
    ///   - discardAmount: The number of messages to discard when limit is reached. Default is 50.
    public init(maxLimit: Int = 200, discardAmount: Int = 50) {
        self.maxLimit = maxLimit
        self.discardAmount = discardAmount
    }

    /// The recommended configuration with 200 max messages and 50 discard amount.
    public static let recommended = MaxMessageLimitOptions()
}
