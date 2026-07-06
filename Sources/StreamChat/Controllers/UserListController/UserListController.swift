//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
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
public class ChatUserListController: DataController, DelegateCallable, DataStoreProvider, @unchecked Sendable {
    /// The query specifying and filtering the list of users.
    public var query: UserListQuery { userList.query }

    /// The `ChatClient` instance this controller belongs to.
    public let client: ChatClient

    /// The users matching the query of this controller.
    ///
    /// To observe changes of the users, set your class as a delegate of this controller or use the provided
    /// `Combine` publishers.
    ///
    public var users: [ChatUser] {
        startUserListObserverIfNeeded()
        return StreamConcurrency.onMain { userList.state.users }
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

    private let userList: UserList
    let usersChangesSubject = PassthroughSubject<[ListChange<ChatUser>], Never>()

    /// Creates a new `UserListController`.
    ///
    /// - Parameters:
    ///   - query: The query used for filtering the users.
    ///   - client: The `Client` instance this controller belongs to.
    init(query: UserListQuery, client: ChatClient, environment: Environment = .init()) {
        self.client = client
        self.userList = environment.userListBuilder(query, client)
    }

    override public func synchronize(_ completion: (@MainActor (_ error: Error?) -> Void)? = nil) {
        startUserListObserverIfNeeded()
        withOnMainCompletion {
            try await self.userList.get()
        } completion: { result in
            self.state = result.error == nil ? .remoteDataFetched : .remoteDataFetchFailed(ClientError(with: result.error))
            completion?(result.error)
        }
    }

    func startUserListObserverIfNeeded() {
        guard state == .initialized else { return }
        StreamConcurrency.onMain {
            userList.state.usersDidChangeHandler = { [weak self] changes in
                guard let self else { return }
                usersChangesSubject.send(changes)
                delegateCallback { $0.controller(self, didChangeUsers: changes) }
            }
            state = .localDataFetched
        }
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
        completion: (@MainActor (Error?) -> Void)? = nil
    ) {
        startUserListObserverIfNeeded()
        withOnMainCompletion {
            try await self.userList.loadMoreUsers(limit: limit)
        } completion: { result in
            completion?(result.error)
        }
    }
}

extension ChatUserListController {
    struct Environment {
        var userListBuilder: (
            _ query: UserListQuery,
            _ client: ChatClient
        ) -> UserList = { query, client in
            UserList(query: query, client: client)
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
