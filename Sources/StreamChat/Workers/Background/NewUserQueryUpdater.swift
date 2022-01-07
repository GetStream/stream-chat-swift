//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import CoreData

/// After creating new user it's not observed cause it's not linked to any UserListQuery.
/// The only job of `NewUserQueryUpdater` is to find whether new user belongs to any of the exsisting queries
/// and link it to the user if so.
///     1. This worker observers DB for the insertations of the new `UserDTO`s without any linked queries.
///     2. When new user is found, all exsisting queries are fetched from DB and we modify exsiting queries filters so
///     in response for `update(userListQuery` request new user will be returned if it is part of the original query filter.
///     3. After sending `update(userListQuery` for all queries `UserListUpdater` does the job of linking
///     corresponding queries to the user.
final class NewUserQueryUpdater: Worker {
    private let environment: Environment
        
    private lazy var userListUpdater: UserListUpdater = self.environment
        .createUserListUpdater(
            database,
            apiClient
        )
    
    private lazy var usersObserver: ListDatabaseObserver = .init(
        context: self.database.backgroundReadOnlyContext,
        fetchRequest: UserDTO.userWithoutQueryFetchRequest
    )
    
    private var queries: [UserListQueryDTO] {
        do {
            let queries = try database.backgroundReadOnlyContext
                .fetch(UserListQueryDTO.observedQueries())
            return queries
        } catch {
            log.error("Internal error: Failed to fetch [UserListQueryDTO]: \(error)")
        }
        return []
    }
    
    init(database: DatabaseContainer, apiClient: APIClient, env: Environment) {
        environment = env
        super.init(database: database, apiClient: apiClient)
        
        startObserving()
    }
    
    override convenience init(database: DatabaseContainer, apiClient: APIClient) {
        self.init(database: database, apiClient: apiClient, env: .init())
    }
    
    private func startObserving() {
        // We have to initialize the lazy variables synchronously
        _ = userListUpdater
        _ = usersObserver
        
        // But the observing can be started on a background queue
        DispatchQueue.global().async { [weak self] in
            do {
                self?.usersObserver.onChange = { changes in
                    self?.handle(changes: changes)
                }
                try self?.usersObserver.startObserving()
                self?.usersObserver.items.forEach { self?.updateUserListQuery(for: $0) }
            } catch {
                log.error("Error starting NewUserQueryUpdater observer: \(error)")
            }
        }
    }
    
    private func handle(changes: [ListChange<UserDTO>]) {
        // Observe `UserDTO` insertations
        changes.forEach { change in
            switch change {
            case let .insert(userDTO, _):
                updateUserListQuery(for: userDTO)
            default: return
            }
        }
    }
    
    private func updateUserListQuery(for userDTO: UserDTO) {
        database.backgroundReadOnlyContext.perform { [weak self] in
            guard let queries = self?.queries else { return }

            // Existing queries with modified filter parameter
            var updatedQueries: [UserListQuery] = []
            
            do {
                updatedQueries = try queries.map {
                    // Modify original query filter
                    try $0.asUserListQueryWithUpdatedFilter(filterToAdd: .equal("id", to: userDTO.id))
                }
                
            } catch {
                log.error("Internal error. Failed to update UserListQueries for the new user: \(error)")
            }
            
            // Send `update(userListQuery:` requests so corresponding queries will be linked to the user
            updatedQueries.forEach {
                self?.userListUpdater.update(userListQuery: $0) { error in
                    if let error = error {
                        log
                            .error("Internal error. Failed to update UserListQueries for the new user: \(error)")
                    }
                }
            }
        }
    }
}

extension NewUserQueryUpdater {
    struct Environment {
        var createUserListUpdater: (
            _ database: DatabaseContainer,
            _ apiClient: APIClient
        ) -> UserListUpdater = UserListUpdater.init
    }
}

private extension UserListQueryDTO {
    func asUserListQueryWithUpdatedFilter(
        filterToAdd filter: Filter<UserListFilterScope>
    ) throws -> UserListQuery {
        let encodedFilter = try JSONDecoder.default.decode(Filter<UserListFilterScope>.self, from: filterJSONData)
        
        // We need to pass original `filterHash` so user will be linked to original query, not the modified one
        var updatedFilter: Filter<UserListFilterScope> = .and([encodedFilter, filter])
        updatedFilter.explicitHash = filterHash
        
        return UserListQuery(filter: updatedFilter)
    }
}
