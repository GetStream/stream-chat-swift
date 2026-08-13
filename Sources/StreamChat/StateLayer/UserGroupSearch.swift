//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// An object which represents a list of `UserGroup` for the specified search query.
///
/// Text searches are debounced: 500ms for 1-2 characters, 300ms for 3 or more.
/// Calling ``search(text:teamId:)`` or ``search(query:)`` again cancels the previous
/// in-flight search. The superseded call returns the current results rather than throwing,
/// so typing does not surface an error per keystroke.
///
/// Search results are kept in ``UserGroupSearchState`` and replaced on every new search.
///
/// - Note: For a delegate based alternative, please check ``UserGroupSearchController``.
public class UserGroupSearch: @unchecked Sendable {
    @MainActor private var stateBuilder: StateBuilder<UserGroupSearchState>
    private let userGroupsRepository: UserGroupsRepository
    private let searchDebouncer: AsyncSearchDebouncer

    init(
        client: ChatClient,
        debouncePolicy: SearchDebouncePolicy = .default
    ) {
        userGroupsRepository = client.userGroupsRepository
        searchDebouncer = AsyncSearchDebouncer(policy: debouncePolicy)
        stateBuilder = StateBuilder { UserGroupSearchState() }
    }

    // MARK: - Accessing the State

    /// An observable object representing the current state of the search.
    @MainActor public var state: UserGroupSearchState { stateBuilder.state }

    // MARK: - Search Results

    /// Searches for user groups with the specified search term and updates ``UserGroupSearchState/userGroups``.
    ///
    /// - Parameters:
    ///   - text: The search term used to match group names.
    ///   - teamId: When set, restricts the search to groups scoped to the given team.
    ///
    /// - Throws: An error while communicating with the Stream API.
    /// - Returns: An array of user groups for the search term. When a newer search supersedes
    /// this one, the current ``UserGroupSearchState/userGroups`` are returned.
    @discardableResult public func search(text: String, teamId: String? = nil) async throws -> [UserGroup] {
        try await search(query: UserGroupSearchQuery(query: text, teamId: teamId))
    }

    /// Searches for user groups with the specified query and updates ``UserGroupSearchState/userGroups``.
    ///
    /// - Parameter query: The query describing the search term and filters.
    ///
    /// - Note: Searches are debounced on the length of ``UserGroupSearchQuery/query``.
    ///
    /// - Throws: An error while communicating with the Stream API.
    /// - Returns: An array of user groups for the query. When a newer search supersedes this
    /// one, the current ``UserGroupSearchState/userGroups`` are returned.
    @discardableResult public func search(query: UserGroupSearchQuery) async throws -> [UserGroup] {
        let result = try await searchDebouncer.schedule(queryLength: query.query.count) { [weak self] in
            guard let self else { throw ClientError("UserGroupSearch was deallocated") }
            return try await self.performSearch(query: query)
        }
        if let result {
            return result
        }
        return await state.userGroups
    }

    /// Cancels any pending or in-flight search and clears ``UserGroupSearchState/userGroups``.
    public func clearResults() async {
        await searchDebouncer.cancel()
        await state.clear()
    }

    // MARK: - Private

    private func performSearch(query: UserGroupSearchQuery) async throws -> [UserGroup] {
        // A superseded search must not publish its query. `state.query` is what
        // `handleDidFetchQuery` compares against, so a stale write here would make the
        // winning search discard its own results.
        try Task.checkCancellation()
        await state.setQuery(query)
        let userGroups = try await userGroupsRepository.searchUserGroups(query: query)
        try Task.checkCancellation()
        await state.handleDidFetchQuery(query, userGroups: userGroups)
        return userGroups
    }
}
