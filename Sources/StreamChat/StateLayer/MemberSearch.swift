//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// An object which represents a list of `ChatChannelMember` for the specified search query.
///
/// Text searches are debounced: 500ms for 1-2 characters, 300ms for 3 or more.
/// Calling ``search(text:in:)`` or ``search(query:)`` again cancels the previous in-flight search.
///
/// - Note: For a fixed query without debounce, use ``MemberList``.
public class MemberSearch: @unchecked Sendable {
    @MainActor private var stateBuilder: StateBuilder<MemberSearchState>
    private let memberListUpdater: ChannelMemberListUpdater
    private let searchDebouncer: AsyncSearchDebouncer

    init(
        client: ChatClient,
        environment: Environment = .init(),
        debouncePolicy: SearchDebouncePolicy = .default
    ) {
        memberListUpdater = environment.memberListUpdaterBuilder(
            client.databaseContainer,
            client.apiClient
        )
        searchDebouncer = AsyncSearchDebouncer(policy: debouncePolicy)
        stateBuilder = StateBuilder { MemberSearchState() }
    }

    // MARK: - Accessing the State

    /// An observable object representing the current state of the search.
    @MainActor public var state: MemberSearchState { stateBuilder.state }

    // MARK: - Search Results and Pagination

    /// Searches for channel members whose name matches the given text and updates ``MemberSearchState/members``.
    ///
    /// - Parameters:
    ///   - text: The member name search text.
    ///   - cid: The channel to search members in.
    ///
    /// - Throws: An error while communicating with the Stream API.
    /// - Returns: An array of members matching the search text. When a newer search supersedes
    /// this one, the current ``MemberSearchState/members`` are returned.
    @discardableResult public func search(text: String, in cid: ChannelId) async throws -> [ChatChannelMember] {
        try await search(
            query: ChannelMemberListQuery(
                cid: cid,
                filter: .autocomplete(.name, text: text),
                sort: [.init(key: .name, isAscending: true)]
            )
        )
    }

    /// Searches for channel members with the specified query and updates ``MemberSearchState/members``.
    ///
    /// - Parameter query: The channel member list query used for searching.
    ///
    /// - Note: A query built around a text-search operator (`.autocomplete`, `.query`) is
    /// debounced on the length of that text, even when combined with other filters. A query
    /// with no search text is not typed character by character, so it runs right away — a
    /// later search still cancels it either way.
    ///
    /// - Throws: An error while communicating with the Stream API.
    /// - Returns: An array of members for the query. When a newer search supersedes this one,
    /// the current ``MemberSearchState/members`` are returned.
    @discardableResult public func search(query: ChannelMemberListQuery) async throws -> [ChatChannelMember] {
        let pagination = Pagination(pageSize: query.pagination.pageSize, offset: 0)
        let result = try await searchDebouncer.schedule(filter: query.filter) { [weak self] in
            guard let self else { throw ClientError("MemberSearch was deallocated") }
            return try await self.performSearch(query: query, pagination: pagination)
        }
        if let result {
            return result
        }
        return await state.members
    }

    /// Loads more members for the last search and updates ``MemberSearchState/members``.
    ///
    /// - Parameter limit: The limit for the page size. The default limit is 30.
    ///
    /// - Throws: An error while communicating with the Stream API.
    /// - Returns: An array of loaded members.
    @discardableResult public func loadMoreMembers(limit: Int? = nil) async throws -> [ChatChannelMember] {
        guard let query = await state.query else {
            throw ClientError("Call search() before calling for next page")
        }
        let limit = limit ?? query.pagination.pageSize
        let offset = await state.members.count
        let pagination = Pagination(pageSize: limit, offset: offset)
        return try await performSearch(query: query, pagination: pagination)
    }

    // MARK: - Private

    private func performSearch(
        query: ChannelMemberListQuery,
        pagination: Pagination
    ) async throws -> [ChatChannelMember] {
        let query = query.withPagination(pagination)
        // A superseded search must not publish its query. `state.query` is what
        // `handleDidFetchQuery` compares against and what `loadMoreMembers` paginates, so a
        // stale write here would make the winning search discard its own results and would
        // paginate the wrong query.
        try Task.checkCancellation()
        await state.setQuery(query)
        let members = try await memberListUpdater.load(query)
        try Task.checkCancellation()
        await state.handleDidFetchQuery(query, members: members)
        return members
    }
}

extension MemberSearch {
    struct Environment {
        var memberListUpdaterBuilder: (
            _ database: DatabaseContainer,
            _ apiClient: APIClient
        ) -> ChannelMemberListUpdater = {
            ChannelMemberListUpdater(database: $0, apiClient: $1)
        }
    }
}
