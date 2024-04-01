//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// An object which represents a list of `ChatUser`.
@available(iOS 13.0, *)
public final class UserList {
    private let userListUpdater: UserListUpdater
    
    /// The query specifying and filtering the list of users.
    public let query: UserListQuery
    
    init(users: [ChatUser], query: UserListQuery, userListUpdater: UserListUpdater, client: ChatClient, environment: Environment = .init()) {
        self.query = query
        self.userListUpdater = userListUpdater
        state = environment.stateBuilder(
            users,
            query,
            client.databaseContainer
        )
    }
    
    /// An observable object representing the current state of the users list.
    public let state: UserListState
    
    // MARK: - User List Pagination
    
    /// Loads users for the specified pagination parameters and updates ``UserListState/users``.
    ///
    /// - Parameter pagination: The pagination configuration which includes a limit and an offset or a cursor.
    ///
    /// - Throws: An error while communicating with the Stream API.
    /// - Returns: An array of users for the pagination.
    @discardableResult public func loadUsers(with pagination: Pagination) async throws -> [ChatUser] {
        try await userListUpdater.loadUsers(query, pagination: pagination)
    }
    
    /// Loads more users and updates ``UserListState/users``.
    ///
    /// - Parameters
    ///   - limit: The limit for the page size. The default limit is 30.
    ///
    /// - Throws: An error while communicating with the Stream API.
    /// - Returns: An array of loaded channels.
    @discardableResult public func loadNextUsers(limit: Int? = nil) async throws -> [ChatUser] {
        let limit = (limit ?? query.pagination?.pageSize) ?? Int.usersPageSize
        let offset = state.users.count
        return try await userListUpdater.loadNextUsers(query, limit: limit, offset: offset)
    }
}

@available(iOS 13.0, *)
extension UserList {
    struct Environment {
        var stateBuilder: (
            _ users: [ChatUser],
            _ query: UserListQuery,
            _ database: DatabaseContainer
        ) -> UserListState = UserListState.init
    }
}
