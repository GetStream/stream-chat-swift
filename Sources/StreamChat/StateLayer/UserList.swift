//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// An object which represents a list of `ChatUser`.
public final class UserList {
    private let query: UserListQuery
    private let stateBuilder: StateBuilder<UserListState>
    private let userListUpdater: UserListUpdater
    
    init(query: UserListQuery, client: ChatClient, environment: Environment = .init()) {
        self.query = query
        userListUpdater = environment.userListUpdater(
            client.databaseContainer,
            client.apiClient
        )
        stateBuilder = StateBuilder {
            environment.stateBuilder(
                query,
                client.databaseContainer
            )
        }
    }
    
    // MARK: - Accessing the State
    
    /// An observable object representing the current state of the users list.
    @MainActor public lazy var state: UserListState = stateBuilder.build()
    
    /// Fetches the most recent state from the server and updates the local store.
    ///
    /// - Important: Loaded users in ``UserListState/users`` are reset.
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func get() async throws {
        let pagination = Pagination(pageSize: query.pagination?.pageSize ?? .usersPageSize)
        try await loadUsers(with: pagination)
    }
    
    // MARK: - Users Pagination
    
    /// Loads users for the specified pagination parameters and updates ``UserListState/users``.
    ///
    /// - Important: If pagination offset is 0 and cursor is nil, then loaded users are reset.
    ///
    /// - Parameter pagination: The pagination configuration which includes a limit and an offset or a cursor.
    ///
    /// - Throws: An error while communicating with the Stream API.
    /// - Returns: An array of users for the pagination.
    @discardableResult public func loadUsers(with pagination: Pagination) async throws -> [ChatUser] {
        try await userListUpdater.loadUsers(state.query, pagination: pagination)
    }
    
    /// Loads more users and updates ``UserListState/users``.
    ///
    /// - Parameters
    ///   - limit: The limit for the page size. The default limit is 30.
    ///
    /// - Throws: An error while communicating with the Stream API.
    /// - Returns: An array of loaded channels.
    @discardableResult public func loadMoreUsers(limit: Int? = nil) async throws -> [ChatUser] {
        let state = await self.state
        let limit = (limit ?? state.query.pagination?.pageSize) ?? Int.usersPageSize
        let offset = await state.users.count
        return try await userListUpdater.loadNextUsers(state.query, limit: limit, offset: offset)
    }
}

extension UserList {
    struct Environment {
        var userListUpdater: (
            _ database: DatabaseContainer,
            _ apiClient: APIClient
        ) -> UserListUpdater = UserListUpdater.init
        
        var stateBuilder: @MainActor(
            _ query: UserListQuery,
            _ database: DatabaseContainer
        ) -> UserListState = { @MainActor in
            UserListState(query: $0, database: $1)
        }
    }
}
