//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import CoreData
import Foundation

extension ChatClient {
    /// Creates a new `ChatUserListController` with the provided user query.
    ///
    /// - Parameter query: The query specify the filter and sorting of the users the controller should fetch.
    ///
    /// - Returns: A new instance of `ChatUserListController`.
    ///
    public func userListController(query: UserListQuery = .init()) -> ChatUserListController {
        .init(query: query, client: self)
    }
}

/// `ChatUserListController` is a controller class which allows observing a list of chat users based on the provided query.
///
/// - Note: For an async-await alternative of the `ChatUserListController`, please check ``UserList`` in the async-await supported [state layer](https://getstream.io/chat/docs/sdk/ios/client/state-layer/state-layer-overview/).
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
        return userList.state { LazyCachedMapCollection(source: $0.state.users, map: { $0 }) }
    }

    /// A type-erased delegate.
    var multicastDelegate: MulticastDelegate<ChatUserListControllerDelegate> = .init() {
        didSet {
            stateMulticastDelegate.set(mainDelegate: multicastDelegate.mainDelegate)
            stateMulticastDelegate.set(additionalDelegates: multicastDelegate.additionalDelegates)

            // After setting delegate local changes will be fetched and observed.
            startUserListObserverIfNeeded()
        }
    }

    var _basePublishers: Any?
    /// An internal backing object for all publicly available Combine publishers. We use it to simplify the way we expose
    /// publishers. Instead of creating custom `Publisher` types, we use `CurrentValueSubject` and `PassthroughSubject` internally,
    /// and expose the published values by mapping them to a read-only `AnyPublisher` type.
    var basePublishers: BasePublishers {
        if let value = _basePublishers as? BasePublishers {
            return value
        }
        _basePublishers = BasePublishers(controller: self)
        return _basePublishers as? BasePublishers ?? .init(controller: self)
    }

    private let userList: StateLayerControllerAdapter<UserList>
    
    /// Creates a new `UserListController`.
    ///
    /// - Parameters:
    ///   - query: The query used for filtering the users.
    ///   - client: The `Client` instance this controller belongs to.
    init(query: UserListQuery, client: ChatClient, environment: UserList.Environment = .init()) {
        self.client = client
        self.query = query
        userList = StateLayerControllerAdapter(
            stateLayer: UserList(
                query: query,
                client: client,
                environment: environment
            )
        )
    }

    override public func synchronize(_ completion: ((_ error: Error?) -> Void)? = nil) {
        Task.run {
            try await self.userList.stateLayer.get()
        } completion: { error in
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
        userList.observe { [weak self] userList, cancellables in
            userList.state.$usersLatestChanges
                .sink { [weak self] changes in
                    guard let self else { return }
                    self.delegateCallback {
                        $0.controller(self, didChangeUsers: changes)
                    }
                }
                .store(in: &cancellables)
        }
        state = .localDataFetched
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
        Task.run {
            try await self.userList.stateLayer.loadMoreUsers(limit: limit)
        } completion: { error in
            self.callback { completion?(error) }
        }
    }
}

extension ChatUserListController {
    /// Set the delegate of `UserListController` to observe the changes in the system.
    public weak var delegate: ChatUserListControllerDelegate? {
        get { multicastDelegate.mainDelegate }
        set { multicastDelegate.set(mainDelegate: newValue) }
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

// MARK: - Support

// TODO: move to a new file

/// State layer requires main actor when accessing the current state (reduces errors made when using publishers and simplifies concurrency).
/// Controllers do not have main actor requirements so we'll need to handle it here. Common case is that controllers are used from the main
/// thread. In that particular case, switching to state layer gives a performance boost since managedobjectcontext thread is not used any more for reading data.
final class StateLayerControllerAdapter<StateLayer> {
    private var cancellables = Set<AnyCancellable>()
    let stateLayer: StateLayer
    
    init(stateLayer: StateLayer) {
        self.stateLayer = stateLayer
    }
    
    func state<T>(_ read: @MainActor(StateLayer) -> T) -> T {
        onMain {
            read(stateLayer)
        }
    }
    
    func observe(_ block: @MainActor(StateLayer, inout Set<AnyCancellable>) -> Void) {
        onMain {
            block(stateLayer, &cancellables)
        }
    }
    
    private func onMain<T>(_ block: @MainActor() -> T) -> T {
        if Thread.isMainThread {
            return MainActor.assumeIsolated {
                block()
            }
        } else {
            return DispatchQueue.main.sync {
                block()
            }
        }
    }
}

extension Task {
    static func run(_ actions: @escaping () async throws -> Success, completion: @escaping (Result<Success, Failure>) -> Void) where Failure == Error {
        Task<Void, Never> {
            do {
                let result = try await actions()
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    static func run(_ actions: @escaping () async throws -> Success, completion: @escaping (Error?) -> Void) where Failure == Error, Success == Void {
        Task<Void, Never> {
            do {
                try await actions()
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }
}
