//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

extension ChatClient {
    /// Creates a new `ChatUserSearchController` with the provided user query.
    ///
    /// - Parameter query: The query specify the filter and sorting of the users the controller should fetch.
    ///
    /// - Returns: A new instance of `ChatUserSearchController`.
    ///
    public func userSearchController() -> ChatUserSearchController {
        .init(client: self)
    }
}

/// `ChatUserSearchController` is a controller class which allows observing a list of chat users based on the provided query.
public class ChatUserSearchController: DataController, DelegateCallable, DataStoreProvider {
    /// The `ChatClient` instance this controller belongs to.
    public let client: ChatClient
    
    /// Copy of last search query made, used for getting next page.
    private(set) var query: UserListQuery?
    
    /// The users matching the last query of this controller.
    private var _users: [ChatUser] = []
    public var userArray: [ChatUser] {
        setLocalDataFetchedStateIfNeeded()
        return _users
    }

    @available(*, deprecated, message: "Please, switch to `userArray: [ChatUser]`")
    public var users: LazyCachedMapCollection<ChatUser> {
        .init(source: userArray, map: { $0 })
    }

    lazy var userQueryUpdater = self.environment
        .userQueryUpdaterBuilder(
            client.databaseContainer,
            client.apiClient
        )
    
    /// A type-erased delegate.
    var multicastDelegate: MulticastDelegate<ChatUserSearchControllerDelegate> = .init() {
        didSet {
            stateMulticastDelegate.set(mainDelegate: multicastDelegate.mainDelegate)
            stateMulticastDelegate.set(additionalDelegates: multicastDelegate.additionalDelegates)
            
            setLocalDataFetchedStateIfNeeded()
        }
    }
    
    private let environment: Environment
    
    init(client: ChatClient, environment: Environment = .init()) {
        self.client = client
        self.environment = environment
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
        fetch(.search(term: term), completion: completion)
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
        fetch(query, completion: completion)
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
        guard let lastQuery = query else {
            completion?(ClientError("You should make a search before calling for next page."))
            return
        }
        
        var updatedQuery = lastQuery
        updatedQuery.pagination = Pagination(pageSize: limit, offset: userArray.count)
        
        fetch(updatedQuery, completion: completion)
    }
}

private extension ChatUserSearchController {
    /// Fetches the given query from the API, saves the loaded page to the database, updates the list of users and notifies the delegate.
    ///
    /// - Parameters:
    ///   - query: The query to fetch.
    ///   - completion: The completion that is triggered when the query is processed.
    func fetch(_ query: UserListQuery, completion: ((Error?) -> Void)? = nil) {
        // TODO: Remove with the next major
        //
        // This is needed to make the delegate fire about state changes at the same time with the same
        // values as it was when query was persisted.
        setLocalDataFetchedStateIfNeeded()
        
        userQueryUpdater.fetch(userListQuery: query) { [weak self] result in
            switch result {
            case let .success(page):
                self?.save(page: page) { loadedUsers in
                    let listChanges = self?.prepareListChanges(
                        loadedPage: loadedUsers,
                        updatePolicy: query.pagination?.offset == 0 ? .replace : .merge
                    )
                    
                    self?.query = query
                    if let listChanges = listChanges, let users = self?.userList(after: listChanges) {
                        self?._users = users
                    }
                    self?.state = .remoteDataFetched
                    
                    self?.callback {
                        self?.multicastDelegate.invoke {
                            guard let self = self, let listChanges = listChanges else { return }
                            $0.controller(self, didChangeUsers: listChanges)
                        }
                        completion?(nil)
                    }
                }
            case let .failure(error):
                self?.state = .remoteDataFetchFailed(ClientError(with: error))
                self?.callback { completion?(error) }
            }
        }
    }
    
    /// Saves the given payload to the database and returns database independent models.
    ///
    /// - Parameters:
    ///   - page: The page of users fetched from the API.
    ///   - completion: The completion that will be called with user models when database write is completed.
    func save(page: UserListPayload, completion: @escaping ([ChatUser]) -> Void) {
        var loadedUsers: [ChatUser] = []
        
        client.databaseContainer.write({ session in
            loadedUsers = page
                .users
                .compactMap { try? session.saveUser(payload: $0).asModel() }
            
        }, completion: { _ in
            completion(loadedUsers)
        })
    }
    
    /// Creates the list of changes based on current list, the new page, and the policy.
    ///
    /// - Parameters:
    ///   - loadedPage: The next page of users.
    ///   - updatePolicy: The update policy.
    /// - Returns: The list of changes that can be applied to the current list of users.
    func prepareListChanges(loadedPage: [ChatUser], updatePolicy: UpdatePolicy) -> [ListChange<ChatUser>] {
        switch updatePolicy {
        case .replace:
            let deletions = userArray.enumerated().reversed().map { (index, user) in
                ListChange.remove(user, index: .init(item: index, section: 0))
            }
            
            let insertions = loadedPage.enumerated().map { (index, user) in
                ListChange.insert(user, index: .init(item: index, section: 0))
            }
            
            return deletions + insertions
        case .merge:
            let insertions = loadedPage.enumerated().map { (index, user) in
                ListChange.insert(user, index: .init(item: index + userArray.count, section: 0))
            }
            
            return insertions
        }
    }
    
    /// Applies the given changes to the current list of users and returns the updated list.
    ///
    /// - Parameter changes: The changes to apply.
    /// - Returns: The user list after the given changes applied.
    ///
    func userList(after changes: [ListChange<ChatUser>]) -> [ChatUser] {
        var users = _users
        
        for change in changes {
            switch change {
            case let .insert(user, indexPath):
                users.insert(user, at: indexPath.item)
            case let .remove(_, indexPath):
                users.remove(at: indexPath.item)
            default:
                log.assertionFailure("Unsupported list change observed: \(change)")
            }
        }
        
        return users
    }
    
    /// Sets state to `localDataFetched` if current state is `initialized`.
    func setLocalDataFetchedStateIfNeeded() {
        guard state == .initialized else { return }
            
        state = .localDataFetched
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
