//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// An object which represents a list of `Role` for the specified search query.
///
/// Results are kept in ``RoleSearchState`` and replaced on every new search.
public class RoleSearch: @unchecked Sendable {
    @MainActor private var stateBuilder: StateBuilder<RoleSearchState>
    private let rolesRepository: RolesRepository

    init(client: ChatClient) {
        rolesRepository = client.rolesRepository
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
    /// - Returns: An array of roles for the search term.
    @discardableResult public func search(text: String, roleType: RoleType? = nil) async throws -> [Role] {
        try await search(query: RoleSearchQuery(query: text, roleType: roleType))
    }

    /// Searches for roles with the specified query and updates ``RoleSearchState/roles``.
    ///
    /// - Parameter query: The query describing the search term and filters.
    ///
    /// - Throws: An error while communicating with the Stream API.
    /// - Returns: An array of roles for the query.
    @discardableResult public func search(query: RoleSearchQuery) async throws -> [Role] {
        await state.setQuery(query)
        let roles = try await rolesRepository.searchRoles(query: query)
        await state.handleDidFetchQuery(query, roles: roles)
        return roles
    }
}
