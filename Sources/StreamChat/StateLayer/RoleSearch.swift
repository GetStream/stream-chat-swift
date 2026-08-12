//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// An object which represents a list of `Role` for the specified search query.
///
/// Text searches are debounced: 500ms for 1-2 characters, 300ms for 3 or more.
/// Calling ``search(text:roleType:)`` or ``search(query:)`` again cancels the previous
/// in-flight search. The superseded call returns the current results rather than throwing,
/// so typing does not surface an error per keystroke.
///
/// Results are kept in ``RoleSearchState`` and replaced on every new search.
public class RoleSearch: @unchecked Sendable {
    @MainActor private var stateBuilder: StateBuilder<RoleSearchState>
    private let rolesRepository: RolesRepository
    private let searchDebouncer: AsyncSearchDebouncer

    init(
        client: ChatClient,
        debouncePolicy: SearchDebouncePolicy = .default
    ) {
        rolesRepository = client.rolesRepository
        searchDebouncer = AsyncSearchDebouncer(policy: debouncePolicy)
        stateBuilder = StateBuilder { RoleSearchState() }
    }

    // MARK: - Accessing the State

    /// An observable object representing the current state of the search.
    @MainActor public var state: RoleSearchState { stateBuilder.state }

    // MARK: - Search Results

    /// Searches for roles with the specified search term and updates ``RoleSearchState/roles``.
    ///
    /// - Parameters:
    ///   - text: The search term used to match role names.
    ///   - roleType: When set, restricts the search to roles of the given type.
    ///
    /// - Throws: An error while communicating with the Stream API.
    /// - Returns: An array of roles for the search term. When a newer search supersedes this
    /// one, the current ``RoleSearchState/roles`` are returned.
    @discardableResult public func search(text: String, roleType: RoleType? = nil) async throws -> [Role] {
        try await search(query: RoleSearchQuery(query: text, roleType: roleType))
    }

    /// Searches for roles with the specified query and updates ``RoleSearchState/roles``.
    ///
    /// - Parameter query: The query describing the search term and filters.
    ///
    /// - Note: Searches are debounced on the length of ``RoleSearchQuery/query``.
    ///
    /// - Throws: An error while communicating with the Stream API.
    /// - Returns: An array of roles for the query. When a newer search supersedes this one,
    /// the current ``RoleSearchState/roles`` are returned.
    @discardableResult public func search(query: RoleSearchQuery) async throws -> [Role] {
        let result = try await searchDebouncer.schedule(queryLength: query.query.count) { [weak self] in
            guard let self else { throw ClientError("RoleSearch was deallocated") }
            return try await self.performSearch(query: query)
        }
        if let result {
            return result
        }
        return await state.roles
    }

    /// Cancels any pending or in-flight search and clears ``RoleSearchState/roles``.
    public func clearResults() async {
        await searchDebouncer.cancel()
        await state.clear()
    }

    // MARK: - Private

    private func performSearch(query: RoleSearchQuery) async throws -> [Role] {
        // A superseded search must not publish its query. `state.query` is what
        // `handleDidFetchQuery` compares against, so a stale write here would make the
        // winning search discard its own results.
        try Task.checkCancellation()
        await state.setQuery(query)
        let roles = try await rolesRepository.searchRoles(query: query)
        try Task.checkCancellation()
        await state.handleDidFetchQuery(query, roles: roles)
        return roles
    }
}
