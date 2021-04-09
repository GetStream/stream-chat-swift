//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

extension _ChatClient {
    /// Creates a new `_ChatUserListController` with the provided user query.
    ///
    /// - Parameter query: The query specify the filter and sorting of the users the controller should fetch.
    ///
    /// - Returns: A new instance of `_ChatUserListController`.
    ///
    public func userListController(query: _UserListQuery<ExtraData.User> = .init()) -> _ChatUserListController<ExtraData> {
        .init(query: query, client: self)
    }
}

/// `_ChatUserListController` is a controller class which allows observing a list of chat users based on the provided query.
///
/// Learn more about `_ChatUserListController` and its usage in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/StreamChat-SDK-Cheat-Sheet#user-list).
///
/// - Note: `ChatUserListController` is a typealias of `_ChatUserListController` with default extra data. If you're using
/// custom extra data, create your own typealias of `_ChatUserListController`.
///
/// Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheet#working-with-extra-data).
///
public typealias ChatUserListController = _ChatUserListController<NoExtraData>

/// `_ChatUserListController` is a controller class which allows observing a list of chat users based on the provided query.
///
/// Learn more about `_ChatUserListController` and its usage in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/StreamChat-SDK-Cheat-Sheet#user-list).
///
/// - Note: `_ChatUserListController` type is not meant to be used directly. If you're using default extra data, use
/// `ChatUserController` typealias instead. If you're using custom extra data, create your own typealias
/// of `_ChatUserListController`.
///
/// Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheet#working-with-extra-data).
///
public class _ChatUserListController<ExtraData: ExtraDataTypes>: DataController, DelegateCallable, DataStoreProvider {
    /// The query specifying and filtering the list of users.
    public let query: _UserListQuery<ExtraData.User>
    
    /// The `ChatClient` instance this controller belongs to.
    public let client: _ChatClient<ExtraData>
    
    /// The users matching the query of this controller.
    ///
    /// To observe changes of the users, set your class as a delegate of this controller or use the provided
    /// `Combine` publishers.
    ///
    public var users: LazyCachedMapCollection<_ChatUser<ExtraData.User>> {
        startUserListObserverIfNeeded()
        return userListObserver.items
    }
    
    /// The worker used to fetch the remote data and communicate with servers.
    private lazy var worker: UserListUpdater<ExtraData.User> = self.environment
        .userQueryUpdaterBuilder(
            client.databaseContainer,
            client.apiClient
        )

    /// A type-erased delegate.
    var multicastDelegate: MulticastDelegate<AnyUserListControllerDelegate<ExtraData>> = .init() {
        didSet {
            stateMulticastDelegate.mainDelegate = multicastDelegate.mainDelegate
            stateMulticastDelegate.additionalDelegates = multicastDelegate.additionalDelegates
            
            // After setting delegate local changes will be fetched and observed.
            startUserListObserverIfNeeded()
        }
    }
    
    /// Used for observing the database for changes.
    private(set) lazy var userListObserver: ListDatabaseObserver<_ChatUser<ExtraData.User>, UserDTO> = {
        let request = UserDTO.userListFetchRequest(query: self.query)
        
        let observer = self.environment.createUserListDabaseObserver(
            client.databaseContainer.viewContext,
            request,
            { $0.asModel() }
        )
        
        observer.onChange = { [unowned self] changes in
            self.delegateCallback {
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
    init(query: _UserListQuery<ExtraData.User>, client: _ChatClient<ExtraData>, environment: Environment = .init()) {
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
    /// - Note: If you don't use custom extra data types, you can set the delegate directly using `controller.delegate = self`.
    /// Due to the current limits of Swift and the way it handles protocols with associated types, it's required to use this
    /// method to set the delegate, if you're using custom extra data types.
    ///
    /// - Parameter delegate: The object used as a delegate. It's referenced weakly, so you need to keep the object
    /// alive if you want keep receiving updates.
    ///
    public func setDelegate<Delegate: _ChatUserListControllerDelegate>(_ delegate: Delegate)
        where Delegate.ExtraData == ExtraData {
        multicastDelegate.mainDelegate = AnyUserListControllerDelegate(delegate)
    }
}

// MARK: - Actions

public extension _ChatUserListController {
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

extension _ChatUserListController {
    struct Environment {
        var userQueryUpdaterBuilder: (
            _ database: DatabaseContainer,
            _ apiClient: APIClient
        ) -> UserListUpdater<ExtraData.User> = UserListUpdater.init

        var createUserListDabaseObserver: (
            _ context: NSManagedObjectContext,
            _ fetchRequest: NSFetchRequest<UserDTO>,
            _ itemCreator: @escaping (UserDTO) -> _ChatUser<ExtraData.User>
        )
            -> ListDatabaseObserver<_ChatUser<ExtraData.User>, UserDTO> = {
                ListDatabaseObserver(context: $0, fetchRequest: $1, itemCreator: $2)
            }
    }
}

extension _ChatUserListController where ExtraData == NoExtraData {
    /// Set the delegate of `UserListController` to observe the changes in the system.
    ///
    /// - Note: The delegate can be set directly only if you're **not** using custom extra data types. Due to the current
    /// limits of Swift and the way it handles protocols with associated types, it's required to use `setDelegate` method
    /// instead to set the delegate, if you're using custom extra data types.
    public weak var delegate: ChatUserListControllerDelegate? {
        get { multicastDelegate.mainDelegate?.wrappedDelegate as? ChatUserListControllerDelegate }
        set { multicastDelegate.mainDelegate = AnyUserListControllerDelegate(newValue) }
    }
}

/// `ChatUserListController` uses this protocol to communicate changes to its delegate.
///
/// This protocol can be used only when no custom extra data are specified. If you're using custom extra data types,
/// please use `_ChatUserListControllerDelegate` instead.
///
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
        _ controller: _ChatUserListController<NoExtraData>,
        didChangeUsers changes: [ListChange<ChatUser>]
    ) {}
}

/// `ChatUserListController` uses this protocol to communicate changes to its delegate.
///
/// If you're **not** using custom extra data types, you can use a convenience version of this protocol
/// named `ChatUserListControllerDelegate`, which hides the generic types, and make the usage easier.
///
public protocol _ChatUserListControllerDelegate: DataControllerStateDelegate {
    associatedtype ExtraData: ExtraDataTypes
    
    /// The controller changed the list of observed users.
    ///
    /// - Parameters:
    ///   - controller: The controller emitting the change callback.
    ///   - changes: The change to the list of users.
    ///
    func controller(
        _ controller: _ChatUserListController<ExtraData>,
        didChangeUsers changes: [ListChange<_ChatUser<ExtraData.User>>]
    )
}

public extension _ChatUserListControllerDelegate {
    func controller(
        _ controller: _ChatUserListController<ExtraData>,
        didChangeUsers changes: [ListChange<_ChatUser<ExtraData.User>>]
    ) {}
}

// MARK: - Delegate type eraser

class AnyUserListControllerDelegate<ExtraData: ExtraDataTypes>: _ChatUserListControllerDelegate {
    private var _controllerDidChangeUsers: (_ChatUserListController<ExtraData>, [ListChange<_ChatUser<ExtraData.User>>])
        -> Void
    private var _controllerDidChangeState: (DataController, DataController.State) -> Void
    
    weak var wrappedDelegate: AnyObject?
    
    init(
        wrappedDelegate: AnyObject?,
        controllerDidChangeState: @escaping (DataController, DataController.State) -> Void,
        controllerDidChangeUsers: @escaping (_ChatUserListController<ExtraData>, [ListChange<_ChatUser<ExtraData.User>>])
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
        _ controller: _ChatUserListController<ExtraData>,
        didChangeUsers changes: [ListChange<_ChatUser<ExtraData.User>>]
    ) {
        _controllerDidChangeUsers(controller, changes)
    }
}

extension AnyUserListControllerDelegate {
    convenience init<Delegate: _ChatUserListControllerDelegate>(_ delegate: Delegate) where Delegate.ExtraData == ExtraData {
        self.init(
            wrappedDelegate: delegate,
            controllerDidChangeState: { [weak delegate] in delegate?.controller($0, didChangeState: $1) },
            controllerDidChangeUsers: { [weak delegate] in delegate?.controller($0, didChangeUsers: $1) }
        )
    }
}

extension AnyUserListControllerDelegate where ExtraData == NoExtraData {
    convenience init(_ delegate: ChatUserListControllerDelegate?) {
        self.init(
            wrappedDelegate: delegate,
            controllerDidChangeState: { [weak delegate] in delegate?.controller($0, didChangeState: $1) },
            controllerDidChangeUsers: { [weak delegate] in delegate?.controller($0, didChangeUsers: $1) }
        )
    }
}
