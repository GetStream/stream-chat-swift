//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// An object which represents a list of `ChatUser` for the specified search query.
///
/// Text searches are debounced: 500ms for 1-2 characters, 300ms for 3 or more.
/// Calling ``search(term:)`` or ``search(query:)`` again cancels the previous in-flight search.
public class UserSearch: @unchecked Sendable {
    @MainActor private var stateBuilder: StateBuilder<UserSearchState>
    private let userListUpdater: UserListUpdater
    private let searchDebouncer: AsyncSearchDebouncer
    init(
        client: ChatClient,
        environment: Environment = .init(),
        debouncePolicy: SearchDebouncePolicy = .default
    ) {
        userListUpdater = environment.userListUpdaterBuilder(
            client.databaseContainer,
            client.apiClient
        )
        searchDebouncer = AsyncSearchDebouncer(policy: debouncePolicy)
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
    /// - Throws: An error while communicating with the Stream API.
    /// - Returns: An array of users for the search term. When a newer search supersedes this
    /// one, the current ``UserSearchState/users`` are returned.
    @discardableResult public func search(term: String?) async throws -> [ChatUser] {
        try await search(query: .search(term: term))
    }
    
    /// Searches for users with the specified query and updates ``UserSearchState/users``.
    ///
    /// - Parameter query: The user list query used for searching.
    ///
    /// - Note: A query built around a text-search operator (`.autocomplete`, `.query`) is
    /// debounced on the length of that text, even when combined with other filters. A query
    /// with no search text is not typed character by character, so it runs right away — a
    /// later search still cancels it either way.
    ///
    /// - Throws: An error while communicating with the Stream API.
    /// - Returns: An array of users for the query. When a newer search supersedes this one,
    /// the current ``UserSearchState/users`` are returned.
    @discardableResult public func search(query: UserListQuery) async throws -> [ChatUser] {
        let pagination = Pagination(pageSize: query.pagination?.pageSize ?? .usersPageSize, offset: 0)
        let result = try await searchDebouncer.schedule(filter: query.filter) { [weak self] in
            guard let self else { throw ClientError("UserSearch was deallocated") }
            return try await self.performSearch(query: query, pagination: pagination)
        }
        if let result {
            return result
        }
        return await state.users
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

    /// Cancels any pending or in-flight search and clears ``UserSearchState/users``.
    public func clearResults() async {
        await searchDebouncer.cancel()
        await state.clear()
    }
    
    // MARK: - Private

    private func performSearch(query: UserListQuery, pagination: Pagination) async throws -> [ChatUser] {
        let query = query.withPagination(pagination)
        // A superseded search must not publish its query. `state.query` is what
        // `handleDidFetchQuery` compares against and what `loadMoreUsers` paginates, so a
        // stale write here would make the winning search discard its own results and would
        // paginate the wrong query.
        try Task.checkCancellation()
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
