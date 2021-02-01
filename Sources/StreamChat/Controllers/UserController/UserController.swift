//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

public extension _ChatClient {
    /// Creates a new `_ChatUserController` for the user with the provided `userId`.
    ///
    /// - Parameter userId: The user identifier.
    /// - Returns: A new instance of `_ChatUserController`.
    func userController(userId: UserId) -> _ChatUserController<ExtraData> {
        .init(userId: userId, client: self)
    }
}

/// `ChatUserController` is a controller class which allows mutating and observing changes of a specific chat user.
///
/// `ChatUserController` objects are lightweight, and they can be used for both, continuous data change observations,
/// and for quick user actions (like mute/unmute).
///
/// - Note: `ChatUserController` is a typealias of `_ChatUserController` with default extra data. If you're using custom
/// extra data, create your own typealias of `_ChatUserController`.
///
/// Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheet#working-with-extra-data).
///
public typealias ChatUserController = _ChatUserController<NoExtraData>

/// `_ChatUserController` is a controller class which allows mutating and observing changes of a specific chat user.
///
/// `_ChatUserController` objects are lightweight, and they can be used for both, continuous data change observations,
/// and for quick user actions (like mute/unmute).
///
/// - Note: `ChatUserController` is a typealias of `_ChatUserController` with default extra data. If you're using custom
/// extra data, create your own typealias of `_ChatUserController`.
///
/// Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheet#working-with-extra-data).
///
public class _ChatUserController<ExtraData: ExtraDataTypes>: DataController, DelegateCallable, DataStoreProvider {
    /// The identifier of tge user this controller observes.
    public let userId: UserId
    
    /// The `ChatClient` instance this controller belongs to.
    public let client: _ChatClient<ExtraData>
    
    /// The user the controller represents.
    ///
    /// To observe changes of the user, set your class as a delegate of this controller or use the provided
    /// `Combine` publishers.
    public var user: _ChatUser<ExtraData.User>? {
        startObservingIfNeeded()
        return userObserver.item
    }
    
    /// A type-erased delegate.
    var multicastDelegate: MulticastDelegate<AnyChatUserControllerDelegate<ExtraData>> = .init() {
        didSet {
            stateMulticastDelegate.mainDelegate = multicastDelegate.mainDelegate
            stateMulticastDelegate.additionalDelegates = multicastDelegate.additionalDelegates
            startObservingIfNeeded()
        }
    }
    
    /// The worker used to fetch the remote data and communicate with servers.
    private lazy var userUpdater = createUserUpdater()
    
    /// The observer used to track the user changes in the database.
    private lazy var userObserver = createUserObserver()
        .onChange { [unowned self] change in
            self.delegateCallback {
                $0.userController(self, didUpdateUser: change)
            }
        }
    
    private let environment: Environment
    
    /// An internal backing object for all publicly available Combine publishers. We use it to simplify the way we expose
    /// publishers. Instead of creating custom `Publisher` types, we use `CurrentValueSubject` and `PassthroughSubject` internally,
    /// and expose the published values by mapping them to a read-only `AnyPublisher` type.
    @available(iOS 13, *)
    lazy var basePublishers: BasePublishers = .init(controller: self)

    /// Creates a new `_ChatUserController`
    /// - Parameters:
    ///   - userId: The identifier of the user this controller manages.
    ///   - client: The `Client` this controller belongs to.
    ///   - environment: Environment for this controller.
    init(
        userId: UserId,
        client: _ChatClient<ExtraData>,
        environment: Environment = .init()
    ) {
        self.userId = userId
        self.client = client
        self.environment = environment
    }
    
    override public func synchronize(_ completion: ((_ error: Error?) -> Void)? = nil) {
        startObservingIfNeeded()
        
        if case let .localDataFetchFailed(error) = state {
            callback { completion?(error) }
            return
        }
        
        userUpdater.loadUser(userId) { error in
            self.state = error == nil ? .remoteDataFetched : .remoteDataFetchFailed(ClientError(with: error))
            self.callback { completion?(error) }
        }
    }
    
    /// Sets the provided object as a delegate of this controller.
    ///
    /// - Note: If you don't use custom extra data types, you can set the delegate directly using `controller.delegate = self`.
    /// Due to the current limits of Swift and the way it handles protocols with associated types, it's required to use this
    /// method to set the delegate, if you're using custom extra data types.
    ///
    /// - Parameter delegate: The object used as a delegate. It's referenced weakly, so you need to keep the object
    /// alive if you want keep receiving updates.
    ///
    public func setDelegate<Delegate: _ChatUserControllerDelegate>(_ delegate: Delegate)
        where Delegate.ExtraData == ExtraData {
        multicastDelegate.mainDelegate = AnyChatUserControllerDelegate(delegate)
    }
    
    // MARK: - Private
    
    private func createUserUpdater() -> UserUpdater<ExtraData> {
        environment.userUpdaterBuilder(
            client.databaseContainer,
            client.apiClient
        )
    }
    
    private func createUserObserver() -> EntityDatabaseObserver<_ChatUser<ExtraData.User>, UserDTO> {
        environment.userObserverBuilder(
            client.databaseContainer.viewContext,
            UserDTO.user(withID: userId),
            { $0.asModel() },
            NSFetchedResultsController<UserDTO>.self
        )
    }
    
    private func startObservingIfNeeded() {
        guard state == .initialized else { return }
        
        do {
            try userObserver.startObserving()
            state = .localDataFetched
        } catch {
            log.error("Observing user with id <\(userId)> failed: \(error). Accessing `user` will always return `nil`")
            state = .localDataFetchFailed(ClientError(with: error))
        }
    }
}

// MARK: - User actions

public extension _ChatUserController {
    /// Mutes the user this controller manages.
    /// - Parameter completion: The completion. Will be called on a **callbackQueue** when the network request is finished.
    ///                         If request fails, the completion will be called with an error.
    func mute(completion: ((Error?) -> Void)? = nil) {
        userUpdater.muteUser(userId) { error in
            self.callback {
                completion?(error)
            }
        }
    }
    
    /// Unmutes the user this controller manages.
    /// - Parameter completion: The completion. Will be called on a **callbackQueue** when the network request is finished.
    ///
    func unmute(completion: ((Error?) -> Void)? = nil) {
        userUpdater.unmuteUser(userId) { error in
            self.callback {
                completion?(error)
            }
        }
    }
    
    /// Flags the user this controller manages.
    /// - Parameter completion: The completion. Will be called on a **callbackQueue** when the network request is finished.
    ///                         If request fails, the completion will be called with an error.
    func flag(completion: ((Error?) -> Void)? = nil) {
        userUpdater.flagUser(true, with: userId) { error in
            self.callback {
                completion?(error)
            }
        }
    }
    
    /// Unflags the user this controller manages.
    /// - Parameter completion: The completion. Will be called on a **callbackQueue** when the network request is finished.
    ///
    func unflag(completion: ((Error?) -> Void)? = nil) {
        userUpdater.flagUser(false, with: userId) { error in
            self.callback {
                completion?(error)
            }
        }
    }
}

extension _ChatUserController {
    struct Environment {
        var userUpdaterBuilder: (
            _ database: DatabaseContainer,
            _ apiClient: APIClient
        ) -> UserUpdater<ExtraData> = UserUpdater.init
        
        var userObserverBuilder: (
            _ context: NSManagedObjectContext,
            _ fetchRequest: NSFetchRequest<UserDTO>,
            _ itemCreator: @escaping (UserDTO) -> _ChatUser<ExtraData.User>,
            _ fetchedResultsControllerType: NSFetchedResultsController<UserDTO>.Type
        ) -> EntityDatabaseObserver<_ChatUser<ExtraData.User>, UserDTO> = EntityDatabaseObserver.init
    }
}

public extension _ChatUserController where ExtraData == NoExtraData {
    /// Set the delegate of `ChatUserController` to observe the changes in the system.
    ///
    /// - Note: The delegate can be set directly only if you're **not** using custom extra data types. Due to the current
    /// limits of Swift and the way it handles protocols with associated types, it's required to use `setDelegate` method
    /// instead to set the delegate, if you're using custom extra data types.
    var delegate: ChatUserControllerDelegate? {
        get { multicastDelegate.mainDelegate?.wrappedDelegate as? ChatUserControllerDelegate }
        set { multicastDelegate.mainDelegate = AnyChatUserControllerDelegate(newValue) }
    }
}

// MARK: - Delegates

/// `ChatUserControllerDelegate` uses this protocol to communicate changes to its delegate.
///
/// This protocol can be used only when no custom extra data are specified. If you're using custom extra data types,
/// please use `_ChatUserControllerDelegate` instead.
///
public protocol ChatUserControllerDelegate: DataControllerStateDelegate {
    /// The controller observed a change in the `ChatUser` entity.
    func userController(
        _ controller: ChatUserController,
        didUpdateUser change: EntityChange<ChatUser>
    )
}

public extension ChatChannelControllerDelegate {
    func userController(
        _ controller: ChatUserController,
        didUpdateUser change: EntityChange<ChatUser>
    ) {}
}

// MARK: Generic Delegates

/// `ChatChannelController` uses this protocol to communicate changes to its delegate.
///
/// If you're **not** using custom extra data types, you can use a convenience version of this protocol
/// named `ChatChannelControllerDelegate`, which hides the generic types, and make the usage easier.
///
public protocol _ChatUserControllerDelegate: DataControllerStateDelegate {
    associatedtype ExtraData: ExtraDataTypes
    
    /// The controller observed a change in the `_ChatUser<ExtraData.User>` entity.
    func userController(
        _ controller: _ChatUserController<ExtraData>,
        didUpdateUser change: EntityChange<_ChatUser<ExtraData.User>>
    )
}

public extension _ChatChannelControllerDelegate {
    func userController(
        _ controller: _ChatUserController<ExtraData>,
        didUpdateUser change: EntityChange<_ChatUser<ExtraData.User>>
    ) {}
}

// MARK: Type erased Delegate

class AnyChatUserControllerDelegate<ExtraData: ExtraDataTypes>: _ChatChannelControllerDelegate {
    private var _controllerDidChangeState: (DataController, DataController.State) -> Void
    
    private var _controllerDidUpdateUser: (
        _ChatUserController<ExtraData>,
        EntityChange<_ChatUser<ExtraData.User>>
    ) -> Void
    
    weak var wrappedDelegate: AnyObject?
    
    init(
        wrappedDelegate: AnyObject?,
        controllerDidChangeState: @escaping (DataController, DataController.State) -> Void,
        controllerDidUpdateUser: @escaping (
            _ChatUserController<ExtraData>,
            EntityChange<_ChatUser<ExtraData.User>>
        ) -> Void
    ) {
        self.wrappedDelegate = wrappedDelegate
        _controllerDidChangeState = controllerDidChangeState
        _controllerDidUpdateUser = controllerDidUpdateUser
    }
    
    func controller(_ controller: DataController, didChangeState state: DataController.State) {
        _controllerDidChangeState(controller, state)
    }
    
    func userController(
        _ controller: _ChatUserController<ExtraData>,
        didUpdateUser change: EntityChange<_ChatUser<ExtraData.User>>
    ) {
        _controllerDidUpdateUser(controller, change)
    }
}

extension AnyChatUserControllerDelegate {
    convenience init<Delegate: _ChatUserControllerDelegate>(_ delegate: Delegate) where Delegate.ExtraData == ExtraData {
        self.init(
            wrappedDelegate: delegate,
            controllerDidChangeState: { [weak delegate] in delegate?.controller($0, didChangeState: $1) },
            controllerDidUpdateUser: { [weak delegate] in delegate?.userController($0, didUpdateUser: $1) }
        )
    }
}

extension AnyChatUserControllerDelegate where ExtraData == NoExtraData {
    convenience init(_ delegate: ChatUserControllerDelegate?) {
        self.init(
            wrappedDelegate: delegate,
            controllerDidChangeState: { [weak delegate] in delegate?.controller($0, didChangeState: $1) },
            controllerDidUpdateUser: { [weak delegate] in delegate?.userController($0, didUpdateUser: $1) }
        )
    }
}
