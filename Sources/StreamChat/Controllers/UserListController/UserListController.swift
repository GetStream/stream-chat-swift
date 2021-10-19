//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

extension ChatClient {
    /// Creates a new `_ChatUserListController` with the provided user query.
    ///
    /// - Parameter query: The query specify the filter and sorting of the users the controller should fetch.
    ///
    /// - Returns: A new instance of `_ChatUserListController`.
    ///
    public func userListController(query: UserListQuery = .init()) -> ChatUserListController {
        .init(query: query, client: self)
    }
}

/// `_ChatUserListController` is a controller class which allows observing a list of chat users based on the provided query.
public class ChatUserListController: DataController, DelegateCallable, DataStoreProvider {
    /// The query specifying and filtering the list of users.
    public let query: UserListQuery
    
    /// The `ChatClient` instance this controller belongs to.
    public let client: ChatClient
    
    /// The users matching the query of this controller.
    ///
    /// To observe changes of the users, set your class as a delegate of this controller or use the provided
    /// `Combine` publishers.
    ///
    public var users: LazyCachedMapCollection<ChatUser> {
        startUserListObserverIfNeeded()
        return userListObserver.items
    }
    
    /// The worker used to fetch the remote data and communicate with servers.
    private lazy var worker: UserListUpdater = self.environment
        .userQueryUpdaterBuilder(
            client.databaseContainer,
            client.apiClient
        )

    /// A type-erased delegate.
    var multicastDelegate: MulticastDelegate<ChatUserListControllerDelegate> = .init() {
        didSet {
            multicastDelegate.delegates.forEach {
                stateMulticastDelegate.add($0)
            }
            
            // After setting delegate local changes will be fetched and observed.
            startUserListObserverIfNeeded()
        }
    }
    
    /// Used for observing the database for changes.
    private(set) lazy var userListObserver: ListDatabaseObserver<ChatUser, UserDTO> = {
        let request = UserDTO.userListFetchRequest(query: self.query)
        
        let observer = self.environment.createUserListDabaseObserver(
            client.databaseContainer.viewContext,
            request,
            { $0.asModel() }
        )
        
        observer.onChange = { [weak self] changes in
            self?.delegateCallback { [weak self] in
                guard let self = self else {
                    log.warning("Callback called while self is nil")
                    return
                }

                $0.controller(self, didChangeUsers: changes)
            }
        }
        
        return observer
    }()
    
    /// An internal backing object for all publicly available Combine publishers. We use it to simplify the way we expose
    /// publishers. Instead of creating custom `Publisher` types, we use `CurrentValueSubject` and `PassthroughSubject` internally,
    /// and expose the published values by mapping them to a read-only `AnyPublisher` type.
    @available(iOS 13, *)
    lazy var basePublishers: BasePublishers = .init(controller: self)
    
    private let environment: Environment
    
    /// Creates a new `UserListController`.
    ///
    /// - Parameters:
    ///   - query: The query used for filtering the users.
    ///   - client: The `Client` instance this controller belongs to.
    init(query: UserListQuery, client: ChatClient, environment: Environment = .init()) {
        self.client = client
        self.query = query
        self.environment = environment
    }
    
    override public func synchronize(_ completion: ((_ error: Error?) -> Void)? = nil) {
        startUserListObserverIfNeeded()
        
        worker.update(userListQuery: query) { error in
            self.state = error == nil ? .remoteDataFetched : .remoteDataFetchFailed(ClientError(with: error))
            self.callback { completion?(error) }
        }
    }
    
    /// If the `state` of the controller is `initialized`, this method calls `startObserving` on the
    /// `userListObserver` to fetch the local data and start observing the changes. It also changes
    /// `state` based on the result.
    ///
    /// It's safe to call this method repeatedly.
    ///
    private func startUserListObserverIfNeeded() {
        guard state == .initialized else { return }
        do {
            try userListObserver.startObserving()
            state = .localDataFetched
        } catch {
            state = .localDataFetchFailed(ClientError(with: error))
            log.error("Failed to perform fetch request with error: \(error). This is an internal error.")
        }
    }
    
    /// Sets the provided object as a delegate of this controller.
    ///
    /// - Parameter delegate: The object used as a delegate. It's referenced weakly, so you need to keep the object
    /// alive if you want keep receiving updates.
    ///
    public func setDelegate<Delegate: ChatUserListControllerDelegate>(_ delegate: Delegate) {
        multicastDelegate.add(delegate)
    }
}

// MARK: - Actions

public extension ChatUserListController {
    /// Loads next users from backend.
    ///
    /// - Parameters:
    ///   - limit: Limit for page size.
    ///   - completion: The completion. Will be called on a **callbackQueue** when the network request is finished.
    ///                 If request fails, the completion will be called with an error.
    ///
    func loadNextUsers(
        limit: Int = 25,
        completion: ((Error?) -> Void)? = nil
    ) {
        var updatedQuery = query
        updatedQuery.pagination = Pagination(pageSize: limit, offset: users.count)
        worker.update(userListQuery: updatedQuery) { error in
            self.callback { completion?(error) }
        }
    }
}

extension ChatUserListController {
    struct Environment {
        var userQueryUpdaterBuilder: (
            _ database: DatabaseContainer,
            _ apiClient: APIClient
        ) -> UserListUpdater = UserListUpdater.init

        var createUserListDabaseObserver: (
            _ context: NSManagedObjectContext,
            _ fetchRequest: NSFetchRequest<UserDTO>,
            _ itemCreator: @escaping (UserDTO) -> ChatUser
        )
            -> ListDatabaseObserver<ChatUser, UserDTO> = {
                ListDatabaseObserver(context: $0, fetchRequest: $1, itemCreator: $2)
            }
    }
}

extension ChatUserListController {
    /// Set the delegate of `UserListController` to observe the changes in the system.
    public weak var delegate: ChatUserListControllerDelegate? {
        get { multicastDelegate.delegates.first }
        set { newValue.map { multicastDelegate.add($0) } }
    }
}

/// `ChatUserListController` uses this protocol to communicate changes to its delegate.
public protocol ChatUserListControllerDelegate: DataControllerStateDelegate {
    /// The controller changed the list of observed users.
    ///
    /// - Parameters:
    ///   - controller: The controller emitting the change callback.
    ///   - changes: The change to the list of users.
    ///
    func controller(
        _ controller: ChatUserListController,
        didChangeUsers changes: [ListChange<ChatUser>]
    )
}

public extension ChatUserListControllerDelegate {
    func controller(
        _ controller: ChatUserListController,
        didChangeUsers changes: [ListChange<ChatUser>]
    ) {}
}

// MARK: - Delegate type eraser

class AnyUserListControllerDelegate: ChatUserListControllerDelegate {
    private var _controllerDidChangeUsers: (ChatUserListController, [ListChange<ChatUser>])
        -> Void
    private var _controllerDidChangeState: (DataController, DataController.State) -> Void
    
    weak var wrappedDelegate: AnyObject?
    
    init(
        wrappedDelegate: AnyObject?,
        controllerDidChangeState: @escaping (DataController, DataController.State) -> Void,
        controllerDidChangeUsers: @escaping (ChatUserListController, [ListChange<ChatUser>])
            -> Void
    ) {
        self.wrappedDelegate = wrappedDelegate
        _controllerDidChangeState = controllerDidChangeState
        _controllerDidChangeUsers = controllerDidChangeUsers
    }

    func controller(_ controller: DataController, didChangeState state: DataController.State) {
        _controllerDidChangeState(controller, state)
    }

    func controller(
        _ controller: ChatUserListController,
        didChangeUsers changes: [ListChange<ChatUser>]
    ) {
        _controllerDidChangeUsers(controller, changes)
    }
}

extension AnyUserListControllerDelegate {
    convenience init<Delegate: ChatUserListControllerDelegate>(_ delegate: Delegate) {
        self.init(
            wrappedDelegate: delegate,
            controllerDidChangeState: { [weak delegate] in delegate?.controller($0, didChangeState: $1) },
            controllerDidChangeUsers: { [weak delegate] in delegate?.controller($0, didChangeUsers: $1) }
        )
    }
}

extension AnyUserListControllerDelegate {
    convenience init(_ delegate: ChatUserListControllerDelegate?) {
        self.init(
            wrappedDelegate: delegate,
            controllerDidChangeState: { [weak delegate] in delegate?.controller($0, didChangeState: $1) },
            controllerDidChangeUsers: { [weak delegate] in delegate?.controller($0, didChangeUsers: $1) }
        )
    }
}
