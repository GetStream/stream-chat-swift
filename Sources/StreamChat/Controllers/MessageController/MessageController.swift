//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

public extension _ChatClient {
    /// Creates a new `MessageController` for the message with the provided id.
    /// - Parameter cid: The channel identifier the message relates to.
    /// - Parameter messageId: The message identifier.
    /// - Returns: A new instance of `MessageController`.
    func messageController(cid: ChannelId, messageId: MessageId) -> _ChatMessageController<ExtraData> {
        .init(client: self, cid: cid, messageId: messageId)
    }
}

/// `ChatMessageController` is a controller class which allows observing and mutating a chat message entity.
///
/// Learn more about `ChatMessageController` and its usage in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/StreamChat-SDK-Cheat-Sheet#messages).
///
/// - Note: `ChatMessageController` is a typealias of `_ChatMessageController` with default extra data. If you're using
/// custom extra data, create your own typealias of `_ChatMessageController`.
///
/// Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheet#working-with-extra-data).
///
public typealias ChatMessageController = _ChatMessageController<NoExtraData>

/// `ChatMessageController` is a controller class which allows observing and mutating a chat message entity.
///
/// Learn more about `ChatMessageController` and its usage in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/StreamChat-SDK-Cheat-Sheet#messages).
///
/// - Note: `_ChatMessageController` type is not meant to be used directly. If you're using default extra data, use
/// `ChatMessageController` typealias instead. If you're using custom extra data, create your own typealias
/// of `_ChatMessageController`.
///
/// Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheet#working-with-extra-data).
///
public class _ChatMessageController<ExtraData: ExtraDataTypes>: DataController, DelegateCallable {
    /// The `ChatClient` instance this controller belongs to.
    public let client: _ChatClient<ExtraData>
    
    /// The identified of the channel the message belongs to.
    public let cid: ChannelId
    
    /// The identified of the message this controllers represents.
    public let messageId: MessageId
    
    /// The message object this controller represents.
    ///
    /// To observe changes of the message, set your class as a delegate of this controller or use the provided
    /// `Combine` publishers.
    ///
    public var message: _ChatMessage<ExtraData>? { messageObserver.item }
    
    /// The replies to the message the controller represents.
    ///
    /// To observe changes of the replies, set your class as a delegate of this controller or use the provided
    /// `Combine` publishers.
    ///
    public var replies: LazyCachedMapCollection<_ChatMessage<ExtraData>> {
        if state == .initialized {
            startRepliesObserver { [weak self] error in
                self?.state = error == nil ? .localDataFetched : .localDataFetchFailed(ClientError(with: error))
            }
        }
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
                // Reset replies observer to apply new ordering
                startRepliesObserver { [weak self] error in
                    self?.state = error == nil ? .localDataFetched : .localDataFetchFailed(ClientError(with: error))
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
    var multicastDelegate: MulticastDelegate<AnyChatMessageControllerDelegate<ExtraData>> = .init() {
        didSet {
            stateMulticastDelegate.mainDelegate = multicastDelegate.mainDelegate
            stateMulticastDelegate.additionalDelegates = multicastDelegate.additionalDelegates
            startMessageObserver()
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
    @Cached private var repliesObserver: ListDatabaseObserver<_ChatMessage<ExtraData>, MessageDTO>?
    
    /// The worker used to fetch the remote data and communicate with servers.
    private lazy var messageUpdater: MessageUpdater<ExtraData> = environment.messageUpdaterBuilder(
        client.databaseContainer,
        client.apiClient
    )

    /// Creates a new `MessageControllerGeneric`.
    /// - Parameters:
    ///   - client: The `Client` instance this controller belongs to.
    ///   - cid: The channel identifier the message belongs to.
    ///   - messageId: The message identifier.
    ///   - environment: The source of internal dependencies.
    init(client: _ChatClient<ExtraData>, cid: ChannelId, messageId: MessageId, environment: Environment = .init()) {
        self.client = client
        self.cid = cid
        self.messageId = messageId
        self.environment = environment
        super.init()
        
        setRepliesObserver()
    }

    override public func synchronize(_ completion: ((Error?) -> Void)? = nil) {
        startMessageObserver()
        startRepliesObserver()
        
        messageUpdater.getMessage(cid: cid, messageId: messageId) { error in
            self.state = error == nil ? .remoteDataFetched : .remoteDataFetchFailed(ClientError(with: error))
            self.callback { completion?(error) }
        }
    }
    
    /// Initializing of `messageObserver` will start local data observing.
    /// In most cases it will be done by accusing `messages` but it's possible that only
    /// changes will be observed.
    private func startMessageObserver() {
        _ = messageObserver
    }
}

// MARK: - Actions

public extension _ChatMessageController {
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
    ///   - attachments: An array of the attachments for the message.
    ///   - showReplyInChannel: Set this flag to `true` if you want the message to be also visible in the channel, not only
    ///   in the response thread.
    ///   - quotedMessageId: An id of the message new message quotes. (inline reply)
    ///   - extraData: Additional extra data of the message object.
    ///   - completion: Called when saving the message to the local DB finishes.
    ///
    func createNewReply(
        text: String,
//        command: String? = nil,
//        arguments: String? = nil,
        attachments: [ChatMessageAttachmentSeed] = [],
        showReplyInChannel: Bool = false,
        quotedMessageId: MessageId? = nil,
        extraData: ExtraData.Message = .defaultValue,
        completion: ((Result<MessageId, Error>) -> Void)? = nil
    ) {
        messageUpdater.createNewReply(
            in: cid,
            text: text,
            command: nil,
            arguments: nil,
            parentMessageId: messageId,
            attachments: attachments,
            showReplyInChannel: showReplyInChannel,
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
        extraData: ExtraData.MessageReaction = .defaultValue,
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

extension _ChatMessageController {
    struct Environment {
        var messageObserverBuilder: (
            _ context: NSManagedObjectContext,
            _ fetchRequest: NSFetchRequest<MessageDTO>,
            _ itemCreator: @escaping (MessageDTO) -> _ChatMessage<ExtraData>,
            _ fetchedResultsControllerType: NSFetchedResultsController<MessageDTO>.Type
        ) -> EntityDatabaseObserver<_ChatMessage<ExtraData>, MessageDTO> = EntityDatabaseObserver.init
        
        var messageUpdaterBuilder: (
            _ database: DatabaseContainer,
            _ apiClient: APIClient
        ) -> MessageUpdater<ExtraData> = MessageUpdater.init
    }
}

// MARK: - Private

private extension _ChatMessageController {
    func createMessageObserver() -> EntityDatabaseObserver<_ChatMessage<ExtraData>, MessageDTO> {
        let observer = environment.messageObserverBuilder(
            client.databaseContainer.viewContext,
            MessageDTO.message(withID: messageId),
            { $0.asModel() }, // swiftlint:disable:this opening_brace
            NSFetchedResultsController<MessageDTO>.self
        )
        
        do {
            try observer.startObserving()
            state = .localDataFetched
        } catch {
            log.error("Failed to perform fetch request with error: \(error). This is an internal error.")
            state = .localDataFetchFailed(ClientError(with: error))
        }
        
        return observer
    }

    func setRepliesObserver() {
        _repliesObserver.computeValue = { [unowned self] in
            let sortAscending = self.listOrdering == .topToBottom ? false : true
            let observer = ListDatabaseObserver(
                context: self.client.databaseContainer.viewContext,
                fetchRequest: MessageDTO.repliesFetchRequest(for: self.messageId, sortAscending: sortAscending),
                itemCreator: { $0.asModel() as _ChatMessage<ExtraData> }
            )
            observer.onChange = { changes in
                self.delegateCallback {
                    $0.messageController(self, didChangeReplies: changes)
                }
            }

            return observer
        }
    }
    
    func startRepliesObserver(completion: ((Error?) -> Void)? = nil) {
        _repliesObserver.reset()
        
        do {
            try repliesObserver?.startObserving()
            completion?(nil)
        } catch {
            log.error("Failed to perform fetch request with error: \(error). This is an internal error.")
            completion?(ClientError.FetchFailed())
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
    associatedtype ExtraData: ExtraDataTypes
    
    /// The controller observed a change in the `ChatMessage` its observes.
    func messageController(
        _ controller: _ChatMessageController<ExtraData>,
        didChangeMessage change: EntityChange<_ChatMessage<ExtraData>>
    )
    
    /// The controller observed changes in the replies of the observed `ChatMessage`.
    func messageController(
        _ controller: _ChatMessageController<ExtraData>,
        didChangeReplies changes: [ListChange<_ChatMessage<ExtraData>>]
    )
}

public extension _ChatMessageControllerDelegate {
    func messageController(
        _ controller: _ChatMessageController<ExtraData>,
        didChangeMessage change: EntityChange<_ChatMessage<ExtraData>>
    ) {}
    
    func messageController(
        _ controller: _ChatMessageController<ExtraData>,
        didChangeReplies changes: [ListChange<_ChatMessage<ExtraData>>]
    ) {}
}

final class AnyChatMessageControllerDelegate<ExtraData: ExtraDataTypes>: _ChatMessageControllerDelegate {
    weak var wrappedDelegate: AnyObject?
    private var _controllerDidChangeState: (DataController, DataController.State) -> Void
    private var _messageControllerDidChangeMessage: (_ChatMessageController<ExtraData>, EntityChange<_ChatMessage<ExtraData>>)
        -> Void
    private var _messageControllerDidChangeReplies: (_ChatMessageController<ExtraData>, [ListChange<_ChatMessage<ExtraData>>])
        -> Void
    
    init(
        wrappedDelegate: AnyObject?,
        controllerDidChangeState: @escaping (DataController, DataController.State) -> Void,
        messageControllerDidChangeMessage: @escaping (_ChatMessageController<ExtraData>, EntityChange<_ChatMessage<ExtraData>>)
            -> Void,
        messageControllerDidChangeReplies: @escaping (_ChatMessageController<ExtraData>, [ListChange<_ChatMessage<ExtraData>>])
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
        _ controller: _ChatMessageController<ExtraData>,
        didChangeMessage change: EntityChange<_ChatMessage<ExtraData>>
    ) {
        _messageControllerDidChangeMessage(controller, change)
    }
    
    func messageController(
        _ controller: _ChatMessageController<ExtraData>,
        didChangeReplies changes: [ListChange<_ChatMessage<ExtraData>>]
    ) {
        _messageControllerDidChangeReplies(controller, changes)
    }
}

extension AnyChatMessageControllerDelegate {
    convenience init<Delegate: _ChatMessageControllerDelegate>(_ delegate: Delegate) where Delegate.ExtraData == ExtraData {
        self.init(
            wrappedDelegate: delegate,
            controllerDidChangeState: { [weak delegate] in delegate?.controller($0, didChangeState: $1) },
            messageControllerDidChangeMessage: { [weak delegate] in delegate?.messageController($0, didChangeMessage: $1) },
            messageControllerDidChangeReplies: { [weak delegate] in delegate?.messageController($0, didChangeReplies: $1) }
        )
    }
}

extension AnyChatMessageControllerDelegate where ExtraData == NoExtraData {
    convenience init(_ delegate: ChatMessageControllerDelegate?) {
        self.init(
            wrappedDelegate: delegate,
            controllerDidChangeState: { [weak delegate] in delegate?.controller($0, didChangeState: $1) },
            messageControllerDidChangeMessage: { [weak delegate] in delegate?.messageController($0, didChangeMessage: $1) },
            messageControllerDidChangeReplies: { [weak delegate] in delegate?.messageController($0, didChangeReplies: $1) }
        )
    }
}
 
public extension _ChatMessageController {
    /// Sets the provided object as a delegate of this controller.
    ///
    /// - Note: If you don't use custom extra data types, you can set the delegate directly using `controller.delegate = self`.
    /// Due to the current limits of Swift and the way it handles protocols with associated types, it's required to use this
    /// method to set the delegate, if you're using custom extra data types.
    ///
    /// - Parameter delegate: The object used as a delegate. It's referenced weakly, so you need to keep the object
    /// alive if you want keep receiving updates.
    func setDelegate<Delegate: _ChatMessageControllerDelegate>(_ delegate: Delegate?) where Delegate.ExtraData == ExtraData {
        multicastDelegate.mainDelegate = delegate.flatMap(AnyChatMessageControllerDelegate.init)
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
