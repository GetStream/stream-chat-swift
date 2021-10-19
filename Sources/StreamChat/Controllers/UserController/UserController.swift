//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

public extension ChatClient {
    /// Creates a new `_ChatUserController` for the user with the provided `userId`.
    ///
    /// - Parameter userId: The user identifier.
    /// - Returns: A new instance of `_ChatUserController`.
    func userController(userId: UserId) -> ChatUserController {
        .init(userId: userId, client: self)
    }
}

/// `_ChatUserController` is a controller class which allows mutating and observing changes of a specific chat user.
///
/// `_ChatUserController` objects are lightweight, and they can be used for both, continuous data change observations,
/// and for quick user actions (like mute/unmute).
public class ChatUserController: DataController, DelegateCallable, DataStoreProvider {
    /// The identifier of tge user this controller observes.
    public let userId: UserId
    
    /// The `ChatClient` instance this controller belongs to.
    public let client: ChatClient
    
    /// The user the controller represents.
    ///
    /// To observe changes of the user, set your class as a delegate of this controller or use the provided
    /// `Combine` publishers.
    public var user: ChatUser? {
        startObservingIfNeeded()
        return userObserver.item
    }
    
    /// A type-erased delegate.
    var multicastDelegate: MulticastDelegate<ChatUserControllerDelegate> = .init() {
        didSet {
            multicastDelegate.delegates.forEach {
                stateMulticastDelegate.add($0)
            }
            startObservingIfNeeded()
        }
    }
    
    /// The worker used to fetch the remote data and communicate with servers.
    private lazy var userUpdater = createUserUpdater()
    
    /// The observer used to track the user changes in the database.
    private lazy var userObserver = createUserObserver()
        .onChange { [weak self] change in
            self?.delegateCallback { [weak self] in
                guard let self = self else {
                    log.warning("Callback called while self is nil")
                    return
                }
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
        client: ChatClient,
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
    /// - Parameter delegate: The object used as a delegate. It's referenced weakly, so you need to keep the object
    /// alive if you want keep receiving updates.
    ///
    public func setDelegate<Delegate: ChatUserControllerDelegate>(_ delegate: Delegate) {
        multicastDelegate.add(delegate)
    }
    
    // MARK: - Private
    
    private func createUserUpdater() -> UserUpdater {
        environment.userUpdaterBuilder(
            client.databaseContainer,
            client.apiClient
        )
    }
    
    private func createUserObserver() -> EntityDatabaseObserver<ChatUser, UserDTO> {
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

public extension ChatUserController {
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

extension ChatUserController {
    struct Environment {
        var userUpdaterBuilder: (
            _ database: DatabaseContainer,
            _ apiClient: APIClient
        ) -> UserUpdater = UserUpdater.init
        
        var userObserverBuilder: (
            _ context: NSManagedObjectContext,
            _ fetchRequest: NSFetchRequest<UserDTO>,
            _ itemCreator: @escaping (UserDTO) -> ChatUser,
            _ fetchedResultsControllerType: NSFetchedResultsController<UserDTO>.Type
        ) -> EntityDatabaseObserver<ChatUser, UserDTO> = EntityDatabaseObserver.init
    }
}

public extension ChatUserController {
    /// Set the delegate of `ChatUserController` to observe the changes in the system.
    var delegate: ChatUserControllerDelegate? {
        get { multicastDelegate.delegates.first }
        set { newValue.map { multicastDelegate.add($0) } }
    }
}

// MARK: - Delegates

/// `ChatUserControllerDelegate` uses this protocol to communicate changes to its delegate.
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
