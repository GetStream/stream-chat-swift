//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

public extension Client {
    /// Creates a new `CurrentUserControllerGeneric`
    /// - Returns: A new instance of `ChannelController`.
    func currentUserController() -> CurrentUserControllerGeneric<ExtraData> {
        .init(client: self, environment: .init())
    }
}

/// A convenience typealias for `CurrentUserControllerGeneric` with `DefaultDataTypes`
public typealias CurrentUserController = CurrentUserControllerGeneric<DefaultDataTypes>

/// `CurrentUserControllerGeneric` allows to observer current user updates
public class CurrentUserControllerGeneric<ExtraData: ExtraDataTypes>: Controller, DelegateCallable, DataStoreProvider {
    /// The `ChatClient` instance this controller belongs to.
    public let client: Client<ExtraData>
    
    private let environment: Environment
    
    /// An internal backing object for all publicly available Combine publishers. We use it to simplify the way we expose
    /// publishers. Instead of creating custom `Publisher` types, we use `CurrentValueSubject` and `PassthroughSubject` internally,
    /// and expose the published values by mapping them to a read-only `AnyPublisher` type.
    @available(iOS 13, *)
    lazy var basePublishers: BasePublishers = .init(controller: self)

    /// Used for observing the curren-user changes in a database.
    private lazy var currentUserObserver = createUserObserver()
        .onChange { [unowned self] change in
            self.delegateCallback {
                $0.currentUserController(self, didChangeCurrentUser: change)
            }
        }
        .onFieldChange(\.unreadCount) { [unowned self] change in
            self.delegateCallback {
                $0.currentUserController(self, didChangeCurrentUserUnreadCount: change.unreadCount)
            }
        }
    
    /// The current connection status of the client.
    public var connectionStatus: ConnectionStatus {
        .init(webSocketConnectionState: client.webSocketClient.connectionState)
    }
    
    /// The connection event observer for the connection status updates.
    private lazy var connectionEventObserver = ConnectionEventObserver(
        notificationCenter: client.webSocketClient.eventNotificationCenter
    ) { [unowned self] status in
        self.delegateCallback {
            $0.currentUserController(self, didUpdateConnectionStatus: status.connectionStatus)
        }
    }

    /// A type-erased delegate.
    var multicastDelegate: MulticastDelegate<AnyCurrentUserControllerDelegate<ExtraData>> = .init() {
        didSet {
            stateMulticastDelegate.mainDelegate = multicastDelegate.mainDelegate
            stateMulticastDelegate.additionalDelegates = multicastDelegate.additionalDelegates
        }
    }
    
    /// The currently logged-in user.
    /// Always returns `nil` if `startUpdating` was not called
    /// To observe the updates of this value, set your class as a delegate of this controller and call `startUpdating`.
    public var currentUser: CurrentUserModel<ExtraData.User>? {
        guard state != .inactive else {
            log.warning("Accessing `currentUser` fields before calling `startUpdating()` always results in `nil`.")
            return nil
        }

        return currentUserObserver.item
    }

    /// The unread messages and channels count for the current user.
    /// Always returns `noUnread` if `startUpdating` was not called.
    /// To observe the updates of this value, set your class as a delegate of this controller and call `startUpdating`.
    public var unreadCount: UnreadCount {
        currentUser?.unreadCount ?? .noUnread
    }

    /// Creates a new `CurrentUserControllerGeneric`.
    /// - Parameters:
    ///   - client: The `Client` instance this controller belongs to.
    ///   - environment: The source of internal dependencies
    init(client: Client<ExtraData>, environment: Environment = .init()) {
        self.client = client
        self.environment = environment
        
        super.init()
        
        _ = connectionEventObserver
    }
    
    /// Starts updating the results.
    ///
    /// It **synchronously** loads the data for the referenced objects from the local cache.
    /// The `currentUser` and `unreadCount` properties are immediately available once this method returns.
    /// Any further changes to the data are communicated using `delegate`.
    ///
    /// - Parameter completion: Called when the controller has finished fetching data from a database.
    /// If the data fetching fails, the `error` variable contains more details about the problem.
    public func startUpdating(_ completion: ((Error?) -> Void)? = nil) {
        do {
            try currentUserObserver.startObserving()
        } catch {
            callback { completion?(ClientError.FetchFailed()) }
            return
        }
        
        state = .localDataFetched

        callback { completion?(nil) }
    }
    
    private func prepareEnvironmentForNewUser(
        userId: UserId,
        role: UserRole,
        extraData: ExtraData.User? = nil,
        completion: @escaping (Error?) -> Void
    ) {
        // Reset the current token
        client.currentToken = nil
        
        // Set up a new user id
        client.currentUserId = userId
        
        // Set a new WebSocketClient connect endpoint
        client.webSocketClient.connectEndpoint = .webSocketConnect(userId: userId, role: role, extraData: extraData)
        
        // Reset all existing data if the new user is not the same as the last logged-in one
        if client.databaseContainer.viewContext.currentUser()?.user.id != userId {
            // Re-create backgroundWorker's so their ongoing requests won't affect database state
            client.createBackgroundWorkers()

            // Reset all existing local data
            client.databaseContainer.removeAllData(force: true) { completion($0) }
        } else {
            // Otherwise we're done
            completion(nil)
        }
    }
}

// MARK: - Set current user

public extension CurrentUserControllerGeneric {
    /// Connects a client the controller owns to the chat servers.
    /// When the connection is established, `Client` starts receiving chat updates.
    ///
    /// - Parameter completion: Called when the connection is established. If the connection fails, the completion is
    /// called with an error.
    func connect(completion: ((Error?) -> Void)? = nil) {
        guard client.connectionId == nil else {
            log.warning("The client is already connected. Skipping the `connect` call.")
            completion?(nil)
            return
        }
        
        // Set up a waiter for the new connection id to know when the connection process is finished
        client.provideConnectionId { connectionId in
            if connectionId != nil {
                completion?(nil)
            } else {
                completion?(ClientError.ConnectionNotSuccessfull())
            }
        }
        
        client.webSocketClient.connect()
    }
    
    /// Disconnects a client the controller owns from the chat servers. No further updates from the servers are received.
    func disconnect() {
        // Disconnect the web socket
        client.webSocketClient.disconnect(source: .userInitiated)
        
        // Reset `connectionId`. This would happen asynchronously by the callback from WebSocketClient anyway, but it's
        // safer to do it here synchronously to immediately stop all API calls.
        client.connectionId = nil
        
        // Remove all waiters for connectionId
        client.connectionIdWaiters.removeAll()
    }
    
    /// Sets a new anonymous as a current user.
    ///
    /// Anonymous users have limited set of permissions. A typical use case for anonymous users are livestream channels,
    /// where they are allowed to read the conversation.
    ///
    /// - Parameters:
    ///   - completion: Called when the new anonymous user is set. If setting up the new user fails, the completion
    /// is called with an error.
    func setAnonymousUser(completion: ((Error?) -> Void)? = nil) {
        disconnect()
        prepareEnvironmentForNewUser(userId: .anonymous, role: .anonymous, extraData: nil) { error in
            guard error == nil else {
                completion?(error)
                return
            }
            
            self.connect(completion: completion)
        }
    }
    
    /// Sets a new **guest** user as a current user.
    ///
    /// Guest sessions do not require any server-side authentication.
    /// Guest users have a limited set of permissions.
    ///
    /// - Parameters:
    ///   - userId: The new guest-user identifier.
    ///   - extraData: The extra data of the new guest-user.
    ///   - completion: The completion. Will be called when the new guest user is set.
    ///                 If setting up the new user fails the completion will be called with an error.
    func setGuestUser(userId: UserId, extraData: ExtraData.User, completion: ((Error?) -> Void)? = nil) {
        disconnect()
        prepareEnvironmentForNewUser(userId: userId, role: .guest, extraData: extraData) { error in
            guard error == nil else {
                completion?(error)
                return
            }
            
            self.client.apiClient.request(endpoint: .guestUserToken(userId: userId, extraData: extraData)) {
                switch $0 {
                case let .success(payload):
                    self.client.currentToken = payload.token
                    self.connect(completion: completion)
                case let .failure(error):
                    completion?(error)
                }
            }
        }
    }
    
    /// Sets a new current user.
    ///
    /// - Important: Setting a new user disconnects all the existing controllers. You should create new controllers
    /// if you want to keep receiving updates about the newly set user.
    ///
    /// - Parameters:
    ///   - userId: The id of the new current user.
    ///   - userExtraData: You can optionally provide additional data to be set for the user. This is an equivalent of
    ///   setting the current user detail data manually using `CurrentUserController`.
    ///   - token: You can provide a token which is used for user authentication. If the `token` is not explicitly provided,
    ///   the client uses `ChatClientConfig.tokenProvider` to obtain a token. If you haven't specified the token provider,
    ///   providing a token explicitly is required. In case both the `token` and `ChatClientConfig.tokenProvider` is specified,
    ///   the `token` value is used.
    ///   - completion: Called when the new user is successfully set.
    func setUser(
        userId: UserId,
        userExtraData: ExtraData.User? = nil,
        token: Token? = nil,
        completion: ((Error?) -> Void)? = nil
    ) {
        guard token != nil || client.config.tokenProvider != nil else {
            log.assert(
                false,
                "The provided token is `nil` and `ChatClientConfig.tokenProvider` is also `nil`. You must either provide " +
                    "a token explicitly or set `TokenProvider` in `ChatClientConfig`."
            )
            completion?(ClientError.MissingToken())
            return
        }
        
        guard userId != client.currentUserId else {
            log.warning("New user with id:<\(userId)> is not set because it's similar to the already logged-in user.")
            completion?(nil)
            return
        }
        
        disconnect()
        
        prepareEnvironmentForNewUser(userId: userId, role: .user, extraData: userExtraData) { error in
            guard error == nil else {
                completion?(error)
                return
            }
            
            if let token = token {
                self.client.currentToken = token
                self.connect(completion: completion)
            } else {
                // Use `tokenProvider` to get the token
                self.client.refreshToken { error in
                    guard error == nil else {
                        completion?(error)
                        return
                    }
                    
                    self.connect(completion: completion)
                }
            }
        }
    }
}

// MARK: - Environment

extension CurrentUserControllerGeneric {
    struct Environment {
        var currentUserObserverBuilder: (
            _ context: NSManagedObjectContext,
            _ fetchRequest: NSFetchRequest<CurrentUserDTO>,
            _ itemCreator: @escaping (CurrentUserDTO) -> CurrentUserModel<ExtraData.User>,
            _ fetchedResultsControllerType: NSFetchedResultsController<CurrentUserDTO>.Type
        ) -> EntityDatabaseObserver<CurrentUserModel<ExtraData.User>, CurrentUserDTO> = EntityDatabaseObserver.init
    }
}

// MARK: - Private

private extension EntityChange where Item == UnreadCount {
    var unreadCount: UnreadCount {
        switch self {
        case let .create(count):
            return count
        case let .update(count):
            return count
        case .remove:
            return .noUnread
        }
    }
}

private extension CurrentUserControllerGeneric {
    func createUserObserver() -> EntityDatabaseObserver<CurrentUserModel<ExtraData.User>, CurrentUserDTO> {
        environment.currentUserObserverBuilder(
            client.databaseContainer.viewContext,
            CurrentUserDTO.defaultFetchRequest,
            { $0.asModel() }, // swiftlint:disable:this opening_brace
            NSFetchedResultsController<CurrentUserDTO>.self
        )
    }
}

// MARK: - Delegates

/// `CurrentUserController` uses this protocol to communicate changes to its delegate.
///
/// This protocol can be used only when no custom extra data are specified.
/// If you're using custom extra data types, please use `CurrentUserControllerDelegateGeneric` instead.
public protocol CurrentUserControllerDelegate: ControllerStateDelegate {
    /// The controller observed a change in the `UnreadCount`.
    func currentUserController(_ controller: CurrentUserController, didChangeCurrentUserUnreadCount: UnreadCount)
    
    /// The controller observed a change in the `CurrentUser` entity.
    func currentUserController(_ controller: CurrentUserController, didChangeCurrentUser: EntityChange<CurrentUser>)
    
    /// The controller observed a change in connection status.
    func currentUserController(_ controller: CurrentUserController, didUpdateConnectionStatus status: ConnectionStatus)
}

public extension CurrentUserControllerDelegate {
    func currentUserController(_ controller: CurrentUserController, didChangeCurrentUserUnreadCount: UnreadCount) {}
    
    func currentUserController(_ controller: CurrentUserController, didChangeCurrentUser: EntityChange<CurrentUser>) {}
    
    func currentUserController(_ controller: CurrentUserController, didUpdateConnectionStatus status: ConnectionStatus) {}
}

/// `CurrentUserControllerGeneric` uses this protocol to communicate changes to its delegate.
///
/// If you're **not** using custom extra data types, you can use a convenience version of this protocol
/// named `CurrentUserControllerDelegate`, which hides the generic types, and make the usage easier.
public protocol CurrentUserControllerDelegateGeneric: ControllerStateDelegate {
    associatedtype ExtraData: ExtraDataTypes
    
    /// The controller observed a change in the `UnreadCount`.
    func currentUserController(_ controller: CurrentUserControllerGeneric<ExtraData>, didChangeCurrentUserUnreadCount: UnreadCount)
    
    /// The controller observed a change in the `CurrentUser` entity.
    func currentUserController(
        _ controller: CurrentUserControllerGeneric<ExtraData>,
        didChangeCurrentUser: EntityChange<CurrentUserModel<ExtraData.User>>
    )
    
    /// The controller observed a change in connection status.
    func currentUserController(
        _ controller: CurrentUserControllerGeneric<ExtraData>,
        didUpdateConnectionStatus status: ConnectionStatus
    )
}

public extension CurrentUserControllerDelegateGeneric {
    func currentUserController(
        _ controller: CurrentUserControllerGeneric<ExtraData>,
        didChangeCurrentUserUnreadCount: UnreadCount
    ) {}
    
    func currentUserController(
        _ controller: CurrentUserControllerGeneric<ExtraData>,
        didChangeCurrentUser: EntityChange<CurrentUserModel<ExtraData.User>>
    ) {}
    
    func currentUserController(
        _ controller: CurrentUserControllerGeneric<ExtraData>,
        didUpdateConnectionStatus status: ConnectionStatus
    ) {}
}

final class AnyCurrentUserControllerDelegate<ExtraData: ExtraDataTypes>: CurrentUserControllerDelegateGeneric {
    weak var wrappedDelegate: AnyObject?
    
    private var _controllerDidChangeState: (
        Controller,
        Controller.State
    ) -> Void
    
    private var _controllerDidChangeCurrentUserUnreadCount: (
        CurrentUserControllerGeneric<ExtraData>,
        UnreadCount
    ) -> Void
    
    private var _controllerDidChangeCurrentUser: (
        CurrentUserControllerGeneric<ExtraData>,
        EntityChange<CurrentUserModel<ExtraData.User>>
    ) -> Void
    
    private var _controllerDidChangeConnectionStatus: (
        CurrentUserControllerGeneric<ExtraData>,
        ConnectionStatus
    ) -> Void
    
    init(
        wrappedDelegate: AnyObject?,
        controllerDidChangeState: @escaping (
            Controller,
            Controller.State
        ) -> Void,
        controllerDidChangeCurrentUserUnreadCount: @escaping (
            CurrentUserControllerGeneric<ExtraData>,
            UnreadCount
        ) -> Void,
        controllerDidChangeCurrentUser: @escaping (
            CurrentUserControllerGeneric<ExtraData>,
            EntityChange<CurrentUserModel<ExtraData.User>>
        ) -> Void,
        controllerDidChangeConnectionStatus: @escaping (
            CurrentUserControllerGeneric<ExtraData>,
            ConnectionStatus
        ) -> Void
    ) {
        self.wrappedDelegate = wrappedDelegate
        _controllerDidChangeCurrentUserUnreadCount = controllerDidChangeCurrentUserUnreadCount
        _controllerDidChangeState = controllerDidChangeState
        _controllerDidChangeCurrentUser = controllerDidChangeCurrentUser
        _controllerDidChangeConnectionStatus = controllerDidChangeConnectionStatus
    }

    func controller(_ controller: Controller, didChangeState state: Controller.State) {
        _controllerDidChangeState(controller, state)
    }

    func currentUserController(
        _ controller: CurrentUserControllerGeneric<ExtraData>,
        didChangeCurrentUserUnreadCount unreadCount: UnreadCount
    ) {
        _controllerDidChangeCurrentUserUnreadCount(controller, unreadCount)
    }
    
    func currentUserController(
        _ controller: CurrentUserControllerGeneric<ExtraData>,
        didChangeCurrentUser user: EntityChange<CurrentUserModel<ExtraData.User>>
    ) {
        _controllerDidChangeCurrentUser(controller, user)
    }
    
    func currentUserController(
        _ controller: CurrentUserControllerGeneric<ExtraData>,
        didUpdateConnectionStatus status: ConnectionStatus
    ) {
        _controllerDidChangeConnectionStatus(controller, status)
    }
}

extension AnyCurrentUserControllerDelegate {
    convenience init<Delegate: CurrentUserControllerDelegateGeneric>(_ delegate: Delegate) where Delegate.ExtraData == ExtraData {
        self.init(
            wrappedDelegate: delegate,
            controllerDidChangeState: { [weak delegate] in delegate?.controller($0, didChangeState: $1) },
            controllerDidChangeCurrentUserUnreadCount: { [weak delegate] in
                delegate?.currentUserController($0, didChangeCurrentUserUnreadCount: $1)
            },
            controllerDidChangeCurrentUser: { [weak delegate] in
                delegate?.currentUserController($0, didChangeCurrentUser: $1)
            },
            controllerDidChangeConnectionStatus: { [weak delegate] in
                delegate?.currentUserController($0, didUpdateConnectionStatus: $1)
            }
        )
    }
}

extension AnyCurrentUserControllerDelegate where ExtraData == DefaultDataTypes {
    convenience init(_ delegate: CurrentUserControllerDelegate?) {
        self.init(
            wrappedDelegate: delegate,
            controllerDidChangeState: { [weak delegate] in delegate?.controller($0, didChangeState: $1) },
            controllerDidChangeCurrentUserUnreadCount: { [weak delegate] in
                delegate?.currentUserController($0, didChangeCurrentUserUnreadCount: $1)
            },
            controllerDidChangeCurrentUser: { [weak delegate] in
                delegate?.currentUserController($0, didChangeCurrentUser: $1)
            },
            controllerDidChangeConnectionStatus: { [weak delegate] in
                delegate?.currentUserController($0, didUpdateConnectionStatus: $1)
            }
        )
    }
}
 
public extension CurrentUserControllerGeneric {
    /// Sets the provided object as a delegate of this controller.
    ///
    /// - Note: If you don't use custom extra data types, you can set the delegate directly using `controller.delegate = self`.
    /// Due to the current limits of Swift and the way it handles protocols with associated types, it's required to use this
    /// method to set the delegate, if you're using custom extra data types.
    ///
    /// - Parameter delegate: The object used as a delegate. It's referenced weakly, so you need to keep the object
    /// alive if you want keep receiving updates.
    func setDelegate<Delegate: CurrentUserControllerDelegateGeneric>(_ delegate: Delegate?) where Delegate.ExtraData == ExtraData {
        multicastDelegate.mainDelegate = delegate.flatMap(AnyCurrentUserControllerDelegate.init)
    }
}

public extension CurrentUserController {
    /// Set the delegate of `CurrentUserController` to observe the changes in the system.
    ///
    /// - Note: The delegate can be set directly only if you're **not** using custom extra data types. Due to the current
    /// limits of Swift and the way it handles protocols with associated types, it's required to use `setDelegate` method
    /// instead to set the delegate, if you're using custom extra data types.
    var delegate: CurrentUserControllerDelegate? {
        set { multicastDelegate.mainDelegate = AnyCurrentUserControllerDelegate(newValue) }
        get { multicastDelegate.mainDelegate?.wrappedDelegate as? CurrentUserControllerDelegate }
    }
}

/// A connection event observer to handle `ConnectionStatusUpdated` events.
private class ConnectionEventObserver: EventObserver {
    init(
        notificationCenter: NotificationCenter,
        filter: ((ConnectionStatusUpdated) -> Bool)? = nil,
        callback: @escaping (ConnectionStatusUpdated) -> Void
    ) {
        super.init(notificationCenter: notificationCenter, transform: { $0 as? ConnectionStatusUpdated }) {
            guard filter == nil || filter?($0) == true else { return }
            callback($0)
        }
    }
}
