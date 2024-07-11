//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// An object which represents a list of `ChatUser` for the specified search query.
public class UserSearch {
    private let stateBuilder: StateBuilder<UserSearchState>
    private let userListUpdater: UserListUpdater
    
    init(client: ChatClient, environment: Environment = .init()) {
        userListUpdater = environment.userListUpdaterBuilder(
            client.databaseContainer,
            client.apiClient
        )
        stateBuilder = StateBuilder { UserSearchState() }
    }
    
    // MARK: - Accessing the State
    
    /// An observable object representing the current state of the search.
    @MainActor public lazy var state: UserSearchState = stateBuilder.build()
    
    // MARK: - Search Results and Pagination
    
    /// Searches for users with the specified search term and updates ``UserSearchState/users``.
    ///
    /// - Parameter term: The search term for searching users. If `nil` or empty, all users are returned.
    ///
    /// - Throws: An error while communicating with the Stream API.
    /// - Returns: An array of users for the search term.
    @discardableResult public func search(term: String?) async throws -> [ChatUser] {
        try await search(query: .search(term: term))
    }
    
    /// Searches for users with the specified query and updates ``UserSearchState/users``.
    ///
    /// - Parameter query: The user list query used for searching.
    ///
    /// - Throws: An error while communicating with the Stream API.
    /// - Returns: An array of users for the query.
    @discardableResult public func search(query: UserListQuery) async throws -> [ChatUser] {
        let limit = query.pagination?.pageSize ?? .usersPageSize
        let pagination = Pagination(pageSize: limit, offset: 0)
        return try await search(query: query, pagination: pagination)
    }
    
    /// Searches for more users with the specified query and updates ``UserSearchState/users``.
    ///
    /// - Parameters
    ///   - limit: The limit for the page size. The default limit is 30.
    ///
    /// - Throws: An error while communicating with the Stream API.
    /// - Returns: An array of loaded channels.
    @discardableResult public func loadMoreUsers(limit: Int? = nil) async throws -> [ChatUser] {
        guard let query = await state.query else { throw ClientError("Call search() before calling for next page") }
        let limit = (limit ?? query.pagination?.pageSize) ?? .usersPageSize
        let offset = await state.users.count
        let pagination = Pagination(pageSize: limit, offset: offset)
        return try await search(query: query, pagination: pagination)
    }
    
    // MARK: - Private
    
    private func search(query: UserListQuery, pagination: Pagination) async throws -> [ChatUser] {
        let query = query.withPagination(pagination)
        await state.setQuery(query)
        let users = try await userListUpdater.fetch(userListQuery: query, pagination: pagination)
        await state.handleDidFetchQuery(query, users: users)
        return users
    }
}

extension UserSearch {
    struct Environment {
        var userListUpdaterBuilder: (
            _ database: DatabaseContainer,
            _ apiClient: APIClient
        ) -> UserListUpdater = UserListUpdater.init
    }
}
