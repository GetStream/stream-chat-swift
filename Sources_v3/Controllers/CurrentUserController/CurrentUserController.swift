//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

public extension _ChatClient {
    /// Creates a new `CurrentUserController` instance.
    ///
    /// - Returns: A new instance of `ChannelController`.
    ///
    func currentUserController() -> _CurrentChatUserController<ExtraData> {
        .init(client: self)
    }
}

/// `CurrentChatUserController` is a controller class which allows observing and mutating the currently logged-in
/// user of `ChatClient`. You can also use it to explicitly connect/disconnect the `ChatClient`.
///
/// Learn more about `CurrentChatUserController` and its usage in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/StreamChat-SDK-Cheat-Sheet#user).
///
/// - Note: `CurrentChatUserController` is a typealias of `_CurrentChatUserController` with default extra data. If you're using
/// custom extra data, create your own typealias of `_CurrentChatUserController`.
///
/// Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/StreamChat-SDK-Cheat-Sheet#working-with-extra-data).
///
public typealias CurrentChatUserController = _CurrentChatUserController<DefaultExtraData>

/// `CurrentChatUserController` is a controller class which allows observing and mutating the currently logged-in
/// user of `ChatClient`. You can also use it to explicitly connect/disconnect the `ChatClient`.
///
/// Learn more about `CurrentChatUserController` and its usage in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/StreamChat-SDK-Cheat-Sheet#user).
///
/// - Note: `_CurrentChatUserController` type is not meant to be used directly. If you're using default extra data, use
/// `CurrentChatUserController` typealias instead. If you're using custom extra data, create your own typealias
/// of `_CurrentChatUserController`.
///
/// Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/StreamChat-SDK-Cheat-Sheet#working-with-extra-data).
///
public class _CurrentChatUserController<ExtraData: ExtraDataTypes>: Controller, DelegateCallable, DataStoreProvider {
    public var callbackQueue: DispatchQueue = .main
    
    /// The `ChatClient` instance this controller belongs to.
    public let client: _ChatClient<ExtraData>
    
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
    ///
    /// To observe changes of the connection status, set your class as a delegate of this controller or use the provided
    /// `Combine` publishers.
    ///
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
    // swiftlint:disable:next weak_delegate
    var multicastDelegate: MulticastDelegate<AnyCurrentUserControllerDelegate<ExtraData>> = .init()
    
    /// The currently logged-in user. `nil` if the connection hasn't been fully established yet, or the connection
    /// wasn't successful.
    public var currentUser: _CurrentChatUser<ExtraData.User>? {
        currentUserObserver.item
    }

    /// The unread messages and channels count for the current user.
    ///
    /// Returns `noUnread` if `currentUser` doesn't exist yet.
    ///
    public var unreadCount: UnreadCount {
        currentUser?.unreadCount ?? .noUnread
    }

    /// Creates a new `CurrentUserControllerGeneric`.
    ///
    /// - Parameters:
    ///   - client: The `Client` instance this controller belongs to.
    ///   - environment: The source of internal dependencies
    ///
    init(client: _ChatClient<ExtraData>, environment: Environment = .init()) {
        self.client = client
        self.environment = environment
        startObserving()
        _ = connectionEventObserver
    }
    
    private func startObserving() {
        do {
            try currentUserObserver.startObserving()
        } catch {
            log.error("""
            Observing current user failed: \(error).\n
            Accessing `currentUser` will always return `nil`, `unreadCount` with `.noUnread`
            """)
        }
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

public extension _CurrentChatUserController {
    /// Connects the chat client the controller represents to the chat servers.
    ///
    /// When the connection is established, `ChatClient` starts receiving chat updates, and `currentUser` variable is available.
    ///
    /// - Parameter completion: Called when the connection is established. If the connection fails, the completion is
    /// called with an error.
    ///
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
    
    /// Disconnects the chat client the controller represents from the chat servers. No further updates from the servers
    /// are received.
    func disconnect() {
        // Disconnect the web socket
        client.webSocketClient.disconnect(source: .userInitiated)
        
        // Reset `connectionId`. This would happen asynchronously by the callback from WebSocketClient anyway, but it's
        // safer to do it here synchronously to immediately stop all API calls.
        client.connectionId = nil
        
        // Remove all waiters for connectionId
        client.connectionIdWaiters.removeAll()
    }
    
    /// Sets a new anonymous user as the current user.
    ///
    /// Anonymous users have limited set of permissions. A typical use case for anonymous users are livestream channels,
    /// where they are allowed to read the conversation.
    ///
    /// - Parameter completion: Called when the new anonymous user is set. If setting up the new user fails, the completion
    /// is called with an error.
    ///
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
    
    /// Sets a new **guest** user as the current user.
    ///
    /// Guest sessions do not require any server-side authentication. Guest users have a limited set of permissions.
    ///
    /// - Parameters:
    ///   - userId: The new guest-user identifier.
    ///   - extraData: The extra data of the new guest-user.
    ///   - completion: The completion. Will be called when the new guest user is set.
    ///                 If setting up the new user fails the completion will be called with an error.
    func setGuestUser(userId: UserId, extraData: ExtraData.User = .defaultValue, completion: ((Error?) -> Void)? = nil) {
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
    
    /// Sets a new current user of the `ChatClient`.
    ///
    /// - Parameters:
    ///   - userId: The id of the new current user.
    ///
    ///   - userExtraData: You can optionally provide additional data to be set for the user. This is an equivalent of
    ///   setting the current user detail data manually using `CurrentUserController`.
    ///
    ///   - token: You can provide a token which is used for user authentication. If the `token` is not explicitly provided,
    ///   the client uses `ChatClientConfig.tokenProvider` to obtain a token. If you haven't specified the token provider,
    ///   providing a token explicitly is required. In case both the `token` and `ChatClientConfig.tokenProvider` is specified,
    ///   the `token` value is used.
    ///
    ///   - completion: Called when the new user is successfully set.
    ///
    func setUser(
        userId: UserId,
        userExtraData: ExtraData.User? = nil,
        token: Token? = nil,
        completion: ((Error?) -> Void)? = nil
    ) {
        guard token != nil || client.config.tokenProvider != nil else {
            log.assertationFailure(
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

extension _CurrentChatUserController {
    struct Environment {
        var currentUserObserverBuilder: (
            _ context: NSManagedObjectContext,
            _ fetchRequest: NSFetchRequest<CurrentUserDTO>,
            _ itemCreator: @escaping (CurrentUserDTO) -> _CurrentChatUser<ExtraData.User>,
            _ fetchedResultsControllerType: NSFetchedResultsController<CurrentUserDTO>.Type
        ) -> EntityDatabaseObserver<_CurrentChatUser<ExtraData.User>, CurrentUserDTO> = EntityDatabaseObserver.init
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

private extension _CurrentChatUserController {
    func createUserObserver() -> EntityDatabaseObserver<_CurrentChatUser<ExtraData.User>, CurrentUserDTO> {
        environment.currentUserObserverBuilder(
            client.databaseContainer.viewContext,
            CurrentUserDTO.defaultFetchRequest,
            { $0.asModel() }, // swiftlint:disable:this opening_brace
            NSFetchedResultsController<CurrentUserDTO>.self
        )
    }
}

// MARK: - Delegates

/// `CurrentChatUserController` uses this protocol to communicate changes to its delegate.
///
/// This protocol can be used only when no custom extra data are specified.
/// If you're using custom extra data types, please use `_CurrentChatUserControllerDelegate` instead.
///
public protocol CurrentChatUserControllerDelegate: AnyObject {
    /// The controller observed a change in the `UnreadCount`.
    func currentUserController(_ controller: CurrentChatUserController, didChangeCurrentUserUnreadCount: UnreadCount)
    
    /// The controller observed a change in the `CurrentChatUser` entity.
    func currentUserController(_ controller: CurrentChatUserController, didChangeCurrentUser: EntityChange<CurrentChatUser>)
    
    /// The controller observed a change in connection status.
    func currentUserController(_ controller: CurrentChatUserController, didUpdateConnectionStatus status: ConnectionStatus)
}

public extension CurrentChatUserControllerDelegate {
    func currentUserController(_ controller: CurrentChatUserController, didChangeCurrentUserUnreadCount: UnreadCount) {}
    
    func currentUserController(_ controller: CurrentChatUserController, didChangeCurrentUser: EntityChange<CurrentChatUser>) {}
    
    func currentUserController(_ controller: CurrentChatUserController, didUpdateConnectionStatus status: ConnectionStatus) {}
}

/// `CurrentChatUserController` uses this protocol to communicate changes to its delegate.
///
/// If you're **not** using custom extra data types, you can use a convenience version of this protocol
/// named `CurrentChatUserControllerDelegate`, which hides the generic types, and make the usage easier.
///
public protocol _CurrentChatUserControllerDelegate: AnyObject {
    associatedtype ExtraData: ExtraDataTypes
    
    /// The controller observed a change in the `UnreadCount`.
    func currentUserController(_ controller: _CurrentChatUserController<ExtraData>, didChangeCurrentUserUnreadCount: UnreadCount)
    
    /// The controller observed a change in the `CurrentUser` entity.
    func currentUserController(
        _ controller: _CurrentChatUserController<ExtraData>,
        didChangeCurrentUser: EntityChange<_CurrentChatUser<ExtraData.User>>
    )
    
    /// The controller observed a change in connection status.
    func currentUserController(
        _ controller: _CurrentChatUserController<ExtraData>,
        didUpdateConnectionStatus status: ConnectionStatus
    )
}

public extension _CurrentChatUserControllerDelegate {
    func currentUserController(
        _ controller: _CurrentChatUserController<ExtraData>,
        didChangeCurrentUserUnreadCount: UnreadCount
    ) {}
    
    func currentUserController(
        _ controller: _CurrentChatUserController<ExtraData>,
        didChangeCurrentUser: EntityChange<_CurrentChatUser<ExtraData.User>>
    ) {}
    
    func currentUserController(
        _ controller: _CurrentChatUserController<ExtraData>,
        didUpdateConnectionStatus status: ConnectionStatus
    ) {}
}

final class AnyCurrentUserControllerDelegate<ExtraData: ExtraDataTypes>: _CurrentChatUserControllerDelegate {
    weak var wrappedDelegate: AnyObject?
    
    private var _controllerDidChangeCurrentUserUnreadCount: (
        _CurrentChatUserController<ExtraData>,
        UnreadCount
    ) -> Void
    
    private var _controllerDidChangeCurrentUser: (
        _CurrentChatUserController<ExtraData>,
        EntityChange<_CurrentChatUser<ExtraData.User>>
    ) -> Void
    
    private var _controllerDidChangeConnectionStatus: (
        _CurrentChatUserController<ExtraData>,
        ConnectionStatus
    ) -> Void
    
    init(
        wrappedDelegate: AnyObject?,
        controllerDidChangeCurrentUserUnreadCount: @escaping (
            _CurrentChatUserController<ExtraData>,
            UnreadCount
        ) -> Void,
        controllerDidChangeCurrentUser: @escaping (
            _CurrentChatUserController<ExtraData>,
            EntityChange<_CurrentChatUser<ExtraData.User>>
        ) -> Void,
        controllerDidChangeConnectionStatus: @escaping (
            _CurrentChatUserController<ExtraData>,
            ConnectionStatus
        ) -> Void
    ) {
        self.wrappedDelegate = wrappedDelegate
        _controllerDidChangeCurrentUserUnreadCount = controllerDidChangeCurrentUserUnreadCount
        _controllerDidChangeCurrentUser = controllerDidChangeCurrentUser
        _controllerDidChangeConnectionStatus = controllerDidChangeConnectionStatus
    }
    
    func currentUserController(
        _ controller: _CurrentChatUserController<ExtraData>,
        didChangeCurrentUserUnreadCount unreadCount: UnreadCount
    ) {
        _controllerDidChangeCurrentUserUnreadCount(controller, unreadCount)
    }
    
    func currentUserController(
        _ controller: _CurrentChatUserController<ExtraData>,
        didChangeCurrentUser user: EntityChange<_CurrentChatUser<ExtraData.User>>
    ) {
        _controllerDidChangeCurrentUser(controller, user)
    }
    
    func currentUserController(
        _ controller: _CurrentChatUserController<ExtraData>,
        didUpdateConnectionStatus status: ConnectionStatus
    ) {
        _controllerDidChangeConnectionStatus(controller, status)
    }
}

extension AnyCurrentUserControllerDelegate {
    convenience init<Delegate: _CurrentChatUserControllerDelegate>(_ delegate: Delegate) where Delegate.ExtraData == ExtraData {
        self.init(
            wrappedDelegate: delegate,
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

extension AnyCurrentUserControllerDelegate where ExtraData == DefaultExtraData {
    convenience init(_ delegate: CurrentChatUserControllerDelegate?) {
        self.init(
            wrappedDelegate: delegate,
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
 
public extension _CurrentChatUserController {
    /// Sets the provided object as a delegate of this controller.
    ///
    /// - Note: If you don't use custom extra data types, you can set the delegate directly using `controller.delegate = self`.
    /// Due to the current limits of Swift and the way it handles protocols with associated types, it's required to use this
    /// method to set the delegate, if you're using custom extra data types.
    ///
    /// - Parameter delegate: The object used as a delegate. It's referenced weakly, so you need to keep the object
    /// alive if you want keep receiving updates.
    func setDelegate<Delegate: _CurrentChatUserControllerDelegate>(_ delegate: Delegate?) where Delegate.ExtraData == ExtraData {
        multicastDelegate.mainDelegate = delegate.flatMap(AnyCurrentUserControllerDelegate.init)
    }
}

public extension CurrentChatUserController {
    /// Set the delegate of `CurrentUserController` to observe the changes in the system.
    ///
    /// - Note: The delegate can be set directly only if you're **not** using custom extra data types. Due to the current
    /// limits of Swift and the way it handles protocols with associated types, it's required to use `setDelegate` method
    /// instead to set the delegate, if you're using custom extra data types.
    var delegate: CurrentChatUserControllerDelegate? {
        set { multicastDelegate.mainDelegate = AnyCurrentUserControllerDelegate(newValue) }
        get { multicastDelegate.mainDelegate?.wrappedDelegate as? CurrentChatUserControllerDelegate }
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
