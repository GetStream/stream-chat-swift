//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

public extension ChatClient {
    /// Creates a new `UserGroupListController` with the provided query.
    func userGroupListController(query: UserGroupListQuery = .init()) -> UserGroupListController {
        .init(query: query, client: self)
    }
}

/// `UserGroupListController` uses this protocol to communicate changes to its delegate.
public protocol UserGroupListControllerDelegate: DataControllerStateDelegate {
    /// The controller changed the list of observed user groups.
    func controller(
        _ controller: UserGroupListController,
        didChangeUserGroups changes: [ListChange<UserGroup>]
    )
}

/// A controller which allows querying and filtering user groups.
public class UserGroupListController: DataController, DelegateCallable, DataStoreProvider, @unchecked Sendable {
    /// The query specifying and filtering the list of user groups.
    public let query: UserGroupListQuery

    /// The `ChatClient` instance this controller belongs to.
    public let client: ChatClient

    /// The user groups the controller represents.
    public var userGroups: [UserGroup] {
        startUserGroupsObserverIfNeeded()
        return userGroupsObserver.items
    }

    /// A Boolean value that returns whether pagination is finished.
    public private(set) var hasLoadedAllUserGroups: Bool = false

    /// Set the delegate of `UserGroupListController` to observe the changes in the system.
    public weak var delegate: UserGroupListControllerDelegate? {
        get { multicastDelegate.mainDelegate }
        set { multicastDelegate.set(mainDelegate: newValue) }
    }

    var multicastDelegate: MulticastDelegate<UserGroupListControllerDelegate> = .init() {
        didSet {
            stateMulticastDelegate.set(mainDelegate: multicastDelegate.mainDelegate)
            stateMulticastDelegate.set(additionalDelegates: multicastDelegate.additionalDelegates)
            startUserGroupsObserverIfNeeded()
        }
    }

    private(set) lazy var userGroupsObserver: BackgroundListDatabaseObserver<UserGroup, UserGroupDTO> = {
        let request = UserGroupDTO.userGroupsFetchRequest(query: self.query)

        let observer = self.environment.createUserGroupListDatabaseObserver(
            client.databaseContainer,
            request,
            { $0.asModel() }
        )

        observer.onDidChange = { [weak self] changes in
            self?.delegateCallback { [weak self] in
                guard let self else { return }
                $0.controller(self, didChangeUserGroups: changes)
            }
        }

        return observer
    }()

    var _basePublishers: Any?
    var basePublishers: BasePublishers {
        if let value = _basePublishers as? BasePublishers {
            return value
        }
        _basePublishers = BasePublishers(controller: self)
        return _basePublishers as? BasePublishers ?? .init(controller: self)
    }

    private let userGroupsRepository: UserGroupsRepository
    private let environment: Environment

    init(query: UserGroupListQuery, client: ChatClient, environment: Environment = .init()) {
        self.client = client
        self.query = query
        self.environment = environment
        userGroupsRepository = client.userGroupsRepository
        super.init()
    }

    override public func synchronize(_ completion: (@MainActor (_ error: Error?) -> Void)? = nil) {
        startUserGroupsObserverIfNeeded()

        userGroupsRepository.loadUserGroups(query: query) { [weak self] result in
            guard let self else { return }
            if let value = result.value {
                self.hasLoadedAllUserGroups = !value.hasMore
            }
            if let error = result.error {
                self.state = .remoteDataFetchFailed(ClientError(with: error))
            } else {
                self.state = .remoteDataFetched
            }
            self.callback { completion?(result.error) }
        }
    }

    private func startUserGroupsObserverIfNeeded() {
        guard state == .initialized else { return }
        do {
            try userGroupsObserver.startObserving()
            state = .localDataFetched
        } catch {
            state = .localDataFetchFailed(ClientError(with: error))
            log.error("Failed to perform fetch request with error: \(error). This is an internal error.")
        }
    }
}

public extension UserGroupListController {
    /// Loads the next page of user groups.
    func loadMoreUserGroups(
        completion: (@MainActor (Error?) -> Void)? = nil
    ) {
        guard let lastUserGroup = userGroups.last else {
            callback { completion?(nil) }
            return
        }

        var updatedQuery = query
        updatedQuery.idGreaterThan = lastUserGroup.id
        updatedQuery.createdAtGreaterThan = lastUserGroup.createdAt

        userGroupsRepository.loadUserGroups(query: updatedQuery) { [weak self] result in
            guard let self else { return }
            if let value = result.value {
                self.hasLoadedAllUserGroups = !value.hasMore
            }
            self.callback { completion?(result.error) }
        }
    }

    /// Searches user groups by name prefix.
    ///
    /// - Note: The `userGroups` property is not updated by this method. Search results are returned only in the completion block.
    func searchUserGroups(
        text: String,
        completion: (@MainActor (Result<[UserGroup], Error>) -> Void)? = nil
    ) {
        searchUserGroups(
            query: UserGroupSearchQuery(query: text, teamId: query.teamId),
            completion: completion
        )
    }

    /// Searches user groups using the provided query.
    ///
    /// - Note: The `userGroups` property is not updated by this method. Search results are returned only in the completion block.
    func searchUserGroups(
        query: UserGroupSearchQuery,
        completion: (@MainActor (Result<[UserGroup], Error>) -> Void)? = nil
    ) {
        userGroupsRepository.searchUserGroups(query: query) { [weak self] result in
            self?.callback {
                completion?(result)
            }
        }
    }

    /// Creates a new user group.
    func createUserGroup(
        id: String? = nil,
        name: String,
        description: String? = nil,
        teamId: String? = nil,
        memberIds: [UserId] = [],
        completion: (@MainActor (Result<UserGroup, Error>) -> Void)? = nil
    ) {
        let request = CreateUserGroupRequestBody(
            id: id,
            name: name,
            description: description,
            teamId: teamId,
            memberIds: memberIds
        )

        userGroupsRepository.createUserGroup(request: request) { [weak self] result in
            self?.callback {
                completion?(result)
            }
        }
    }

    /// Deletes a user group.
    func deleteUserGroup(
        id: String,
        teamId: String? = nil,
        completion: (@MainActor (Error?) -> Void)? = nil
    ) {
        userGroupsRepository.deleteUserGroup(id: id, teamId: teamId ?? query.teamId) { [weak self] error in
            self?.callback {
                completion?(error)
            }
        }
    }
}

extension UserGroupListController {
    struct Environment {
        var createUserGroupListDatabaseObserver: (
            _ database: DatabaseContainer,
            _ fetchRequest: NSFetchRequest<UserGroupDTO>,
            _ itemCreator: @escaping (UserGroupDTO) -> UserGroup
        ) -> BackgroundListDatabaseObserver<UserGroup, UserGroupDTO> = {
            BackgroundListDatabaseObserver(
                database: $0,
                fetchRequest: $1,
                itemCreator: $2,
                itemReuseKeyPaths: (\UserGroup.id, \UserGroupDTO.id)
            )
        }
    }
}

public extension UserGroupListControllerDelegate {
    func controller(
        _ controller: UserGroupListController,
        didChangeUserGroups changes: [ListChange<UserGroup>]
    ) {}
}
