//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

public extension ChatClient {
    /// Creates a new `UserGroupController` for the user group with the provided identifier.
    func userGroupController(userGroupId: String, teamId: String? = nil) -> UserGroupController {
        .init(userGroupId: userGroupId, teamId: teamId, client: self)
    }
}

/// `UserGroupController` uses this protocol to communicate changes to its delegate.
public protocol UserGroupControllerDelegate: DataControllerStateDelegate {
    /// The controller changed the observed user group.
    func userGroupController(
        _ controller: UserGroupController,
        didUpdateUserGroup change: EntityChange<UserGroup>
    )
}

/// A controller which allows observing and mutating a specific user group.
public class UserGroupController: DataController, DelegateCallable, DataStoreProvider, @unchecked Sendable {
    /// The identifier of the user group this controller manages.
    public let userGroupId: String

    /// The team identifier when the user group is team-scoped.
    public let teamId: String?

    /// The `ChatClient` instance this controller belongs to.
    public let client: ChatClient

    /// The user group the controller represents.
    public var userGroup: UserGroup? {
        startObservingIfNeeded()
        return userGroupObserver.item
    }

    /// Set the delegate of `UserGroupController` to observe the changes in the system.
    public var delegate: UserGroupControllerDelegate? {
        get { multicastDelegate.mainDelegate }
        set { multicastDelegate.set(mainDelegate: newValue) }
    }

    var multicastDelegate: MulticastDelegate<UserGroupControllerDelegate> = .init() {
        didSet {
            stateMulticastDelegate.set(mainDelegate: multicastDelegate.mainDelegate)
            stateMulticastDelegate.set(additionalDelegates: multicastDelegate.additionalDelegates)
            startObservingIfNeeded()
        }
    }

    private lazy var userGroupObserver = createUserGroupObserver()
        .onChange { [weak self] change in
            self?.delegateCallback { [weak self] in
                guard let self else { return }
                $0.userGroupController(self, didUpdateUserGroup: change)
            }
        }

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

    init(
        userGroupId: String,
        teamId: String?,
        client: ChatClient,
        environment: Environment = .init()
    ) {
        self.userGroupId = userGroupId
        self.teamId = teamId
        self.client = client
        self.environment = environment
        userGroupsRepository = client.userGroupsRepository
        super.init()
    }

    override public func synchronize(_ completion: (@MainActor (_ error: Error?) -> Void)? = nil) {
        startObservingIfNeeded()

        userGroupsRepository.loadUserGroup(id: userGroupId, teamId: teamId) { [weak self] result in
            guard let self else { return }
            if let error = result.error {
                self.state = .remoteDataFetchFailed(ClientError(with: error))
            } else {
                self.state = .remoteDataFetched
            }
            self.callback { completion?(result.error) }
        }
    }

    private func createUserGroupObserver() -> BackgroundEntityDatabaseObserver<UserGroup, UserGroupDTO> {
        environment.userGroupObserverBuilder(
            client.databaseContainer,
            UserGroupDTO.fetchRequest(id: userGroupId),
            { $0.asModel() },
            NSFetchedResultsController<UserGroupDTO>.self
        )
    }

    private func startObservingIfNeeded() {
        guard state == .initialized else { return }

        do {
            try userGroupObserver.startObserving()
            state = .localDataFetched
        } catch {
            log.error("Observing user group with id <\(userGroupId)> failed: \(error). Accessing `userGroup` will always return `nil`")
            state = .localDataFetchFailed(ClientError(with: error))
        }
    }
}

public extension UserGroupController {
    /// Updates the user group.
    func update(
        name: String? = nil,
        description: String? = nil,
        teamId: String? = nil,
        completion: (@MainActor (Result<UserGroup, Error>) -> Void)? = nil
    ) {
        let request = UpdateUserGroupRequest(
            description: description,
            name: name,
            teamId: teamId ?? self.teamId
        )

        userGroupsRepository.updateUserGroup(id: userGroupId, request: request) { [weak self] result in
            self?.callback {
                completion?(result)
            }
        }
    }

    /// Adds members to the user group.
    func addMembers(
        _ memberIds: [UserId],
        asAdmin: Bool = false,
        teamId: String? = nil,
        completion: (@MainActor (Result<UserGroup, Error>) -> Void)? = nil
    ) {
        let request = AddUserGroupMembersRequest(
            asAdmin: asAdmin,
            memberIds: memberIds,
            teamId: teamId ?? self.teamId
        )

        userGroupsRepository.addMembers(id: userGroupId, request: request) { [weak self] result in
            self?.callback {
                completion?(result)
            }
        }
    }

    /// Removes members from the user group.
    func removeMembers(
        _ memberIds: [UserId],
        teamId: String? = nil,
        completion: (@MainActor (Result<UserGroup, Error>) -> Void)? = nil
    ) {
        let request = RemoveUserGroupMembersRequest(
            memberIds: memberIds,
            teamId: teamId ?? self.teamId
        )

        userGroupsRepository.removeMembers(id: userGroupId, request: request) { [weak self] result in
            self?.callback {
                completion?(result)
            }
        }
    }
}

extension UserGroupController {
    struct Environment {
        var userGroupObserverBuilder: (
            _ databaseContainer: DatabaseContainer,
            _ fetchRequest: NSFetchRequest<UserGroupDTO>,
            _ itemCreator: @escaping (UserGroupDTO) -> UserGroup,
            _ fetchedResultsControllerType: NSFetchedResultsController<UserGroupDTO>.Type
        ) -> BackgroundEntityDatabaseObserver<UserGroup, UserGroupDTO> = BackgroundEntityDatabaseObserver.init
    }
}

public extension UserGroupControllerDelegate {
    func userGroupController(
        _ controller: UserGroupController,
        didUpdateUserGroup change: EntityChange<UserGroup>
    ) {}
}
