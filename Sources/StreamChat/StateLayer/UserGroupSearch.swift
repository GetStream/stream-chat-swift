//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// An object which represents a list of `UserGroup` for the specified search query.
///
/// Search results are kept in ``UserGroupSearchState`` and replaced on every new search.
public class UserGroupSearch: @unchecked Sendable {
    @MainActor private var stateBuilder: StateBuilder<UserGroupSearchState>
    private let userGroupsRepository: UserGroupsRepository

    init(client: ChatClient) {
        userGroupsRepository = client.userGroupsRepository
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
    /// - Returns: An array of user groups for the search term.
    @discardableResult public func search(text: String, teamId: String? = nil) async throws -> [UserGroup] {
        try await search(query: UserGroupSearchQuery(query: text, teamId: teamId))
    }

    /// Searches for user groups with the specified query and updates ``UserGroupSearchState/userGroups``.
    ///
    /// - Parameter query: The query describing the search term and filters.
    ///
    /// - Throws: An error while communicating with the Stream API.
    /// - Returns: An array of user groups for the query.
    @discardableResult public func search(query: UserGroupSearchQuery) async throws -> [UserGroup] {
        await state.setQuery(query)
        let userGroups = try await userGroupsRepository.searchUserGroups(query: query)
        await state.handleDidFetchQuery(query, userGroups: userGroups)
        return userGroups
    }
}
