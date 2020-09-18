//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

public extension _ChatClient {
    /// Creates a new `MessageController` for the message with the provided id.
    /// - Parameter cid: The channel identifer the message relates to.
    /// - Parameter messageId: The message identifier.
    /// - Returns: A new instance of `MessageController`.
    func messageController(cid: ChannelId, messageId: MessageId) -> MessageControllerGeneric<ExtraData> {
        .init(client: self, cid: cid, messageId: messageId)
    }
}

/// A convenience typealias for `MessageControllerGeneric` with `DefaultExtraData`.
public typealias MessageController = MessageControllerGeneric<DefaultExtraData>

/// The `MessageControllerGeneric` is designed to edit the message it was created with.
public class MessageControllerGeneric<ExtraData: ExtraDataTypes>: DataController, DelegateCallable {
    /// The `ChatClient` instance this controller belongs to.
    public let client: _ChatClient<ExtraData>
    
    /// The channel identifier the message is related to.
    public let cid: ChannelId
    
    /// The message identifier this controller manages.
    public let messageId: MessageId
    
    /// The message data
    /// To observe the updates of this value, set your class as a delegate of this controller or use `Combine` wrapper.
    public var message: MessageModel<ExtraData>? { messageObserver.item }
    
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
    
    /// Synchronize local data with remote.
    ///
    /// 1. **Synchronously** loads the data for the referenced objects from the local cache if it is not loaded yet.
    /// Any further changes to the data are communicated using `delegate`.
    ///
    /// 2. It also **asynchronously** fetches the latest version of the data from the servers. Once the remote fetch is completed,
    /// the completion block is called. If the updated data differ from the locally cached ones, the controller uses the `delegate`
    /// methods to inform about the changes.
    ///
    /// - Parameter completion: Called when the controller has finished fetching remote data.
    ///                         If the data fetching fails, the `error` variable contains more details about the problem.
    public func synchronize(_ completion: ((Error?) -> Void)? = nil) {
        startMessageObserver()
        
        messageUpdater.getMessage(cid: cid, messageId: messageId) { [weak self] error in
            guard let self = self else { return }
            self.state = error == nil ? .remoteDataFetched : .remoteDataFetchFailed(ClientError(with: error))
            self.callback { completion?(error) }
        }
    }
    
    /// Initializing of `messageObserver` will start local data observing.
    /// In most cases it will be done by accesing `messages` but it's possible that only
    /// changes will be observed.
    private func startMessageObserver() {
        _ = messageObserver
    }
}

// MARK: - Actions

public extension MessageControllerGeneric {
    /// Edits the message this controller manages with the provided values.
    /// - Parameters:
    ///   - text: The updated message text.
    ///   - completion: The completion. Will be called on a **callbackQueue** when the network request is finished.
    ///                 If request fails, the completion will be called with an error.
    func editMessage(text: String, completion: ((Error?) -> Void)? = nil) {
        messageUpdater.editMessage(messageId: messageId, text: text) { [weak self] error in
            self?.callback {
                completion?(error)
            }
        }
    }
    
    /// Delete the message this controller manages.
    /// - Parameters:
    ///   - completion: The completion. Will be called on a **callbackQueue** when the network request is finished.
    ///                 If request fails, the completion will be called with an error.
    func deleteMessage(completion: ((Error?) -> Void)? = nil) {
        messageUpdater.deleteMessage(messageId: messageId) { [weak self] error in
            self?.callback {
                completion?(error)
            }
        }
    }
}

// MARK: - Environment

extension MessageControllerGeneric {
    struct Environment {
        var messageObserverBuilder: (
            _ context: NSManagedObjectContext,
            _ fetchRequest: NSFetchRequest<MessageDTO>,
            _ itemCreator: @escaping (MessageDTO) -> MessageModel<ExtraData>,
            _ fetchedResultsControllerType: NSFetchedResultsController<MessageDTO>.Type
        ) -> EntityDatabaseObserver<MessageModel<ExtraData>, MessageDTO> = EntityDatabaseObserver.init
        
        var messageUpdaterBuilder: (
            _ database: DatabaseContainer,
            _ webSocketClient: WebSocketClient,
            _ apiClient: APIClient
        ) -> MessageUpdater<ExtraData> = MessageUpdater.init
    }
}

// MARK: - Private

private extension MessageControllerGeneric {
    func createMessageObserver() -> EntityDatabaseObserver<MessageModel<ExtraData>, MessageDTO> {
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

/// `MessageController` uses this protocol to communicate changes to its delegate.
///
/// This protocol can be used only when no custom extra data are specified.
/// If you're using custom extra data types, please use `MessageControllerDelegateGeneric` instead.
public protocol MessageControllerDelegate: DataControllerStateDelegate {
    /// The controller observed a change in the `Message`.
    func messageController(_ controller: MessageController, didChangeMessage change: EntityChange<Message>)
}

public extension MessageControllerDelegate {
    func messageController(_ controller: MessageController, didChangeMessage change: EntityChange<Message>) {}
}

/// `MessageControllerDelegateGeneric` uses this protocol to communicate changes to its delegate.
///
/// If you're **not** using custom extra data types, you can use a convenience version of this protocol
/// named `MessageControllerDelegate`, which hides the generic types, and make the usage easier.
public protocol MessageControllerDelegateGeneric: DataControllerStateDelegate {
    associatedtype ExtraData: ExtraDataTypes
    
    /// The controller observed a change in the `MessageModel<ExtraData>`.
    func messageController(
        _ controller: MessageControllerGeneric<ExtraData>,
        didChangeMessage change: EntityChange<MessageModel<ExtraData>>
    )
}

public extension MessageControllerDelegateGeneric {
    func messageController(
        _ controller: MessageControllerGeneric<ExtraData>,
        didChangeMessage change: EntityChange<MessageModel<ExtraData>>
    ) {}
}

final class AnyMessageControllerDelegate<ExtraData: ExtraDataTypes>: MessageControllerDelegateGeneric {
    weak var wrappedDelegate: AnyObject?
    private var _controllerDidChangeState: (DataController, DataController.State) -> Void
    private var _messageControllerDidChangeMessage: (MessageControllerGeneric<ExtraData>, EntityChange<MessageModel<ExtraData>>)
        -> Void
    
    init(
        wrappedDelegate: AnyObject?,
        controllerDidChangeState: @escaping (DataController, DataController.State) -> Void,
        messageControllerDidChangeMessage: @escaping (MessageControllerGeneric<ExtraData>, EntityChange<MessageModel<ExtraData>>)
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
        _ controller: MessageControllerGeneric<ExtraData>,
        didChangeMessage change: EntityChange<MessageModel<ExtraData>>
    ) {
        _messageControllerDidChangeMessage(controller, change)
    }
}

extension AnyMessageControllerDelegate {
    convenience init<Delegate: MessageControllerDelegateGeneric>(_ delegate: Delegate) where Delegate.ExtraData == ExtraData {
        self.init(
            wrappedDelegate: delegate,
            controllerDidChangeState: { [weak delegate] in delegate?.controller($0, didChangeState: $1) },
            messageControllerDidChangeMessage: { [weak delegate] in delegate?.messageController($0, didChangeMessage: $1) }
        )
    }
}

extension AnyMessageControllerDelegate where ExtraData == DefaultExtraData {
    convenience init(_ delegate: MessageControllerDelegate?) {
        self.init(
            wrappedDelegate: delegate,
            controllerDidChangeState: { [weak delegate] in delegate?.controller($0, didChangeState: $1) },
            messageControllerDidChangeMessage: { [weak delegate] in delegate?.messageController($0, didChangeMessage: $1) }
        )
    }
}
 
public extension MessageControllerGeneric {
    /// Sets the provided object as a delegate of this controller.
    ///
    /// - Note: If you don't use custom extra data types, you can set the delegate directly using `controller.delegate = self`.
    /// Due to the current limits of Swift and the way it handles protocols with associated types, it's required to use this
    /// method to set the delegate, if you're using custom extra data types.
    ///
    /// - Parameter delegate: The object used as a delegate. It's referenced weakly, so you need to keep the object
    /// alive if you want keep receiving updates.
    func setDelegate<Delegate: MessageControllerDelegateGeneric>(_ delegate: Delegate?) where Delegate.ExtraData == ExtraData {
        multicastDelegate.mainDelegate = delegate.flatMap(AnyMessageControllerDelegate.init)
    }
}

public extension MessageController {
    /// Set the delegate of `MessageController` to observe the changes in the system.
    ///
    /// - Note: The delegate can be set directly only if you're **not** using custom extra data types. Due to the current
    /// limits of Swift and the way it handles protocols with associated types, it's required to use `setDelegate` method
    /// instead to set the delegate, if you're using custom extra data types.
    var delegate: MessageControllerDelegate? {
        set { multicastDelegate.mainDelegate = AnyMessageControllerDelegate(newValue) }
        get { multicastDelegate.mainDelegate?.wrappedDelegate as? MessageControllerDelegate }
    }
}
