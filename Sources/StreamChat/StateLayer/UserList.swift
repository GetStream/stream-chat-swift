//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// An object which represents a list of `ChatUser`.
@available(iOS 13.0, *)
public final class UserList {
    private let stateBuilder: StateBuilder<UserListState>
    private let userListUpdater: UserListUpdater
    
    init(query: UserListQuery, userListUpdater: UserListUpdater, client: ChatClient, environment: Environment = .init()) {
        self.userListUpdater = userListUpdater
        stateBuilder = StateBuilder {
            environment.stateBuilder(
                query,
                client.databaseContainer
            )
        }
    }
    
    /// An observable object representing the current state of the users list.
    @MainActor public lazy var state: UserListState = stateBuilder.build()
    
    // MARK: - User List Pagination
    
    /// Loads users for the specified pagination parameters and updates ``UserListState/users``.
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
    @discardableResult public func loadNextUsers(limit: Int? = nil) async throws -> [ChatUser] {
        let state = await self.state
        let limit = (limit ?? state.query.pagination?.pageSize) ?? Int.usersPageSize
        let offset = await state.users.count
        return try await userListUpdater.loadNextUsers(state.query, limit: limit, offset: offset)
    }
}

@available(iOS 13.0, *)
extension UserList {
    struct Environment {
        var stateBuilder: @MainActor(
            _ query: UserListQuery,
            _ database: DatabaseContainer
        ) -> UserListState = { @MainActor in
            UserListState(query: $0, database: $1)
        }
    }
}
