//
// Copyright © 2021 Stream.io Inc. All rights reserved.
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
    
    /// Describes the ordering the replies are presented.
    ///
    /// - Important: ⚠️ Changing this value doesn't trigger delegate methods. You should reload your UI manually after changing
    /// the `listOrdering` value to reflect the changes. Further updates to the replies will be delivered using the delegate
    /// methods, as usual.
    ///
    public var listOrdering: ListOrdering = .topToBottom {
        didSet {
            if state != .initialized {
                _repliesObserver.reset()
                
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
    
    private let environment: Environment
    
    /// An internal backing object for all publicly available Combine publishers. We use it to simplify the way we expose
    /// publishers. Instead of creating custom `Publisher` types, we use `CurrentValueSubject` and `PassthroughSubject` internally,
    /// and expose the published values by mapping them to a read-only `AnyPublisher` type.
    @available(iOS 13, *)
    lazy var basePublishers: BasePublishers = .init(controller: self)
    
    /// A type-erased multicast delegate.
    var multicastDelegate: MulticastDelegate<AnyChatMessageControllerDelegate> = .init() {
        didSet {
            stateMulticastDelegate.mainDelegate = multicastDelegate.mainDelegate
            stateMulticastDelegate.additionalDelegates = multicastDelegate.additionalDelegates
            startObserversIfNeeded()
        }
    }
    
    /// The observer used to listen to message updates
    private lazy var messageObserver = createMessageObserver()
        .onChange { [unowned self] change in
            self.delegateCallback {
                $0.messageController(self, didChangeMessage: change)
            }
        }
    
    /// The observer used to listen replies updates.
    /// It will be reset on `listOrdering` changes.
    @Cached private var repliesObserver: ListDatabaseObserver<ChatMessage, MessageDTO>?
    
    /// The worker used to fetch the remote data and communicate with servers.
    private lazy var messageUpdater: MessageUpdater = environment.messageUpdaterBuilder(
        client.databaseContainer,
        client.apiClient
    )

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
        super.init()
        
        setRepliesObserver()
    }

    override public func synchronize(_ completion: ((Error?) -> Void)? = nil) {
        startObserversIfNeeded()
        
        messageUpdater.getMessage(cid: cid, messageId: messageId) { error in
            self.state = error == nil ? .remoteDataFetched : .remoteDataFetchFailed(ClientError(with: error))
            self.callback { completion?(error) }
        }
    }
    
    /// If the `state` of the controller is `initialized`, this method calls `startObserving` on
    /// `messageObserver` and `repliesObserver` to fetch the local data and start observing the changes.
    /// It also changes `state` based on the result.
    ///
    /// It's safe to call this method repeatedly.
    ///
    private func startObserversIfNeeded() {
        guard state == .initialized else { return }
        do {
            try messageObserver.startObserving()
            try repliesObserver?.startObserving()
            
            state = .localDataFetched
        } catch {
            log.error("Failed to perform fetch request with error: \(error). This is an internal error.")
            state = .localDataFetchFailed(ClientError(with: error))
        }
    }
}

// MARK: - Actions

public extension ChatMessageController {
    /// Edits the message this controller manages with the provided values.
    ///
    /// - Parameters:
    ///   - text: The updated message text.
    ///   - completion: The completion. Will be called on a **callbackQueue** when the network request is finished.
    ///                 If request fails, the completion will be called with an error.
    ///
    func editMessage(text: String, completion: ((Error?) -> Void)? = nil) {
        messageUpdater.editMessage(messageId: messageId, text: text) { error in
            self.callback {
                completion?(error)
            }
        }
    }
    
    /// Deletes the message this controller manages.
    ///
    /// - Parameters:
    ///   - completion: The completion. Will be called on a **callbackQueue** when the network request is finished.
    ///                 If request fails, the completion will be called with an error.
    ///
    func deleteMessage(completion: ((Error?) -> Void)? = nil) {
        messageUpdater.deleteMessage(messageId: messageId) { error in
            self.callback {
                completion?(error)
            }
        }
    }
    
    /// Creates a new reply message locally and schedules it for send.
    ///
    /// - Parameters:
    ///   - text: Text of the message.
    ///   - pinning: Pins the new message. `nil` if should not be pinned.
    ///   - attachments: An array of the attachments for the message.
    ///    `Note`: can be built-in types, custom attachment types conforming to `AttachmentEnvelope` protocol
    ///     and `ChatMessageAttachmentSeed`s.
    ///   - showReplyInChannel: Set this flag to `true` if you want the message to be also visible in the channel, not only
    ///   in the response thread.
    ///   - quotedMessageId: An id of the message new message quotes. (inline reply)
    ///   - extraData: Additional extra data of the message object.
    ///   - completion: Called when saving the message to the local DB finishes.
    ///
    func createNewReply(
        text: String,
        pinning: MessagePinning? = nil,
        attachments: [AnyAttachmentPayload] = [],
        mentionedUserIds: [UserId] = [],
        showReplyInChannel: Bool = false,
        isSilent: Bool = false,
        quotedMessageId: MessageId? = nil,
        extraData: [String: RawJSON] = [:],
        completion: ((Result<MessageId, Error>) -> Void)? = nil
    ) {
        messageUpdater.createNewReply(
            in: cid,
            text: text,
            pinning: pinning,
            command: nil,
            arguments: nil,
            parentMessageId: messageId,
            attachments: attachments,
            mentionedUserIds: mentionedUserIds,
            showReplyInChannel: showReplyInChannel,
            isSilent: isSilent,
            quotedMessageId: quotedMessageId,
            extraData: extraData
        ) { result in
            self.callback {
                completion?(result)
            }
        }
    }
    
    /// Loads previous messages from backend.
    ///
    /// - Parameters:
    ///   - messageId: ID of the last fetched message. You will get messages `older` than the provided ID.
    ///     In case no replies are fetched you will get the first `limit` number of replies.
    ///   - limit: Limit for page size.
    ///   - completion: The completion. Will be called on a **callbackQueue** when the network request is finished.
    ///                 If request fails, the completion will be called with an error.
    ///
    func loadPreviousReplies(
        before messageId: MessageId? = nil,
        limit: Int = 25,
        completion: ((Error?) -> Void)? = nil
    ) {
        let lastMessageId = messageId ?? replies.last?.id
    
        messageUpdater.loadReplies(
            cid: cid,
            messageId: self.messageId,
            pagination: MessagesPagination(pageSize: limit, parameter: lastMessageId.map { PaginationParameter.lessThan($0) })
        ) { error in
            self.callback { completion?(error) }
        }
    }
    
    /// Loads new messages from backend.
    ///
    /// - Parameters:
    ///   - messageId: ID of the current first message. You will get messages `newer` then the provided ID.
    ///   - limit: Limit for page size.
    ///   - completion: The completion. Will be called on a **callbackQueue** when the network request is finished.
    ///                 If request fails, the completion will be called with an error.
    ///
    func loadNextReplies(
        after messageId: MessageId? = nil,
        limit: Int = 25,
        completion: ((Error?) -> Void)? = nil
    ) {
        guard let messageId = messageId ?? replies.first?.id else {
            log.error(ClientError.MessageEmptyReplies().localizedDescription)
            callback { completion?(ClientError.MessageEmptyReplies()) }
            return
        }
    
        messageUpdater.loadReplies(
            cid: cid,
            messageId: self.messageId,
            pagination: MessagesPagination(pageSize: limit, parameter: .greaterThan(messageId))
        ) { error in
            self.callback { completion?(error) }
        }
    }
    
    /// Flags the message this controller manages.
    ///
    /// - Parameter completion: The completion. Will be called on a **callbackQueue** when the network request is finished.
    ///
    func flag(completion: ((Error?) -> Void)? = nil) {
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
    func unflag(completion: ((Error?) -> Void)? = nil) {
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
    func addReaction(
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
    func deleteReaction(
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
    func pin(_ pinning: MessagePinning, completion: ((Error?) -> Void)? = nil) {
        messageUpdater.pinMessage(messageId: messageId, pinning: pinning) { result in
            self.callback {
                completion?(result)
            }
        }
    }

    /// Unpins the message this controller manages.
    ///  - Parameters:
    ///   - completion: A completion block with an error if the request was failed.
    func unpin(completion: ((Error?) -> Void)? = nil) {
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
    func restartFailedAttachmentUploading(
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
    func resendMessage(completion: ((Error?) -> Void)? = nil) {
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
    func dispatchEphemeralMessageAction(_ action: AttachmentAction, completion: ((Error?) -> Void)? = nil) {
        messageUpdater.dispatchEphemeralMessageAction(cid: cid, messageId: messageId, action: action) { error in
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
            _ itemCreator: @escaping (MessageDTO) -> ChatMessage,
            _ fetchedResultsControllerType: NSFetchedResultsController<MessageDTO>.Type
        ) -> EntityDatabaseObserver<ChatMessage, MessageDTO> = EntityDatabaseObserver.init
        
        var messageUpdaterBuilder: (
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
            { $0.asModel() },
            NSFetchedResultsController<MessageDTO>.self
        )
        
        return observer
    }
    
    func setRepliesObserver() {
        _repliesObserver.computeValue = { [unowned self] in
            let sortAscending = self.listOrdering == .topToBottom ? false : true
            let deletedMessageVisibility = self.client.databaseContainer.viewContext
                .deletedMessagesVisibility ?? .visibleForCurrentUser

            let observer = ListDatabaseObserver(
                context: self.client.databaseContainer.viewContext,
                fetchRequest: MessageDTO.repliesFetchRequest(
                    for: self.messageId,
                    sortAscending: sortAscending,
                    deletedMessagesVisibility: deletedMessageVisibility
                ),
                itemCreator: { $0.asModel() as ChatMessage }
            )
            observer.onChange = { changes in
                self.delegateCallback {
                    $0.messageController(self, didChangeReplies: changes)
                }
            }

            return observer
        }
    }
}

// MARK: - Delegate

/// `ChatMessageController` uses this protocol to communicate changes to its delegate.
///
/// This protocol can be used only when no custom extra data are specified.
/// If you're using custom extra data types, please use `_ChatMessageControllerDelegate` instead.
///
public protocol ChatMessageControllerDelegate: DataControllerStateDelegate {
    /// The controller observed a change in the `ChatMessage` its observes.
    func messageController(_ controller: ChatMessageController, didChangeMessage change: EntityChange<ChatMessage>)
    
    /// The controller observed changes in the replies of the observed `ChatMessage`.
    func messageController(_ controller: ChatMessageController, didChangeReplies changes: [ListChange<ChatMessage>])
}

public extension ChatMessageControllerDelegate {
    func messageController(_ controller: ChatMessageController, didChangeMessage change: EntityChange<ChatMessage>) {}
    
    func messageController(_ controller: ChatMessageController, didChangeReplies changes: [ListChange<ChatMessage>]) {}
}

/// `_ChatMessageControllerDelegate` uses this protocol to communicate changes to its delegate.
///
/// If you're **not** using custom extra data types, you can use a convenience version of this protocol
/// named `ChatMessageControllerDelegate`, which hides the generic types, and make the usage easier.
///
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

final class AnyChatMessageControllerDelegate: ChatMessageControllerDelegate {
    weak var wrappedDelegate: AnyObject?
    private var _controllerDidChangeState: (DataController, DataController.State) -> Void
    private var _messageControllerDidChangeMessage: (ChatMessageController, EntityChange<ChatMessage>)
        -> Void
    private var _messageControllerDidChangeReplies: (ChatMessageController, [ListChange<ChatMessage>])
        -> Void
    
    init(
        wrappedDelegate: AnyObject?,
        controllerDidChangeState: @escaping (DataController, DataController.State) -> Void,
        messageControllerDidChangeMessage: @escaping (ChatMessageController, EntityChange<ChatMessage>)
            -> Void,
        messageControllerDidChangeReplies: @escaping (ChatMessageController, [ListChange<ChatMessage>])
            -> Void
    ) {
        self.wrappedDelegate = wrappedDelegate
        _controllerDidChangeState = controllerDidChangeState
        _messageControllerDidChangeMessage = messageControllerDidChangeMessage
        _messageControllerDidChangeReplies = messageControllerDidChangeReplies
    }

    func controller(_ controller: DataController, didChangeState state: DataController.State) {
        _controllerDidChangeState(controller, state)
    }

    func messageController(
        _ controller: ChatMessageController,
        didChangeMessage change: EntityChange<ChatMessage>
    ) {
        _messageControllerDidChangeMessage(controller, change)
    }
    
    func messageController(
        _ controller: ChatMessageController,
        didChangeReplies changes: [ListChange<ChatMessage>]
    ) {
        _messageControllerDidChangeReplies(controller, changes)
    }
}

extension AnyChatMessageControllerDelegate {
    convenience init(_ delegate: ChatMessageControllerDelegate?) {
        self.init(
            wrappedDelegate: delegate,
            controllerDidChangeState: { [weak delegate] in delegate?.controller($0, didChangeState: $1) },
            messageControllerDidChangeMessage: { [weak delegate] in delegate?.messageController($0, didChangeMessage: $1) },
            messageControllerDidChangeReplies: { [weak delegate] in delegate?.messageController($0, didChangeReplies: $1) }
        )
    }
}
 
public extension ChatMessageController {
    /// Set the delegate of `ChatMessageController` to observe the changes in the system.
    ///
    /// - Note: The delegate can be set directly only if you're **not** using custom extra data types. Due to the current
    /// limits of Swift and the way it handles protocols with associated types, it's required to use `setDelegate` method
    /// instead to set the delegate, if you're using custom extra data types.
    var delegate: ChatMessageControllerDelegate? {
        get { multicastDelegate.mainDelegate?.wrappedDelegate as? ChatMessageControllerDelegate }
        set { multicastDelegate.mainDelegate = AnyChatMessageControllerDelegate(newValue) }
    }
}

extension ClientError {
    class MessageEmptyReplies: ClientError {
        override public var localizedDescription: String {
            "You can't load previous replies when there is no replies for the message."
        }
    }
}
