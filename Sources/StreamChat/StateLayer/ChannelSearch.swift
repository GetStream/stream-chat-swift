//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// An object which represents a list of ``ChatChannel`` matching a channel name search.
///
/// Text searches are debounced: 500ms for 1-2 characters, 300ms for 3 or more. Calling
/// ``search(text:)`` or ``search(query:)`` again cancels the previous in-flight search. The
/// superseded call returns the current results rather than throwing, so typing does not surface
/// an error per keystroke.
///
/// Results are read from the local database, consistent with the other search APIs in the SDK.
///
/// - Note: For a delegate based alternative, please check ``ChatChannelSearchController``.
public class ChannelSearch: @unchecked Sendable {
    private let client: ChatClient
    private let channelListUpdater: ChannelListUpdater
    private let searchDebouncer: AsyncSearchDebouncer
    @MainActor private var stateBuilder: StateBuilder<ChannelSearchState>

    /// The local identity of the results this object observes.
    ///
    /// It is stable for the lifetime of the search, so consecutive searches replace each other in
    /// one place instead of leaving a query behind in the database per search text.
    private let explicitQueryHash = UUID().uuidString

    init(
        client: ChatClient,
        debouncePolicy: SearchDebouncePolicy = .default,
        environment: Environment = .init()
    ) {
        self.client = client
        channelListUpdater = environment.channelListUpdaterBuilder(
            client.databaseContainer,
            client.apiClient
        )
        searchDebouncer = AsyncSearchDebouncer(policy: debouncePolicy)
        stateBuilder = StateBuilder { environment.stateBuilder(client.databaseContainer, client.config) }
    }

    deinit {
        let query = ChannelListQuery.searchResults(explicitQueryHash: explicitQueryHash)
        channelListUpdater.deleteSearchQuery(query) { _ in }
    }

    // MARK: - Accessing the State

    /// An observable object representing the current state of the search.
    @MainActor public var state: ChannelSearchState { stateBuilder.state }

    // MARK: - Search Results and Pagination

    /// Searches for channels whose name matches the given text and updates ``ChannelSearchState/channels``.
    ///
    /// Passing empty text clears the results.
    ///
    /// - Parameter text: The channel name search text.
    ///
    /// - Throws: An error while communicating with the Stream API.
    /// - Returns: An array of channels matching the search text. When a newer search supersedes
    /// this one, the current ``ChannelSearchState/channels`` are returned.
    @discardableResult public func search(text: String) async throws -> [ChatChannel] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            await searchDebouncer.cancel()
            try await clearResults()
            return []
        }

        guard let currentUserId = client.currentUserId else {
            throw ClientError.CurrentUserDoesNotExist("For channel search, a current user must be logged in")
        }

        return try await search(query: makeQuery(text: trimmed, currentUserId: currentUserId))
    }

    /// Searches for channels with the specified query and updates ``ChannelSearchState/channels``.
    ///
    /// - Parameter query: The channel list query used for searching.
    ///
    /// - Note: A query built around a text-search operator (`.autocomplete`, `.queryText`) is
    /// debounced on the length of that text, even when combined with other filters. A query
    /// with no search text is not typed character by character, so it runs right away — a
    /// later search still cancels it either way.
    ///
    /// - Throws: An error while communicating with the Stream API.
    /// - Returns: An array of channels matching the query. When a newer search supersedes this
    /// one, the current ``ChannelSearchState/channels`` are returned.
    @discardableResult public func search(query: ChannelListQuery) async throws -> [ChatChannel] {
        var preparedQuery = prepareSearchQuery(query)
        preparedQuery.pagination = Pagination(pageSize: preparedQuery.pagination.pageSize, offset: 0)
        let searchQuery = preparedQuery

        let result = try await searchDebouncer.schedule(filter: searchQuery.filter) { [weak self] in
            guard let self else { throw ClientError("ChannelSearch was deallocated") }
            return try await self.performSearch(query: searchQuery)
        }
        if let result {
            return result
        }
        return await state.channels
    }

    /// Loads more channels for the last search and updates ``ChannelSearchState/channels``.
    ///
    /// - Parameter limit: The limit for the page size.
    ///
    /// - Throws: An error while communicating with the Stream API.
    /// - Returns: The next page of channels matching the last search. A page smaller than the
    /// limit means the last page has been loaded.
    @discardableResult public func loadMoreChannels(limit: Int? = nil) async throws -> [ChatChannel] {
        guard let query = await state.query else {
            throw ClientError("Call search() before calling for next page")
        }
        var nextPageQuery = query
        nextPageQuery.pagination = Pagination(
            pageSize: limit ?? query.pagination.pageSize,
            offset: await state.channels.count
        )
        let result = try await channelListUpdater.update(channelListQuery: nextPageQuery)
        try Task.checkCancellation()
        return result.channels
    }

    // MARK: - Private

    private func makeQuery(text: String, currentUserId: UserId) -> ChannelListQuery {
        var query = ChannelListQuery(
            filter: .and([
                .autocomplete(.name, text: text),
                .containMembers(userIds: [currentUserId])
            ])
        )
        // Do not start watching any of the searched channels.
        query.options = []
        return query
    }

    private func prepareSearchQuery(_ query: ChannelListQuery) -> ChannelListQuery {
        var query = query
        query.explicitQueryHash = explicitQueryHash
        // Searched channels must not be watched.
        query.options = []
        return query
    }

    private func performSearch(query: ChannelListQuery) async throws -> [ChatChannel] {
        // A superseded search must not publish its query: `state.query` is what the observer
        // follows and what pagination continues from.
        try Task.checkCancellation()
        await state.setQuery(query)
        let result = try await channelListUpdater.update(channelListQuery: query)
        try Task.checkCancellation()
        return result.channels
    }

    private func clearResults() async throws {
        let query = ChannelListQuery.searchResults(explicitQueryHash: explicitQueryHash)
        try await channelListUpdater.clearSearchResults(for: query)
        await state.clear()
    }
}

extension ChannelSearch {
    struct Environment: Sendable {
        var channelListUpdaterBuilder: @Sendable (
            _ database: DatabaseContainer,
            _ apiClient: APIClient
        ) -> ChannelListUpdater = {
            ChannelListUpdater(database: $0, apiClient: $1)
        }

        var stateBuilder: @Sendable @MainActor (
            _ database: DatabaseContainer,
            _ clientConfig: ChatClientConfig
        ) -> ChannelSearchState = { @MainActor in
            ChannelSearchState(database: $0, clientConfig: $1)
        }
    }
}
