//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// An object which represents a list of `ChatUser` for the specified search query.
///
/// Search requests are debounced according to ``debouncePolicy``.
/// Calling ``search(term:)`` or ``search(query:)`` again cancels the previous in-flight search.
public class UserSearch: @unchecked Sendable {
    @MainActor private var stateBuilder: StateBuilder<UserSearchState>
    private let userListUpdater: UserListUpdater
    private let searchDebouncer: AsyncSearchDebouncer
    /// The debounce policy used for search requests.
    ///
    /// Defaults to ``SearchDebouncePolicy/default`` (500ms for 1–2 characters, 300ms for 3+).
    var debouncePolicy: SearchDebouncePolicy {
        get { searchDebouncer.policy }
        set { searchDebouncer.policy = newValue }
    }

    init(client: ChatClient, environment: Environment = .init()) {
        userListUpdater = environment.userListUpdaterBuilder(
            client.databaseContainer,
            client.apiClient
        )
        searchDebouncer = AsyncSearchDebouncer(policy: .default)
        stateBuilder = StateBuilder { UserSearchState() }
    }
    
    // MARK: - Accessing the State
    
    /// An observable object representing the current state of the search.
    @MainActor public var state: UserSearchState { stateBuilder.state }
    
    // MARK: - Search Results and Pagination
    
    /// Searches for users with the specified search term and updates ``UserSearchState/users``.
    ///
    /// - Parameter term: The search term for searching users. If `nil` or empty, all users are returned.
    ///
    /// - Throws: An error while communicating with the Stream API. Throws `CancellationError` when superseded by a newer search.
    /// - Returns: An array of users for the search term.
    @discardableResult public func search(term: String?) async throws -> [ChatUser] {
        try await search(query: .search(term: term), queryLength: term?.count ?? 0)
    }
    
    /// Searches for users with the specified query and updates ``UserSearchState/users``.
    ///
    /// - Parameter query: The user list query used for searching.
    ///
    /// - Throws: An error while communicating with the Stream API. Throws `CancellationError` when superseded by a newer search.
    /// - Returns: An array of users for the query.
    @discardableResult public func search(query: UserListQuery) async throws -> [ChatUser] {
        try await search(
            query: query,
            queryLength: SearchQueryLength.fromFilter(query.filter)
        )
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
        return try await performSearch(query: query, pagination: pagination)
    }
    
    // MARK: - Private

    private func search(query: UserListQuery, queryLength: Int) async throws -> [ChatUser] {
        let limit = query.pagination?.pageSize ?? .usersPageSize
        let pagination = Pagination(pageSize: limit, offset: 0)
        let result = try await searchDebouncer.schedule(queryLength: queryLength) { [weak self] in
            guard let self else { throw ClientError("UserSearch was deallocated") }
            return try await self.performSearch(query: query, pagination: pagination)
        }
        if let result {
            return result
        }
        return await state.users
    }
    
    private func performSearch(query: UserListQuery, pagination: Pagination) async throws -> [ChatUser] {
        let query = query.withPagination(pagination)
        await state.setQuery(query)
        let users = try await userListUpdater.fetch(userListQuery: query, pagination: pagination)
        try Task.checkCancellation()
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
