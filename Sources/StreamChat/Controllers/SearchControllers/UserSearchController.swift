//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

extension _ChatClient {
    /// Creates a new `_ChatUserSearchController` with the provided user query.
    ///
    /// - Parameter query: The query specify the filter and sorting of the users the controller should fetch.
    ///
    /// - Returns: A new instance of `_ChatUserSearchController`.
    ///
    public func userSearchController() -> _ChatUserSearchController<ExtraData> {
        .init(client: self)
    }
}

/// `ChatUserSearchController` is a controller class which allows observing a list of chat users based on the provided query.
///
/// - Note: `ChatUserSearchController` is a typealias of `_ChatUserSearchController` with the default extra data types.
/// If you want to use your custom extra data types, you should create your own `ChatUserSearchController`
/// typealias for `_ChatUserSearchController`.
///
/// Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheet#working-with-extra-data).
///
public typealias ChatUserSearchController = _ChatUserSearchController<NoExtraData>

/// `_ChatUserSearchController` is a controller class which allows observing a list of chat users based on the provided query.
///
/// - Note: `_ChatUserSearchController` type is not meant to be used directly.
/// If you don't use custom extra data types, use `ChatUserSearchController` typealias instead.
/// When using custom extra data types, you should create your own `ChatUserSearchController` typealias
/// for `_ChatUserSearchController`.
///
/// Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheet#working-with-extra-data).
///
public class _ChatUserSearchController<ExtraData: ExtraDataTypes>: DataController, DelegateCallable, DataStoreProvider {
    /// The `ChatClient` instance this controller belongs to.
    public let client: _ChatClient<ExtraData>
    
    /// Filter hash this controller observes.
    let explicitFilterHash = UUID().uuidString
    
    lazy var query: _UserListQuery<ExtraData.User> = {
        // Filter is just a mock, explicit hash will override it
        var query = _UserListQuery<ExtraData.User>(filter: .exists(.id), sort: [.init(key: .name, isAscending: true)])
        // Setting `shouldBeObserved` to false prevents NewUserQueryUpdater to pick this query up
        query.shouldBeUpdatedInBackground = false
        // The initial DB fetch will return 0 users and this is expected
        // In the future we'll implement DB search too
        query.filter?.explicitHash = explicitFilterHash
        
        return query
    }()
    
    /// Copy of last search query made, used for getting next page.
    var lastQuery: _UserListQuery<ExtraData.User>?
    
    /// The users matching the query of this controller.
    ///
    /// To observe changes of the users, set your class as a delegate of this controller or use the provided
    /// `Combine` publishers.
    ///
    public var users: LazyCachedMapCollection<_ChatUser<ExtraData.User>> { userListObserver.items }
    
    lazy var userQueryUpdater = self.environment
        .userQueryUpdaterBuilder(
            client.databaseContainer,
            client.apiClient
        )
    
    /// Used for observing the database for changes.
    lazy var userListObserver: ListDatabaseObserver<_ChatUser<ExtraData.User>, UserDTO> = {
        let request = UserDTO.userListFetchRequest(query: query)
        
        let observer = self.environment.createUserListDatabaseObserver(
            client.databaseContainer.viewContext,
            request,
            { $0.asModel() }
        )
        
        observer.onChange = { [unowned self] changes in
            self.delegateCallback {
                $0.controller(self, didChangeUsers: changes)
            }
        }
        
        do {
            try observer.startObserving()
            state = .localDataFetched
        } catch {
            state = .localDataFetchFailed(ClientError(with: error))
            log.error("Failed to perform fetch request with error: \(error). This is an internal error.")
        }
        
        return observer
    }()
    
    /// A type-erased delegate.
    var multicastDelegate: MulticastDelegate<AnyUserSearchControllerDelegate<ExtraData>> = .init() {
        didSet {
            stateMulticastDelegate.mainDelegate = multicastDelegate.mainDelegate
            stateMulticastDelegate.additionalDelegates = multicastDelegate.additionalDelegates
            
            // After setting delegate local changes will be fetched and observed.
            startUserListObserver()
        }
    }
    
    private let environment: Environment
    
    init(client: _ChatClient<ExtraData>, environment: Environment = .init()) {
        self.client = client
        self.environment = environment
    }
    
    deinit {
        let query = self.query
        client.databaseContainer.write { session in
            session.deleteQuery(query)
        }
    }
    
    /// Initializing of `userListObserver` will start local data observing.
    /// In most cases it will be done by accessing `users` but it's possible that only
    /// changes will be observed.
    private func startUserListObserver() {
        _ = userListObserver
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
    public func setDelegate<Delegate: _ChatUserSearchControllerDelegate>(_ delegate: Delegate)
        where Delegate.ExtraData == ExtraData {
        multicastDelegate.mainDelegate = AnyUserSearchControllerDelegate(delegate)
    }
    
    /// Searches users for the given term.
    ///
    /// When this function is called, `users` property of this controller will refresh with new users matching the term.
    /// The delegate function `didChangeUsers` will also be called.
    ///
    /// - Note: Currently, no local data will be searched, only remote data will be queried.
    ///
    /// - Parameters:
    ///   - term: Search term. If empty string or `nil`, all users are fetched.
    ///   - completion: Called when the controller has finished fetching remote data.
    ///   If the data fetching fails, the error variable contains more details about the problem.
    public func search(term: String?, completion: ((_ error: Error?) -> Void)? = nil) {
        var query = _UserListQuery<ExtraData.User>(sort: [.init(key: .name, isAscending: true)])
        if let term = term, !term.isEmpty {
            query.filter = .or([
                .autocomplete(.name, text: term),
                .autocomplete(.id, text: term)
            ])
        } else {
            query.filter = .exists(.id) // Pseudo-filter to fetch all users
        }
        // Backend suggest not sorting by name
        // so we only sort client-side
        query.filter?.explicitHash = explicitFilterHash
        query.shouldBeUpdatedInBackground = false
        
        lastQuery = query
        
        userQueryUpdater.update(userListQuery: query, policy: .replace) { error in
            self.state = error == nil ? .remoteDataFetched : .remoteDataFetchFailed(ClientError(with: error))
            self.callback { completion?(error) }
        }
    }
    
    /// Loads next users from backend.
    ///
    /// - Parameters:
    ///   - limit: Limit for page size.
    ///   - completion: The completion. Will be called on a **callbackQueue** when the network request is finished.
    ///                 If request fails, the completion will be called with an error.
    ///
    public func loadNextUsers(
        limit: Int = 25,
        completion: ((Error?) -> Void)? = nil
    ) {
        guard let lastQuery = lastQuery else {
            completion?(ClientError("You should make a search before calling for next page."))
            return
        }
        
        var updatedQuery = lastQuery
        updatedQuery.pagination = Pagination(pageSize: limit, offset: users.count)
        userQueryUpdater.update(userListQuery: updatedQuery) { error in
            self.callback { completion?(error) }
        }
    }
}

extension _ChatUserSearchController {
    struct Environment {
        var userQueryUpdaterBuilder: (
            _ database: DatabaseContainer,
            _ apiClient: APIClient
        ) -> UserListUpdater<ExtraData.User> = UserListUpdater.init
        
        var createUserListDatabaseObserver: (
            _ context: NSManagedObjectContext,
            _ fetchRequest: NSFetchRequest<UserDTO>,
            _ itemCreator: @escaping (UserDTO) -> _ChatUser<ExtraData.User>
        )
            -> ListDatabaseObserver<_ChatUser<ExtraData.User>, UserDTO> = {
                ListDatabaseObserver(context: $0, fetchRequest: $1, itemCreator: $2)
            }
    }
}

extension _ChatUserSearchController where ExtraData == NoExtraData {
    /// Set the delegate of `UserListController` to observe the changes in the system.
    ///
    /// - Note: The delegate can be set directly only if you're **not** using custom extra data types. Due to the current
    /// limits of Swift and the way it handles protocols with associated types, it's required to use `setDelegate` method
    /// instead to set the delegate, if you're using custom extra data types.
    public weak var delegate: ChatUserSearchControllerDelegate? {
        get { multicastDelegate.mainDelegate?.wrappedDelegate as? ChatUserSearchControllerDelegate }
        set { multicastDelegate.mainDelegate = AnyUserSearchControllerDelegate(newValue) }
    }
}

/// `ChatUserSearchController` uses this protocol to communicate changes to its delegate.
///
/// If you're **not** using custom extra data types, you can use a convenience version of this protocol
/// named `ChatUserSearchControllerDelegate`, which hides the generic types, and make the usage easier.
///
public protocol _ChatUserSearchControllerDelegate: DataControllerStateDelegate {
    associatedtype ExtraData: ExtraDataTypes
    
    /// The controller changed the list of observed users.
    ///
    /// - Parameters:
    ///   - controller: The controller emitting the change callback.
    ///   - changes: The change to the list of users.
    ///
    func controller(
        _ controller: _ChatUserSearchController<ExtraData>,
        didChangeUsers changes: [ListChange<_ChatUser<ExtraData.User>>]
    )
}

public extension _ChatUserSearchControllerDelegate {
    func controller(
        _ controller: _ChatUserSearchController<ExtraData>,
        didChangeUsers changes: [ListChange<_ChatUser<ExtraData.User>>]
    ) {}
}

/// `ChatUserSearchController` uses this protocol to communicate changes to its delegate.
///
/// This protocol can be used only when no custom extra data are specified. If you're using custom extra data types,
/// please use `_ChatUserSearchControllerDelegate` instead.
///
public protocol ChatUserSearchControllerDelegate: DataControllerStateDelegate {
    /// The controller changed the list of observed users.
    ///
    /// - Parameters:
    ///   - controller: The controller emitting the change callback.
    ///   - changes: The change to the list of users.
    ///
    func controller(
        _ controller: ChatUserSearchController,
        didChangeUsers changes: [ListChange<ChatUser>]
    )
}

public extension ChatUserSearchControllerDelegate {
    func controller(
        _ controller: ChatUserSearchController,
        didChangeUsers changes: [ListChange<ChatUser>]
    ) {}
}

// MARK: - Delegate type eraser

class AnyUserSearchControllerDelegate<ExtraData: ExtraDataTypes>: _ChatUserSearchControllerDelegate {
    private var _controllerDidChangeUsers: (_ChatUserSearchController<ExtraData>, [ListChange<_ChatUser<ExtraData.User>>])
        -> Void
    private var _controllerDidChangeState: (DataController, DataController.State) -> Void
    
    weak var wrappedDelegate: AnyObject?
    
    init(
        wrappedDelegate: AnyObject?,
        controllerDidChangeState: @escaping (DataController, DataController.State) -> Void,
        controllerDidChangeUsers: @escaping (_ChatUserSearchController<ExtraData>, [ListChange<_ChatUser<ExtraData.User>>])
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
        _ controller: _ChatUserSearchController<ExtraData>,
        didChangeUsers changes: [ListChange<_ChatUser<ExtraData.User>>]
    ) {
        _controllerDidChangeUsers(controller, changes)
    }
}

extension AnyUserSearchControllerDelegate {
    convenience init<Delegate: _ChatUserSearchControllerDelegate>(_ delegate: Delegate) where Delegate.ExtraData == ExtraData {
        self.init(
            wrappedDelegate: delegate,
            controllerDidChangeState: { [weak delegate] in delegate?.controller($0, didChangeState: $1) },
            controllerDidChangeUsers: { [weak delegate] in delegate?.controller($0, didChangeUsers: $1) }
        )
    }
}

extension AnyUserSearchControllerDelegate where ExtraData == NoExtraData {
    convenience init(_ delegate: ChatUserSearchControllerDelegate?) {
        self.init(
            wrappedDelegate: delegate,
            controllerDidChangeState: { [weak delegate] in delegate?.controller($0, didChangeState: $1) },
            controllerDidChangeUsers: { [weak delegate] in delegate?.controller($0, didChangeUsers: $1) }
        )
    }
}
