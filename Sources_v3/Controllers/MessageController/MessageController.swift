//
// Copyright © 2020 Stream.io Inc. All rights reserved.
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
/// Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/StreamChat-SDK-Cheat-Sheet#working-with-extra-data).
///
public typealias ChatMessageController = _ChatMessageController<DefaultExtraData>

/// `ChatMessageController` is a controller class which allows observing and mutating a chat message entity.
///
/// Learn more about `ChatMessageController` and its usage in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/StreamChat-SDK-Cheat-Sheet#messages).
///
/// - Note: `_ChatMessageController` type is not meant to be used directly. If you're using default extra data, use
/// `ChatMessageController` typealias instead. If you're using custom extra data, create your own typealias
/// of `_ChatMessageController`.
///
/// Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/StreamChat-SDK-Cheat-Sheet#working-with-extra-data).
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
    
    private let environment: Environment
    
    /// An internal backing object for all publicly available Combine publishers. We use it to simplify the way we expose
    /// publishers. Instead of creating custom `Publisher` types, we use `CurrentValueSubject` and `PassthroughSubject` internally,
    /// and expose the published values by mapping them to a read-only `AnyPublisher` type.
    @available(iOS 13, *)
    lazy var basePublishers: BasePublishers = .init(controller: self)
    
    /// A type-erased multicast delegate.
    var multicastDelegate: MulticastDelegate<AnyMessageControllerDelegate<ExtraData>> = .init() {
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
    
    /// The worker used to fetch the remote data and communicate with servers.
    private lazy var messageUpdater: MessageUpdater<ExtraData> = environment.messageUpdaterBuilder(
        client.databaseContainer,
        client.webSocketClient,
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
    }

    override public func synchronize(_ completion: ((Error?) -> Void)? = nil) {
        startMessageObserver()
        
        messageUpdater.getMessage(cid: cid, messageId: messageId) { [weak self] error in
            guard let self = self else { return }
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
        messageUpdater.editMessage(messageId: messageId, text: text) { [weak self] error in
            self?.callback {
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
        messageUpdater.deleteMessage(messageId: messageId) { [weak self] error in
            self?.callback {
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
            _ webSocketClient: WebSocketClient,
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
}

// MARK: - Delegate

/// `ChatMessageController` uses this protocol to communicate changes to its delegate.
///
/// This protocol can be used only when no custom extra data are specified.
/// If you're using custom extra data types, please use `_MessageControllerDelegate` instead.
///
public protocol ChatMessageControllerDelegate: DataControllerStateDelegate {
    /// The controller observed a change in the `ChatMessage` its observes.
    func messageController(_ controller: ChatMessageController, didChangeMessage change: EntityChange<ChatMessage>)
}

public extension ChatMessageControllerDelegate {
    func messageController(_ controller: ChatMessageController, didChangeMessage change: EntityChange<ChatMessage>) {}
}

/// `_MessageControllerDelegate` uses this protocol to communicate changes to its delegate.
///
/// If you're **not** using custom extra data types, you can use a convenience version of this protocol
/// named `MessageControllerDelegate`, which hides the generic types, and make the usage easier.
///
public protocol _MessageControllerDelegate: DataControllerStateDelegate {
    associatedtype ExtraData: ExtraDataTypes
    
    /// The controller observed a change in the `ChatMessage` its observes.
    func messageController(
        _ controller: _ChatMessageController<ExtraData>,
        didChangeMessage change: EntityChange<_ChatMessage<ExtraData>>
    )
}

public extension _MessageControllerDelegate {
    func messageController(
        _ controller: _ChatMessageController<ExtraData>,
        didChangeMessage change: EntityChange<_ChatMessage<ExtraData>>
    ) {}
}

final class AnyMessageControllerDelegate<ExtraData: ExtraDataTypes>: _MessageControllerDelegate {
    weak var wrappedDelegate: AnyObject?
    private var _controllerDidChangeState: (DataController, DataController.State) -> Void
    private var _messageControllerDidChangeMessage: (_ChatMessageController<ExtraData>, EntityChange<_ChatMessage<ExtraData>>)
        -> Void
    
    init(
        wrappedDelegate: AnyObject?,
        controllerDidChangeState: @escaping (DataController, DataController.State) -> Void,
        messageControllerDidChangeMessage: @escaping (_ChatMessageController<ExtraData>, EntityChange<_ChatMessage<ExtraData>>)
            -> Void
    ) {
        self.wrappedDelegate = wrappedDelegate
        _controllerDidChangeState = controllerDidChangeState
        _messageControllerDidChangeMessage = messageControllerDidChangeMessage
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
}

extension AnyMessageControllerDelegate {
    convenience init<Delegate: _MessageControllerDelegate>(_ delegate: Delegate) where Delegate.ExtraData == ExtraData {
        self.init(
            wrappedDelegate: delegate,
            controllerDidChangeState: { [weak delegate] in delegate?.controller($0, didChangeState: $1) },
            messageControllerDidChangeMessage: { [weak delegate] in delegate?.messageController($0, didChangeMessage: $1) }
        )
    }
}

extension AnyMessageControllerDelegate where ExtraData == DefaultExtraData {
    convenience init(_ delegate: ChatMessageControllerDelegate?) {
        self.init(
            wrappedDelegate: delegate,
            controllerDidChangeState: { [weak delegate] in delegate?.controller($0, didChangeState: $1) },
            messageControllerDidChangeMessage: { [weak delegate] in delegate?.messageController($0, didChangeMessage: $1) }
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
    func setDelegate<Delegate: _MessageControllerDelegate>(_ delegate: Delegate?) where Delegate.ExtraData == ExtraData {
        multicastDelegate.mainDelegate = delegate.flatMap(AnyMessageControllerDelegate.init)
    }
}

public extension ChatMessageController {
    /// Set the delegate of `ChatMessageController` to observe the changes in the system.
    ///
    /// - Note: The delegate can be set directly only if you're **not** using custom extra data types. Due to the current
    /// limits of Swift and the way it handles protocols with associated types, it's required to use `setDelegate` method
    /// instead to set the delegate, if you're using custom extra data types.
    var delegate: ChatMessageControllerDelegate? {
        set { multicastDelegate.mainDelegate = AnyMessageControllerDelegate(newValue) }
        get { multicastDelegate.mainDelegate?.wrappedDelegate as? ChatMessageControllerDelegate }
    }
}
