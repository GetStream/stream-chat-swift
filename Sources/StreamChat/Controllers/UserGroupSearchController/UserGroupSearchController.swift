//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public extension ChatClient {
    /// Creates a new `UserGroupSearchController`.
    func userGroupSearchController() -> UserGroupSearchController {
        .init(client: self)
    }
}

/// A controller for searching user groups.
///
/// Text searches are debounced: 500ms for 1-2 characters, 300ms for 3 or more.
/// Scheduling a new search cancels any pending debounced work.
///
/// Results are replaced on every new search.
///
/// - Note: For an async-await alternative, please check ``UserGroupSearch``.
public class UserGroupSearchController: DataController, DelegateCallable, DataStoreProvider, @unchecked Sendable {
    /// The `ChatClient` instance this controller belongs to.
    public let client: ChatClient

    /// The user groups returned by the last search.
    public private(set) var userGroups: [UserGroup] = []

    /// Set the delegate of `UserGroupSearchController` to observe changes.
    public weak var delegate: UserGroupSearchControllerDelegate? {
        get { multicastDelegate.mainDelegate }
        set { multicastDelegate.set(mainDelegate: newValue) }
    }

    var multicastDelegate: MulticastDelegate<UserGroupSearchControllerDelegate> = .init() {
        didSet {
            stateMulticastDelegate.set(mainDelegate: multicastDelegate.mainDelegate)
            stateMulticastDelegate.set(additionalDelegates: multicastDelegate.additionalDelegates)
        }
    }

    private let userGroupsRepository: UserGroupsRepository
    private let searchDebouncer: SearchDebouncer

    init(
        client: ChatClient,
        debouncePolicy: SearchDebouncePolicy = .default
    ) {
        self.client = client
        userGroupsRepository = client.userGroupsRepository
        searchDebouncer = SearchDebouncer(policy: debouncePolicy)
        super.init()
    }

    deinit {
        searchDebouncer.cancel()
    }

    /// Searches user groups by name.
    ///
    /// The `userGroups` property is updated with the results on completion.
    ///
    /// - Parameters:
    ///   - text: The search term used to match group names.
    ///   - teamId: When set, restricts the search to groups scoped to the given team.
    ///   - completion: Called with the matching user groups or an error.
    public func searchUserGroups(
        text: String,
        teamId: String? = nil,
        completion: (@MainActor (Result<[UserGroup], Error>) -> Void)? = nil
    ) {
        searchUserGroups(
            query: UserGroupSearchQuery(query: text, teamId: teamId),
            completion: completion
        )
    }

    /// Searches user groups using the provided query.
    ///
    /// The `userGroups` property is updated with the results on completion.
    ///
    /// - Note: Searches are debounced on the length of ``UserGroupSearchQuery/query``.
    ///
    /// - Parameters:
    ///   - query: The query describing the search term and filters.
    ///   - completion: Called with the matching user groups or an error.
    public func searchUserGroups(
        query: UserGroupSearchQuery,
        completion: (@MainActor (Result<[UserGroup], Error>) -> Void)? = nil
    ) {
        let scheduled = searchDebouncer.schedule(queryLength: query.query.count) { [weak self] in
            self?.fetch(query, completion: completion)
        }
        if !scheduled {
            callback { [weak self] in
                completion?(.success(self?.userGroups ?? []))
            }
        }
    }

    /// Cancels any pending search and clears the current results.
    public func clearResults() {
        searchDebouncer.cancel()
        let previousUserGroups = userGroups
        guard !previousUserGroups.isEmpty else { return }

        userGroups = []
        delegateCallback { [weak self] in
            guard let self else { return }
            $0.controller(self, didChangeUserGroups: self.userGroups)
        }
    }

    private func fetch(
        _ query: UserGroupSearchQuery,
        completion: (@MainActor (Result<[UserGroup], Error>) -> Void)?
    ) {
        userGroupsRepository.searchUserGroups(query: query) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let fetchedUserGroups):
                self.userGroups = fetchedUserGroups
                self.state = .remoteDataFetched
                self.delegateCallback { [weak self] in
                    guard let self else { return }
                    $0.controller(self, didChangeUserGroups: self.userGroups)
                }
                self.callback { completion?(.success(fetchedUserGroups)) }
            case .failure(let error):
                self.state = .remoteDataFetchFailed(ClientError(with: error))
                self.callback { completion?(.failure(error)) }
            }
        }
    }
}

/// `UserGroupSearchController` uses this protocol to communicate changes to its delegate.
public protocol UserGroupSearchControllerDelegate: DataControllerStateDelegate {
    /// The controller updated its list of user groups.
    func controller(
        _ controller: UserGroupSearchController,
        didChangeUserGroups userGroups: [UserGroup]
    )
}

public extension UserGroupSearchControllerDelegate {
    func controller(
        _ controller: UserGroupSearchController,
        didChangeUserGroups userGroups: [UserGroup]
    ) {}
}
