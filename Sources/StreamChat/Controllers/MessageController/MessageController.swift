//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

public extension ChatClient {
    /// Creates a new `MessageController` for the message with the provided id.
    /// - Parameter cid: The channel identifier the message relates to.
    /// - Parameter messageId: The message identifier.
    /// - Returns: A new instance of `MessageController`.
    func messageController(cid: ChannelId, messageId: MessageId) -> ChatMessageController {
        .init(client: self, cid: cid, messageId: messageId)
    }
}

/// `ChatMessageController` is a controller class which allows observing and mutating a chat message entity.
///
public class ChatMessageController: DataController, DelegateCallable, DataStoreProvider {
    /// The `ChatClient` instance this controller belongs to.
    public let client: ChatClient

    /// The identified of the channel the message belongs to.
    public let cid: ChannelId

    /// The identified of the message this controllers represents.
    public let messageId: MessageId

    /// The amount of replies fetched per page.
    public var repliesPageSize: Int = .messagesPageSize

    /// The message object this controller represents.
    ///
    /// To observe changes of the message, set your class as a delegate of this controller or use the provided
    /// `Combine` publishers.
    ///
    public var message: ChatMessage? {
        startObserversIfNeeded()
        return messageObserver.item
    }

    /// The replies to the message the controller represents.
    ///
    /// To observe changes of the replies, set your class as a delegate of this controller or use the provided
    /// `Combine` publishers.
    ///
    public var replies: LazyCachedMapCollection<ChatMessage> {
        startObserversIfNeeded()
        return repliesObserver?.items ?? []
    }

    /// The total reactions of the message the controller represents.
    ///
    /// To observe changes of the reactions, set your class as a delegate of this controller or use the provided
    /// `Combine` publishers.
    ///
    public var reactions: [ChatMessageReaction] = [] {
        didSet {
            delegateCallback { [weak self] in
                guard let self = self else {
                    log.warning("Callback called while self is nil")
                    return
                }

                $0.messageController(self, didChangeReactions: self.reactions)
            }
        }
    }

    /// A Boolean value that returns whether the reactions have all been loaded or not.
    public internal(set) var hasLoadedAllReactions = false

    /// Describes the ordering the replies are presented.
    ///
    /// - Important: ⚠️ Changing this value doesn't trigger delegate methods. You should reload your UI manually after changing
    /// the `listOrdering` value to reflect the changes. Further updates to the replies will be delivered using the delegate
    /// methods, as usual.
    ///
    public var listOrdering: MessageOrdering = .topToBottom {
        didSet {
            if state != .initialized {
                setRepliesObserver()

                do {
                    try repliesObserver?.startObserving()
                } catch {
                    log.error("Failed to perform fetch request with error: \(error). This is an internal error.")
                    state = .localDataFetchFailed(ClientError(with: error))
                }

                log.warning(
                    "Changing `listOrdering` will update data inside controller, but you have to update your UI manually "
                        + "to see changes."
                )
            }
        }
    }

    /// A Boolean value that returns whether the oldest replies have all been loaded or not.
    public var hasLoadedAllPreviousReplies: Bool {
        messageUpdater.paginationState.hasLoadedAllPreviousMessages
    }

    /// A Boolean value that returns whether the newest replies have all been loaded or not.
    public var hasLoadedAllNextReplies: Bool {
        messageUpdater.paginationState.hasLoadedAllNextMessages || replies.isEmpty
    }

    /// A Boolean value that returns whether the thread is currently loading previous (old) replies.
    public var isLoadingPreviousReplies: Bool {
        messageUpdater.paginationState.isLoadingPreviousMessages
    }

    /// A Boolean value that returns whether the thread is currently loading next (new) replies.
    public var isLoadingNextReplies: Bool {
        messageUpdater.paginationState.isLoadingNextMessages
    }

    /// A Boolean value that returns whether the thread is currently loading a page around a reply.
    public var isLoadingMiddleReplies: Bool {
        messageUpdater.paginationState.isLoadingMiddleMessages
    }

    /// A Boolean value that returns whether the thread is currently in a mid-page.
    /// The value is false if the thread has the first page loaded.
    /// The value is true if the thread is in a mid fragment and didn't load the first page yet.
    public var isJumpingToMessage: Bool {
        messageUpdater.paginationState.isJumpingToMessage
    }

    /// The pagination cursor for loading previous (old) replies.
    internal var lastOldestReplyId: MessageId? {
        messageUpdater.paginationState.oldestFetchedMessage?.id
    }

    /// The pagination cursor for loading next (new) replies.
    internal var lastNewestReplyId: MessageId? {
        messageUpdater.paginationState.newestFetchedMessage?.id
    }

    private let environment: Environment

    var _basePublishers: Any?
    /// An internal backing object for all publicly available Combine publishers. We use it to simplify the way we expose
    /// publishers. Instead of creating custom `Publisher` types, we use `CurrentValueSubject` and `PassthroughSubject` internally,
    /// and expose the published values by mapping them to a read-only `AnyPublisher` type.
    @available(iOS 13, *)
    var basePublishers: BasePublishers {
        if let value = _basePublishers as? BasePublishers {
            return value
        }
        _basePublishers = BasePublishers(controller: self)
        return _basePublishers as? BasePublishers ?? .init(controller: self)
    }

    /// A type-erased multicast delegate.
    var multicastDelegate: MulticastDelegate<ChatMessageControllerDelegate> = .init() {
        didSet {
            stateMulticastDelegate.set(mainDelegate: multicastDelegate.mainDelegate)
            stateMulticastDelegate.set(additionalDelegates: multicastDelegate.additionalDelegates)

            startObserversIfNeeded()
        }
    }

    /// The observer used to listen to message updates
    private lazy var messageObserver = createMessageObserver()
        .onChange { [weak self] change in
            self?.delegateCallback { [weak self] in
                guard let self = self else {
                    log.warning("Callback called while self is nil")
                    return
                }

                $0.messageController(self, didChangeMessage: change)
            }
        }

    /// The observer used to listen replies updates.
    /// It will be reset on `listOrdering` changes.
    private var repliesObserver: ListDatabaseObserverWrapper<ChatMessage, MessageDTO>?

    /// The worker used to fetch the remote data and communicate with servers.
    private let messageUpdater: MessageUpdater

    /// Creates a new `MessageControllerGeneric`.
    /// - Parameters:
    ///   - client: The `Client` instance this controller belongs to.
    ///   - cid: The channel identifier the message belongs to.
    ///   - messageId: The message identifier.
    ///   - environment: The source of internal dependencies.
    init(client: ChatClient, cid: ChannelId, messageId: MessageId, environment: Environment = .init()) {
        self.client = client
        self.cid = cid
        self.messageId = messageId
        self.environment = environment
        messageUpdater = environment.messageUpdaterBuilder(
            client.config.isLocalStorageEnabled,
            client.messageRepository,
            client.makeMessagesPaginationStateHandler(),
            client.databaseContainer,
            client.apiClient
        )
        super.init()

        setRepliesObserver()
    }

    override public func synchronize(_ completion: ((Error?) -> Void)? = nil) {
        startObserversIfNeeded()

        messageUpdater.getMessage(cid: cid, messageId: messageId) { result in
            let error = result.error
            self.state = error == nil ? .remoteDataFetched : .remoteDataFetchFailed(ClientError(with: error))
            self.callback { completion?(error) }
        }
    }

    /// If the `state` of the controller is `initialized`, this method calls `startObserving` on
    /// `messageObserver`, `repliesObserver` and `reactionsObserver` to fetch the local data and start observing the changes.
    /// It also changes `state` based on the result.
    ///
    /// It's safe to call this method repeatedly.
    ///
    internal func startObserversIfNeeded() {
        guard state == .initialized else { return }
        do {
            try messageObserver.startObserving()
            try repliesObserver?.startObserving()
            reactions = Array(messageObserver.item?.latestReactions.sorted(by: { $0.updatedAt > $1.updatedAt }) ?? [])

            state = .localDataFetched
        } catch {
            log.error("Failed to perform fetch request with error: \(error). This is an internal error.")
            state = .localDataFetchFailed(ClientError(with: error))
        }
    }

    // MARK: - Actions

    /// Edits the message this controller manages with the provided values.
    ///
    /// - Parameters:
    ///   - text: The updated message text.
    ///   - attachments: An array of the attachments for the message.
    ///   - extraData: Custom extra data. When `nil` is passed the message custom fields stay the same. Equals `nil` by default.
    ///   - completion: The completion. Will be called on a **callbackQueue** when the network request is finished.
    ///                 If request fails, the completion will be called with an error.
    ///
    public func editMessage(
        text: String,
        attachments: [AnyAttachmentPayload] = [],
        extraData: [String: RawJSON]? = nil,
        completion: ((Error?) -> Void)? = nil
    ) {
        messageUpdater.editMessage(
            messageId: messageId,
            text: text,
            attachments: attachments,
            extraData: extraData
        ) { error in
            self.callback {
                completion?(error)
            }
        }
    }

    /// Deletes the message this controller manages.
    ///
    /// - Parameters:
    ///   - hard: A Boolean value to determine if the message will be delete permanently on the backend. By default it is `false`.
    ///     The recommend approach is to always do a soft delete (hard = false). You can control the UI Visibility of the deleted message in the client side.
    ///     If you hard delete the message, the message will be permanently loss since it will be erased from the backend's database.
    ///   - completion: The completion. Will be called on a **callbackQueue** when the network request is finished.
    ///                 If request fails, the completion will be called with an error.
    ///
    public func deleteMessage(hard: Bool = false, completion: ((Error?) -> Void)? = nil) {
        messageUpdater.deleteMessage(messageId: messageId, hard: hard) { error in
            self.callback {
                completion?(error)
            }
        }
    }

    /// Creates a new reply message locally and schedules it for send.
    ///
    /// - Parameters:
    ///   - messageId: The id for the sent message. By default, it is automatically generated by Stream..
    ///   - text: Text of the message.
    ///   - pinning: Pins the new message. `nil` if should not be pinned.
    ///   - attachments: An array of the attachments for the message.
    ///    `Note`: can be built-in types, custom attachment types conforming to `AttachmentEnvelope` protocol
    ///     and `ChatMessageAttachmentSeed`s.
    ///   - showReplyInChannel: Set this flag to `true` if you want the message to be also visible in the channel, not only
    ///   in the response thread.
    ///   - quotedMessageId: An id of the message new message quotes. (inline reply)
    ///   - skipPush: If true, skips sending push notification to channel members.
    ///   - skipEnrichUrl: If true, skips url enriching.
    ///   - extraData: Additional extra data of the message object.
    ///   - completion: Called when saving the message to the local DB finishes.
    ///
    public func createNewReply(
        messageId: MessageId? = nil,
        text: String,
        pinning: MessagePinning? = nil,
        attachments: [AnyAttachmentPayload] = [],
        mentionedUserIds: [UserId] = [],
        showReplyInChannel: Bool = false,
        isSilent: Bool = false,
        quotedMessageId: MessageId? = nil,
        skipPush: Bool = false,
        skipEnrichUrl: Bool = false,
        extraData: [String: RawJSON] = [:],
        completion: ((Result<MessageId, Error>) -> Void)? = nil
    ) {
        let parentMessageId = self.messageId

        messageUpdater.createNewReply(
            in: cid,
            messageId: messageId,
            text: text,
            pinning: pinning,
            command: nil,
            arguments: nil,
            parentMessageId: parentMessageId,
            attachments: attachments,
            mentionedUserIds: mentionedUserIds,
            showReplyInChannel: showReplyInChannel,
            isSilent: isSilent,
            quotedMessageId: quotedMessageId,
            skipPush: skipPush,
            skipEnrichUrl: skipEnrichUrl,
            extraData: extraData
        ) { result in
            if let newMessage = try? result.get() {
                self.client.eventNotificationCenter.process(NewMessagePendingEvent(message: newMessage))
            }
            self.callback {
                completion?(result.map(\.id))
            }
        }
    }

    /// Loads previous messages from the backend.
    ///
    /// - Parameters:
    ///   - messageId: ID of the last fetched message. You will get messages `older` than the provided ID.
    ///     In case no replies are fetched you will get the first `limit` number of replies.
    ///   - limit: Limit for page size. By default it is 25.
    ///   - completion: The completion. Will be called on a **callbackQueue** when the network request is finished.
    ///                 If request fails, the completion will be called with an error.
    ///
    public func loadPreviousReplies(
        before replyId: MessageId? = nil,
        limit: Int? = nil,
        completion: ((Error?) -> Void)? = nil
    ) {
        if hasLoadedAllPreviousReplies || isLoadingPreviousReplies {
            completion?(nil)
            return
        }

        let pageSize = limit ?? repliesPageSize
        let pagination: MessagesPagination

        if let replyId = replyId ?? lastOldestReplyId {
            pagination = MessagesPagination(
                pageSize: pageSize,
                parameter: .lessThan(replyId)
            )
        } else {
            pagination = MessagesPagination(pageSize: pageSize)
        }

        messageUpdater.loadReplies(
            cid: cid,
            messageId: messageId,
            pagination: pagination
        ) { result in
            switch result {
            case let .success(payload):
                self.callback {
                    // If the first page was loaded with 25 messages, it means we need to load
                    // a page with 0 messages. This won't trigger a didChangeReplies, but we need
                    // to fake it so that we can insert the parent message to the list again.
                    // When we have the oldestReplyId and newestReplyId from the backend, this won't be
                    // needed since when loading the first page, we can check if the first message is the
                    // oldestReplyId, if it is, it means we already loaded all messages, and we don't need
                    // to perform any more requests.
                    if payload.messages.isEmpty {
                        self.delegate?.messageController(self, didChangeReplies: [])
                    }

                    completion?(nil)
                }
            case let .failure(error):
                self.callback { completion?(error) }
            }
        }
    }

    /// Load replies around the given reply id. Useful to jump to a reply which hasn't been loaded yet.
    ///
    /// Clears the current replies of the parent message and loads the replies with the given id,
    /// and the replies around it depending on the limit provided.
    ///
    /// Ex: If the limit is 25, it will load the reply and 12 on top and 12 below it. (25 total)
    ///
    /// - Parameters:
    ///   - replyId: The reply id of the message to jump to.
    ///   - limit: The number of replies to load in total, including the message to jump to.
    ///   - completion: Callback when the API call is completed.
    public func loadPageAroundReplyId(
        _ replyId: MessageId,
        limit: Int? = nil,
        completion: ((Error?) -> Void)? = nil
    ) {
        if isLoadingMiddleReplies {
            completion?(nil)
            return
        }

        let pageSize = limit ?? repliesPageSize
        let pagination = MessagesPagination(pageSize: pageSize, parameter: .around(replyId))

        messageUpdater.loadReplies(
            cid: cid,
            messageId: messageId,
            pagination: pagination
        ) { result in
            switch result {
            case .success:
                self.callback { completion?(nil) }
            case let .failure(error):
                self.callback { completion?(error) }
            }
        }
    }

    /// Loads new messages from the backend.
    ///
    /// - Parameters:
    ///   - messageId: ID of the current first message. You will get messages `newer` then the provided ID.
    ///   - limit: Limit for page size.
    ///   - completion: The completion. Will be called on a **callbackQueue** when the network request is finished.
    ///                 If request fails, the completion will be called with an error.
    ///
    public func loadNextReplies(
        after replyId: MessageId? = nil,
        limit: Int? = nil,
        completion: ((Error?) -> Void)? = nil
    ) {
        if isLoadingNextReplies || hasLoadedAllNextReplies {
            completion?(nil)
            return
        }

        guard let replyId = replyId ?? lastNewestReplyId else {
            log.error(ClientError.MessageEmptyReplies().localizedDescription)
            callback { completion?(ClientError.MessageEmptyReplies()) }
            return
        }

        let pageSize = limit ?? repliesPageSize

        messageUpdater.loadReplies(
            cid: cid,
            messageId: messageId,
            pagination: MessagesPagination(pageSize: pageSize, parameter: .greaterThan(replyId))
        ) { result in
            switch result {
            case .success:
                self.callback { completion?(nil) }
            case let .failure(error):
                self.callback { completion?(error) }
            }
        }
    }

    /// Cleans the current state and loads the first page again.
    /// - Parameter limit: Limit for page size
    /// - Parameter completion: Callback when the API call is completed.
    public func loadFirstPage(limit: Int? = nil, _ completion: ((_ error: Error?) -> Void)? = nil) {
        let pageSize = limit ?? repliesPageSize
        messageUpdater.loadReplies(
            cid: cid,
            messageId: messageId,
            pagination: MessagesPagination(pageSize: pageSize)
        ) { result in
            self.callback { completion?(result.error) }
        }
    }

    /// Loads the next page of reactions starting from the current fetched reactions.
    ///
    /// - Parameters:
    ///   - limit: The reactions page size.
    ///   - completion: The completion is called when the network request is finished.
    ///   If the request fails, the completion will be called with an error, if it succeeds it is
    ///   called without an error and the delegate is notified of reactions changes.
    public func loadNextReactions(
        limit: Int = 25,
        completion: ((Error?) -> Void)? = nil
    ) {
        if hasLoadedAllReactions {
            callback { completion?(nil) }
            return
        }

        // Note: For now we don't reuse the `loadReactions()` function to avoid deadlock on the callbackQueue.
        messageUpdater.loadReactions(
            cid: cid,
            messageId: messageId,
            pagination: Pagination(pageSize: limit, offset: reactions.count)
        ) { result in
            switch result {
            case let .success(reactions):
                let currentReactions = Set(self.reactions)
                let newReactionsWithoutDuplicates = reactions.filter {
                    !currentReactions.contains($0)
                }

                self.reactions += newReactionsWithoutDuplicates

                if reactions.count < limit {
                    self.hasLoadedAllReactions = true
                }

                self.callback {
                    completion?(nil)
                }

            case let .failure(error):
                self.callback {
                    completion?(error)
                }
            }
        }
    }

    /// Loads reactions from the backend given an offset and a limit.
    ///
    /// - Parameters:
    ///   - limit: The reactions page size.
    ///   - offset: The starting position from the desired range to be fetched.
    ///   - completion: The completion is called when the network request is finished.
    ///   It is called with the reactions if the request succeeds or error if the request fails.
    public func loadReactions(
        limit: Int,
        offset: Int = 0,
        completion: @escaping (Result<[ChatMessageReaction], Error>) -> Void
    ) {
        messageUpdater.loadReactions(
            cid: cid,
            messageId: messageId,
            pagination: Pagination(pageSize: limit, offset: offset)
        ) { result in
            switch result {
            case let .success(reactions):
                self.callback { completion(.success(reactions)) }
            case let .failure(error):
                self.callback { completion(.failure(error)) }
            }
        }
    }

    /// Flags the message this controller manages.
    ///
    /// - Parameter completion: The completion. Will be called on a **callbackQueue** when the network request is finished.
    ///
    public func flag(completion: ((Error?) -> Void)? = nil) {
        messageUpdater.flagMessage(true, with: messageId, in: cid) { error in
            self.callback {
                completion?(error)
            }
        }
    }

    /// Unflags the message this controller manages.
    ///
    /// - Parameter completion: The completion. Will be called on a **callbackQueue** when the network request is finished.
    ///
    public func unflag(completion: ((Error?) -> Void)? = nil) {
        messageUpdater.flagMessage(false, with: messageId, in: cid) { error in
            self.callback {
                completion?(error)
            }
        }
    }

    /// Adds new reaction to the message this controller manages.
    /// - Parameters:
    ///   - type: The reaction type.
    ///   - score: The reaction score.
    ///   - enforceUnique: If set to `true`, new reaction will replace all reactions the user has (if any) on this message.
    ///   - extraData: The reaction extra data.
    ///   - completion: The completion. Will be called on a **callbackQueue** when the network request is finished.
    public func addReaction(
        _ type: MessageReactionType,
        score: Int = 1,
        enforceUnique: Bool = false,
        extraData: [String: RawJSON] = [:],
        completion: ((Error?) -> Void)? = nil
    ) {
        messageUpdater.addReaction(
            type,
            score: score,
            enforceUnique: enforceUnique,
            extraData: extraData,
            messageId: messageId
        ) { error in
            self.callback {
                completion?(error)
            }
        }
    }

    /// Deletes the reaction from the message this controller manages.
    /// - Parameters:
    ///   - type: The reaction type.
    ///   - completion: The completion. Will be called on a **callbackQueue** when the network request is finished.
    public func deleteReaction(
        _ type: MessageReactionType,
        completion: ((Error?) -> Void)? = nil
    ) {
        messageUpdater.deleteReaction(type, messageId: messageId) { error in
            self.callback {
                completion?(error)
            }
        }
    }

    /// Pin the message this controller manages.
    ///  - Parameters:
    ///   - pinning: The pinning expiration information. It supports setting an infinite expiration, setting a date, or the amount of time a message is pinned.
    ///   - completion: A completion block with an error if the request was failed.
    public func pin(_ pinning: MessagePinning, completion: ((Error?) -> Void)? = nil) {
        messageUpdater.pinMessage(messageId: messageId, pinning: pinning) { result in
            self.callback {
                completion?(result)
            }
        }
    }

    /// Unpins the message this controller manages.
    ///  - Parameters:
    ///   - completion: A completion block with an error if the request was failed.
    public func unpin(completion: ((Error?) -> Void)? = nil) {
        messageUpdater.unpinMessage(messageId: messageId) { result in
            self.callback {
                completion?(result)
            }
        }
    }

    /// Updates local state of attachment with provided `id` to be enqueued by attachment uploader.
    /// - Parameters:
    ///   - id: The attachment identifier.
    ///   - completion: The completion. Will be called on a **callbackQueue** when the database operation is finished.
    ///                 If operation fails, the completion will be called with an error.
    public func restartFailedAttachmentUploading(
        with id: AttachmentId,
        completion: ((Error?) -> Void)? = nil
    ) {
        messageUpdater.restartFailedAttachmentUploading(with: id) { error in
            self.callback {
                completion?(error)
            }
        }
    }

    /// Changes local message from `.sendingFailed` to `.pendingSend` so it is enqueued by message sender worker.
    /// - Parameter completion: The completion. Will be called on a **callbackQueue** when the database operation is finished.
    ///                         If operation fails, the completion will be called with an error.
    public func resendMessage(completion: ((Error?) -> Void)? = nil) {
        messageUpdater.resendMessage(with: messageId) { error in
            self.callback {
                completion?(error)
            }
        }
    }

    /// Executes the provided action on the message this controller manages.
    /// - Parameters:
    ///   - action: The action to take.
    ///   - completion: The completion. Will be called on a **callbackQueue** when the operation is finished.
    ///                 If operation fails, the completion is called with the error.
    public func dispatchEphemeralMessageAction(_ action: AttachmentAction, completion: ((Error?) -> Void)? = nil) {
        messageUpdater.dispatchEphemeralMessageAction(cid: cid, messageId: messageId, action: action) { error in
            self.callback {
                completion?(error)
            }
        }
    }

    /// Translates the message to the given language.
    /// The translated message will be returned via `didChangeMessage` delegate callback.
    /// Translation will be in `message.translations[language]`
    /// - Parameters:
    ///   - language: The language message text should be translated to.
    ///   - completion: The completion. Will be called on a **callbackQueue** when the operation is finished.
    ///                 If operation fails, the completion is called with the error.
    public func translate(to language: TranslationLanguage, completion: ((Error?) -> Void)? = nil) {
        messageUpdater.translate(messageId: messageId, to: language) { error in
            self.callback {
                completion?(error)
            }
        }
    }
}

// MARK: - Environment

extension ChatMessageController {
    struct Environment {
        var messageObserverBuilder: (
            _ context: NSManagedObjectContext,
            _ fetchRequest: NSFetchRequest<MessageDTO>,
            _ itemCreator: @escaping (MessageDTO) throws -> ChatMessage,
            _ fetchedResultsControllerType: NSFetchedResultsController<MessageDTO>.Type
        ) -> EntityDatabaseObserver<ChatMessage, MessageDTO> = EntityDatabaseObserver.init

        var repliesObserverBuilder: (
            _ isBackgroundMappingEnabled: Bool,
            _ database: DatabaseContainer,
            _ fetchRequest: NSFetchRequest<MessageDTO>,
            _ itemCreator: @escaping (MessageDTO) throws -> ChatMessage,
            _ fetchedResultsControllerType: NSFetchedResultsController<MessageDTO>.Type
        ) -> ListDatabaseObserverWrapper<ChatMessage, MessageDTO> = {
            .init(isBackground: $0, database: $1, fetchRequest: $2, itemCreator: $3, fetchedResultsControllerType: $4)
        }

        var messageUpdaterBuilder: (
            _ isLocalStorageEnabled: Bool,
            _ messageRepository: MessageRepository,
            _ paginationStateHandler: MessagesPaginationStateHandling,
            _ database: DatabaseContainer,
            _ apiClient: APIClient
        ) -> MessageUpdater = MessageUpdater.init
    }
}

// MARK: - Private

private extension ChatMessageController {
    func createMessageObserver() -> EntityDatabaseObserver<ChatMessage, MessageDTO> {
        let observer = environment.messageObserverBuilder(
            client.databaseContainer.viewContext,
            MessageDTO.message(withID: messageId),
            { try $0.asModel() },
            NSFetchedResultsController<MessageDTO>.self
        )

        return observer
    }

    func setRepliesObserver() {
        let sortAscending = listOrdering == .topToBottom ? false : true
        let deletedMessageVisibility = client.databaseContainer.viewContext
            .deletedMessagesVisibility ?? .visibleForCurrentUser
        let shouldShowShadowedMessages = client.databaseContainer.viewContext.shouldShowShadowedMessages ?? false

        let pageSize: Int = repliesPageSize
        let observer = environment.repliesObserverBuilder(
            StreamRuntimeCheck._isBackgroundMappingEnabled,
            client.databaseContainer,
            MessageDTO.repliesFetchRequest(
                for: messageId,
                pageSize: pageSize,
                sortAscending: sortAscending,
                deletedMessagesVisibility: deletedMessageVisibility,
                shouldShowShadowedMessages: shouldShowShadowedMessages
            ),
            { try $0.asModel() as ChatMessage },
            NSFetchedResultsController<MessageDTO>.self
        )
        observer.onDidChange = { [weak self] changes in
            self?.delegateCallback { [weak self] in
                guard let self = self else {
                    log.warning("Callback called while self is nil")
                    return
                }
                log.debug("didChangeReplies: \(changes.map(\.debugDescription))")
                $0.messageController(self, didChangeReplies: changes)
            }
        }

        repliesObserver = observer
    }
}

// MARK: - Delegate

/// `ChatMessageController` uses this protocol to communicate changes to its delegate.
public protocol ChatMessageControllerDelegate: DataControllerStateDelegate {
    /// The controller observed a change in the `ChatMessage` its observes.
    func messageController(_ controller: ChatMessageController, didChangeMessage change: EntityChange<ChatMessage>)

    /// The controller observed changes in the replies of the observed `ChatMessage`.
    func messageController(_ controller: ChatMessageController, didChangeReplies changes: [ListChange<ChatMessage>])

    /// The controller observed changes in the reactions of the observed `ChatMessage`.
    func messageController(_ controller: ChatMessageController, didChangeReactions reactions: [ChatMessageReaction])
}

public extension ChatMessageControllerDelegate {
    func messageController(_ controller: ChatMessageController, didChangeMessage change: EntityChange<ChatMessage>) {}

    func messageController(_ controller: ChatMessageController, didChangeReplies changes: [ListChange<ChatMessage>]) {}

    func messageController(_ controller: ChatMessageController, didChangeReactions reactions: [ChatMessageReaction]) {}
}

/// `ChatMessageControllerDelegate` uses this protocol to communicate changes to its delegate.
public protocol _ChatMessageControllerDelegate: DataControllerStateDelegate {
    /// The controller observed a change in the `ChatMessage` its observes.
    func messageController(
        _ controller: ChatMessageController,
        didChangeMessage change: EntityChange<ChatMessage>
    )

    /// The controller observed changes in the replies of the observed `ChatMessage`.
    func messageController(
        _ controller: ChatMessageController,
        didChangeReplies changes: [ListChange<ChatMessage>]
    )
}

public extension ChatMessageController {
    /// Set the delegate of `ChatMessageController` to observe the changes in the system.
    var delegate: ChatMessageControllerDelegate? {
        get { multicastDelegate.mainDelegate }
        set { multicastDelegate.set(mainDelegate: newValue) }
    }
}

extension ClientError {
    class MessageEmptyReplies: ClientError {
        override public var localizedDescription: String {
            "You can't load previous replies when there is no replies for the message."
        }
    }
}
