//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

extension ChatClient {
    /// Creates a new `_ChatUserSearchController` with the provided user query.
    ///
    /// - Parameter query: The query specify the filter and sorting of the users the controller should fetch.
    ///
    /// - Returns: A new instance of `_ChatUserSearchController`.
    ///
    public func userSearchController() -> ChatUserSearchController {
        .init(client: self)
    }
}

/// `ChatUserSearchController` is a controller class which allows observing a list of chat users based on the provided query.
public class ChatUserSearchController: DataController, DelegateCallable, DataStoreProvider {
    /// The `ChatClient` instance this controller belongs to.
    public let client: ChatClient
    
    /// Filter hash this controller observes.
    let explicitFilterHash = UUID().uuidString
    
    lazy var query: UserListQuery = {
        // Filter is just a mock, explicit hash will override it
        var query = UserListQuery(filter: .exists(.id), sort: [.init(key: .name, isAscending: true)])
        // Setting `shouldBeObserved` to false prevents NewUserQueryUpdater to pick this query up
        query.shouldBeUpdatedInBackground = false
        // The initial DB fetch will return 0 users and this is expected
        // In the future we'll implement DB search too
        query.filter?.explicitHash = explicitFilterHash
        
        return query
    }()
    
    /// Copy of last search query made, used for getting next page.
    var lastQuery: UserListQuery?
    
    /// The users matching the query of this controller.
    ///
    /// To observe changes of the users, set your class as a delegate of this controller or use the provided
    /// `Combine` publishers.
    ///
    public var users: LazyCachedMapCollection<ChatUser> {
        startUserListObserverIfNeeded()
        return userListObserver.items
    }
    
    lazy var userQueryUpdater = self.environment
        .userQueryUpdaterBuilder(
            client.databaseContainer,
            client.apiClient
        )
    
    /// Used for observing the database for changes.
    lazy var userListObserver: ListDatabaseObserver<ChatUser, UserDTO> = {
        let request = UserDTO.userListFetchRequest(query: query)
        
        let observer = self.environment.createUserListDatabaseObserver(
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
    
    /// A type-erased delegate.
    var multicastDelegate: MulticastDelegate<ChatUserSearchControllerDelegate> = .init() {
        didSet {
            stateMulticastDelegate.set(mainDelegate: multicastDelegate.mainDelegate)
            stateMulticastDelegate.set(additionalDelegates: multicastDelegate.additionalDelegates)
            
            // After setting delegate local changes will be fetched and observed.
            startUserListObserverIfNeeded()
        }
    }
    
    private let environment: Environment
    
    init(client: ChatClient, environment: Environment = .init()) {
        self.client = client
        self.environment = environment
    }
    
    deinit {
        let query = self.query
        client.databaseContainer.write { session in
            session.deleteQuery(query)
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
        startUserListObserverIfNeeded()
        
        var query = UserListQuery(sort: [.init(key: .name, isAscending: true)])
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
    
    /// Searches users for the given query.
    ///
    /// When this function is called, `users` property of this controller will refresh with new users matching the term.
    /// The delegate function `didChangeUsers` will also be called.
    ///
    /// - Note: Currently, no local data will be searched, only remote data will be queried.
    ///
    /// - Parameters:
    ///   - query: Search query.
    ///   - completion: Called when the controller has finished fetching remote data.
    ///   If the data fetching fails, the error variable contains more details about the problem.
    public func search(query: UserListQuery, completion: ((_ error: Error?) -> Void)? = nil) {
        startUserListObserverIfNeeded()
        
        var query = query
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

extension ChatUserSearchController {
    struct Environment {
        var userQueryUpdaterBuilder: (
            _ database: DatabaseContainer,
            _ apiClient: APIClient
        ) -> UserListUpdater = UserListUpdater.init
        
        var createUserListDatabaseObserver: (
            _ context: NSManagedObjectContext,
            _ fetchRequest: NSFetchRequest<UserDTO>,
            _ itemCreator: @escaping (UserDTO) -> ChatUser
        )
            -> ListDatabaseObserver<ChatUser, UserDTO> = {
                ListDatabaseObserver(context: $0, fetchRequest: $1, itemCreator: $2)
            }
    }
}

extension ChatUserSearchController {
    /// Set the delegate of `UserListController` to observe the changes in the system.
    public weak var delegate: ChatUserSearchControllerDelegate? {
        get { multicastDelegate.mainDelegate }
        set { multicastDelegate.set(mainDelegate: newValue) }
    }
}

/// `ChatUserSearchController` uses this protocol to communicate changes to its delegate.
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
