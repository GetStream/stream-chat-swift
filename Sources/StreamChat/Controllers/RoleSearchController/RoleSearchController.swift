//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public extension ChatClient {
    /// Creates a new `RoleSearchController`.
    func roleSearchController() -> RoleSearchController {
        .init(client: self)
    }
}

/// A controller for searching roles.
///
/// Roles are not persisted locally. Results are kept in memory and
/// replaced on every new search.
public class RoleSearchController: DataController, DelegateCallable, DataStoreProvider, @unchecked Sendable {
    /// The `ChatClient` instance this controller belongs to.
    public let client: ChatClient

    /// The roles returned by the last search.
    public private(set) var roles: [Role] = []

    /// Set the delegate of `RoleSearchController` to observe changes.
    public weak var delegate: RoleSearchControllerDelegate? {
        get { multicastDelegate.mainDelegate }
        set { multicastDelegate.set(mainDelegate: newValue) }
    }

    var multicastDelegate: MulticastDelegate<RoleSearchControllerDelegate> = .init() {
        didSet {
            stateMulticastDelegate.set(mainDelegate: multicastDelegate.mainDelegate)
            stateMulticastDelegate.set(additionalDelegates: multicastDelegate.additionalDelegates)
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

    private let rolesRepository: RolesRepository

    init(client: ChatClient) {
        self.client = client
        rolesRepository = client.rolesRepository
        super.init()
    }

    /// Searches roles by name.
    ///
    /// The `roles` property is updated with the results on completion.
    ///
    /// - Parameters:
    ///   - text: The search term used to match role names.
    ///   - roleType: When set, restricts the search to roles of the given type.
    ///   - completion: Called with the matching roles or an error.
    public func searchRoles(
        text: String,
        roleType: RoleType? = nil,
        completion: (@MainActor (Result<[Role], Error>) -> Void)? = nil
    ) {
        searchRoles(
            query: RoleSearchQuery(query: text, roleType: roleType),
            completion: completion
        )
    }

    /// Searches roles using the provided query.
    ///
    /// The `roles` property is updated with the results on completion.
    ///
    /// - Parameters:
    ///   - query: The query describing the search term and filters.
    ///   - completion: Called with the matching roles or an error.
    public func searchRoles(
        query: RoleSearchQuery,
        completion: (@MainActor (Result<[Role], Error>) -> Void)? = nil
    ) {
        rolesRepository.searchRoles(query: query) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let fetchedRoles):
                self.roles = fetchedRoles
                self.state = .remoteDataFetched
                self.delegateCallback { [weak self] in
                    guard let self else { return }
                    $0.controller(self, didChangeRoles: self.roles)
                }
                self.callback { completion?(.success(fetchedRoles)) }
            case .failure(let error):
                self.state = .remoteDataFetchFailed(ClientError(with: error))
                self.callback { completion?(.failure(error)) }
            }
        }
    }
}

/// `RoleSearchController` uses this protocol to communicate changes to its delegate.
public protocol RoleSearchControllerDelegate: DataControllerStateDelegate {
    /// The controller updated its list of roles.
    func controller(
        _ controller: RoleSearchController,
        didChangeRoles roles: [Role]
    )
}

public extension RoleSearchControllerDelegate {
    func controller(
        _ controller: RoleSearchController,
        didChangeRoles roles: [Role]
    ) {}
}
