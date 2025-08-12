//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

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
/// - Typing indicators
/// - etc..
public class LivestreamChannelController: DataStoreProvider, EventsControllerDelegate, AppStateObserverDelegate {
    public typealias Delegate = LivestreamChannelControllerDelegate

    // MARK: - Public Properties

    /// The ChannelQuery this controller observes.
    public private(set) var channelQuery: ChannelQuery

    /// The identifier of a channel this controller observes.
    public var cid: ChannelId? { channelQuery.cid }

    /// The `ChatClient` instance this controller belongs to.
    public let client: ChatClient

    /// The channel the controller represents.
    public private(set) var channel: ChatChannel? {
        didSet {
            guard let channel else { return }
            delegateCallback {
                $0.livestreamChannelController(self, didUpdateChannel: channel)
            }
        }
    }

    /// The messages of the channel the controller represents.
    public private(set) var messages: [ChatMessage] = [] {
        didSet {
            delegateCallback {
                $0.livestreamChannelController(self, didUpdateMessages: self.messages)
            }
        }
    }

    /// A Boolean value that indicates whether message processing is paused.
    ///
    /// When paused, new messages from other users will not be added to the messages array.
    /// This is useful when loading previous messages to prevent the array from being modified.
    public private(set) var isPaused: Bool = false {
        didSet {
            delegateCallback {
                $0.livestreamChannelController(self, didChangePauseState: self.isPaused)
            }
        }
    }

    private var isResuming: Bool = false

    /// The amount of messages that were skipped during the pause state.
    public private(set) var skippedMessagesAmount: Int = 0 {
        didSet {
            delegateCallback {
                $0.livestreamChannelController(self, didChangeSkippedMessagesAmount: self.skippedMessagesAmount)
            }
        }
    }

    /// A Boolean value that returns whether the oldest messages have all been loaded or not.
    public var hasLoadedAllPreviousMessages: Bool {
        paginationStateHandler.state.hasLoadedAllPreviousMessages
    }

    /// A Boolean value that returns whether the newest messages have all been loaded or not.
    public var hasLoadedAllNextMessages: Bool {
        paginationStateHandler.state.hasLoadedAllNextMessages || messages.isEmpty
    }

    /// A Boolean value that returns whether the channel is currently loading previous (old) messages.
    public var isLoadingPreviousMessages: Bool {
        paginationStateHandler.state.isLoadingPreviousMessages
    }

    /// A Boolean value that returns whether the channel is currently loading next (new) messages.
    public var isLoadingNextMessages: Bool {
        paginationStateHandler.state.isLoadingNextMessages
    }

    /// A Boolean value that returns whether the channel is currently loading a page around a message.
    public var isLoadingMiddleMessages: Bool {
        paginationStateHandler.state.isLoadingMiddleMessages
    }

    /// A Boolean value that returns whether the channel is currently in a mid-page.
    public var isJumpingToMessage: Bool {
        paginationStateHandler.state.isJumpingToMessage
    }

    /// A Boolean value that indicates whether to load initial messages from the cache.
    ///
    /// Only the initial page will be loaded from cache, to avoid an initial blank screen.
    public var loadInitialMessagesFromCache: Bool = true

    /// A boolean value indicating if the controller should count the number o skipped messages when in pause state.
    public var countSkippedMessagesWhenPaused: Bool = false

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
    public var maxMessageLimitOptions: MaxMessageLimitOptions?

    /// Set the delegate to observe the changes in the system.
    public var delegate: LivestreamChannelControllerDelegate? {
        get { multicastDelegate.mainDelegate }
        set { multicastDelegate.set(mainDelegate: newValue) }
    }

    /// A type-erased multicast delegate.
    internal var multicastDelegate: MulticastDelegate<LivestreamChannelControllerDelegate> = .init()

    // MARK: - Private Properties

    /// The API client for making direct API calls.
    private let apiClient: APIClient

    /// Pagination state handler for managing message pagination.
    private let paginationStateHandler: MessagesPaginationStateHandling

    /// Events controller for listening to real-time events.
    private let eventsController: EventsController

    /// The channel updater to reuse actions from channel controller which is safe to use without DB.
    private let updater: ChannelUpdater

    /// The app state observer for monitoring memory warnings and app state changes.
    private let appStateObserver: AppStateObserving

    /// The current user id.
    private var currentUserId: UserId? { client.currentUserId }

    /// An internal backing object for all publicly available Combine publishers.
    var basePublishers: BasePublishers {
        if let value = _basePublishers as? BasePublishers {
            return value
        }
        _basePublishers = BasePublishers(controller: self)
        return _basePublishers as? BasePublishers ?? .init(controller: self)
    }

    var _basePublishers: Any?

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
        self.channelQuery = channelQuery
        self.client = client
        apiClient = client.apiClient
        self.paginationStateHandler = paginationStateHandler
        eventsController = client.eventsController()
        appStateObserver = StreamAppStateObserver()
        self.updater = updater ?? ChannelUpdater(
            channelRepository: client.channelRepository,
            messageRepository: client.messageRepository,
            paginationStateHandler: client.makeMessagesPaginationStateHandler(),
            database: client.databaseContainer,
            apiClient: client.apiClient
        )
        eventsController.delegate = self
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

    // MARK: - Public Methods

    /// Synchronizes the controller with the backend data.
    /// - Parameter completion: Called when the synchronization is finished.
    public func synchronize(_ completion: (@MainActor(_ error: Error?) -> Void)? = nil) {
        // Populate the initial data with existing cache.
        if loadInitialMessagesFromCache, let cid = self.cid, let channel = dataStore.channel(cid: cid) {
            self.channel = channel
            messages = channel.latestMessages
        }

        updateChannelData(
            channelQuery: channelQuery,
            completion: completion
        )
    }

    /// Loads previous (older) messages from backend.
    /// - Parameters:
    ///   - messageId: ID of the last fetched message. You will get messages `older` than the provided ID.
    ///   - limit: Limit for page size. By default it is 25.
    ///   - completion: Called when the network request is finished.
    public func loadPreviousMessages(
        before messageId: MessageId? = nil,
        limit: Int? = nil,
        completion: (@MainActor(Error?) -> Void)? = nil
    ) {
        guard cid != nil else {
            callback {
                completion?(ClientError.ChannelNotCreatedYet())
            }
            return
        }

        let messageId = messageId
            ?? paginationStateHandler.state.oldestFetchedMessage?.id
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
        completion: (@MainActor(Error?) -> Void)? = nil
    ) {
        guard cid != nil else {
            callback {
                completion?(ClientError.ChannelNotCreatedYet())
            }
            return
        }

        let messageId = messageId
            ?? paginationStateHandler.state.newestFetchedMessage?.id
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
        completion: (@MainActor(Error?) -> Void)? = nil
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
    public func loadFirstPage(_ completion: (@MainActor(_ error: Error?) -> Void)? = nil) {
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
        completion: (@MainActor(Result<MessageId, Error>) -> Void)? = nil
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
        completion: (@MainActor(Error?) -> Void)? = nil
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
        completion: @escaping @MainActor(Result<[ChatMessageReaction], Error>) -> Void
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
        completion: (@MainActor(Error?) -> Void)? = nil
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
        completion: (@MainActor(Error?) -> Void)? = nil
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
        completion: (@MainActor(Error?) -> Void)? = nil
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
        completion: (@MainActor(Error?) -> Void)? = nil
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
    ///   - pinning: The pinning expiration information. It supports setting an infinite expiration, setting a date, or the amount of time a message is pinned.
    ///   - completion: Called when the network request is finished. If request fails, the completion will be called with an error.
    public func pin(
        messageId: MessageId,
        pinning: MessagePinning = .noExpiration,
        completion: (@MainActor(Error?) -> Void)? = nil
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

    /// Unpins a message.
    /// - Parameters:
    ///   - messageId: The message identifier to unpin.
    ///   - completion: Called when the network request is finished. If request fails, the completion will be called with an error.
    public func unpin(
        messageId: MessageId,
        completion: (@MainActor(Error?) -> Void)? = nil
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
        completion: @escaping @MainActor(Result<[ChatMessage], Error>) -> Void
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
        guard let cooldownDuration = channel?.cooldownDuration, cooldownDuration > 0,
              let currentUserLatestMessage = messages.first(where: { $0.author.id == currentUserId }),
              channel?.ownCapabilities.contains(.skipSlowMode) == false else {
            return 0
        }

        let currentTime = Date().timeIntervalSince(currentUserLatestMessage.createdAt)
        return max(0, cooldownDuration - Int(currentTime))
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
    public func enableSlowMode(cooldownDuration: Int, completion: (@MainActor(Error?) -> Void)? = nil) {
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

    /// Disables slow mode for the channel
    ///
    /// For more information, please check [documentation](https://getstream.io/chat/docs/javascript/slow_mode/?language=swift).
    ///
    /// - Parameters:
    ///   - completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    public func disableSlowMode(completion: (@MainActor(Error?) -> Void)? = nil) {
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

    /// Pauses the collecting of new messages.
    ///
    /// When paused, new messages from other users will not be added to the messages array.
    /// This is useful for the loading of previous message to not conflict with the max limit of the messages array.
    public func pause() {
        guard !isPaused else { return }
        isPaused = true
    }

    /// Resumes the collecting of new messages.
    ///
    /// This will load the first page, reseting the current messages  and returning to the latest messages.
    /// After resuming, new messages will be added to the messages array again.
    public func resume(completion: (@MainActor(Error?) -> Void)? = nil) {
        guard isPaused, !isResuming else {
            callback {
                completion?(nil)
            }
            return
        }

        if countSkippedMessagesWhenPaused {
            skippedMessagesAmount = 0
        }
        
        isResuming = true
        loadFirstPage { [weak self] error in
            self?.isPaused = false
            self?.isResuming = false
            completion?(error)
        }
    }

    // MARK: - EventsControllerDelegate

    public func eventsController(_ controller: EventsController, didReceiveEvent event: Event) {
        guard let channelEvent = event as? ChannelSpecificEvent, channelEvent.cid == cid else {
            return
        }

        handleChannelEvent(event)
    }

    // MARK: - AppStateObserverDelegate

    public func applicationDidReceiveMemoryWarning() {
        // Reset the channel to free up memory by loading the first page
        loadFirstPage()
    }

    public func applicationDidMoveToForeground() {
        if client.connectionStatus != .connected {
            loadFirstPage()
        }
    }

    // MARK: - Private Methods

    private func updateChannelData(
        channelQuery: ChannelQuery,
        completion: (@MainActor(Error?) -> Void)? = nil
    ) {
        if let pagination = channelQuery.pagination {
            paginationStateHandler.begin(pagination: pagination)
        }

        let endpoint: Endpoint<ChannelPayload> =
            .updateChannel(query: channelQuery)

        let requestCompletion: (Result<ChannelPayload, Error>) -> Void = { [weak self] result in
            self?.callback { [weak self] in
                guard let self = self else { return }

                switch result {
                case .success(let payload):
                    // If it is the first page, save channel to the DB to make sure manual event handling
                    // can fetch the channel from the DB.
                    if channelQuery.pagination == nil {
                        client.databaseContainer.write { session in
                            try session.saveChannel(payload: payload)
                        }
                    }
                    self.handleChannelPayload(payload, channelQuery: channelQuery)
                    completion?(nil)

                case .failure(let error):
                    if let pagination = channelQuery.pagination {
                        self.paginationStateHandler.end(pagination: pagination, with: .failure(error))
                    }
                    completion?(error)
                }
            }
        }

        apiClient.request(endpoint: endpoint, completion: requestCompletion)
    }

    private func handleChannelPayload(_ payload: ChannelPayload, channelQuery: ChannelQuery) {
        if let pagination = channelQuery.pagination {
            paginationStateHandler.end(pagination: pagination, with: .success(payload.messages))
        }

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

    /// Helper method to execute the callbacks on the main thread.
    private func callback(_ action: @MainActor @escaping () -> Void) {
        DispatchQueue.main.async {
            action()
        }
    }

    private func delegateCallback(_ callback: @escaping @MainActor(Delegate) -> Void) {
        self.callback {
            self.multicastDelegate.invoke(callback)
        }
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
            handleUpdatedMessage(messageDeletedEvent.message)

        case let newMessageErrorEvent as NewMessageErrorEvent:
            guard let message = messages.first(where: { $0.id == newMessageErrorEvent.messageId }) else {
                return
            }
            let errorMessage = message.changing(state: .sendingFailed)
            handleUpdatedMessage(errorMessage)

        case let reactionNewEvent as ReactionNewEvent:
            handleNewReaction(reactionNewEvent)

        case let reactionUpdatedEvent as ReactionUpdatedEvent:
            handleUpdatedReaction(reactionUpdatedEvent)

        case let reactionDeletedEvent as ReactionDeletedEvent:
            handleDeletedReaction(reactionDeletedEvent)

        case let channelUpdatedEvent as ChannelUpdatedEvent:
            handleChannelUpdated(channelUpdatedEvent)

        case is MemberAddedEvent,
             is MemberRemovedEvent,
             is MemberUpdatedEvent,
             is NotificationAddedToChannelEvent,
             is NotificationRemovedFromChannelEvent,
             is NotificationInvitedEvent,
             is NotificationInviteAcceptedEvent,
             is NotificationInviteRejectedEvent:
            updateChannelFromDataStore()

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

        default:
            break
        }
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
            messages[index] = updatedMessage
        }
    }

    private func handleDeletedMessage(_ deletedMessage: ChatMessage) {
        messages.removeAll { $0.id == deletedMessage.id }
    }

    private func handleNewReaction(_ reactionEvent: ReactionNewEvent) {
        updateMessage(reactionEvent.message)
    }

    private func handleUpdatedReaction(_ reactionEvent: ReactionUpdatedEvent) {
        updateMessage(reactionEvent.message)
    }

    private func handleDeletedReaction(_ reactionEvent: ReactionDeletedEvent) {
        updateMessage(reactionEvent.message)
    }

    private func updateMessage(
        _ updatedMessage: ChatMessage
    ) {
        if let messageIndex = messages.firstIndex(where: { $0.id == updatedMessage.id }) {
            messages[messageIndex] = updatedMessage
        }
    }

    private func handleChannelUpdated(_ event: ChannelUpdatedEvent) {
        channel = event.channel
    }

    // For events that do not have the channel data, and still
    // go through the middleware, lets fetch it from DB and update it.
    private func updateChannelFromDataStore() {
        guard let cid = cid, let updatedChannel = dataStore.channel(cid: cid) else {
            return
        }
        channel = updatedChannel
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
        completion: (@MainActor(Result<MessageId, Error>) -> Void)? = nil
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
}

/// Configuration options for message limiting in LivestreamChannelController.
public struct MaxMessageLimitOptions {
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
