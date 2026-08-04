//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// An object which represents a list of ``ChatChannel`` matching a channel name search.
///
/// Text searches are debounced: 500ms for 1-2 characters, 300ms for 3 or more. Calling
/// ``search(text:)`` again cancels the previous in-flight search. The superseded call returns
/// the current results rather than throwing, so typing does not surface an error per keystroke.
///
/// - Note: For a delegate based alternative, please check ``ChatChannelSearchController``.
public class ChannelSearch: @unchecked Sendable {
    private let client: ChatClient
    private let environment: Environment
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
        self.environment = environment
        searchDebouncer = AsyncSearchDebouncer(policy: debouncePolicy)
        stateBuilder = StateBuilder { ChannelSearchState() }
    }

    deinit {
        let query = ChannelListQuery.searchResults(explicitQueryHash: explicitQueryHash)
        client.databaseContainer.write { session in
            session.delete(query: query)
        }
    }

    // MARK: - Accessing the State

    /// An observable object representing the current state of the search.
    @MainActor public var state: ChannelSearchState { stateBuilder.state }

    // MARK: - Search Results and Pagination

    /// Searches for channels whose name matches the given text and updates ``ChannelSearchState/channels``.
    ///
    /// Passing empty text cancels any pending search and clears the results.
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
            await state.clear()
            return []
        }

        guard let currentUserId = client.currentUserId else {
            throw ClientError.CurrentUserDoesNotExist("For channel search, a current user must be logged in")
        }

        let query = makeQuery(text: trimmed, currentUserId: currentUserId)
        let result = try await searchDebouncer.schedule(queryLength: trimmed.count) { [weak self] in
            guard let self else { throw ClientError("ChannelSearch was deallocated") }
            return try await self.performSearch(query: query)
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
    /// - Returns: The full list of loaded channels, including the new page.
    @discardableResult public func loadMoreChannels(limit: Int? = nil) async throws -> [ChatChannel] {
        guard let channelList = await state.channelList, let query = await state.query else {
            throw ClientError("Call search() before calling for next page")
        }
        try await channelList.loadMoreChannels(limit: limit)
        try Task.checkCancellation()
        let channels = await channelList.state.channels
        await state.handleDidLoadMore(query, channels: channels)
        return channels
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
        query.explicitQueryHash = explicitQueryHash
        return query
    }

    private func performSearch(query: ChannelListQuery) async throws -> [ChatChannel] {
        // A superseded search must not publish its query: `state.query` is what the result
        // handlers compare against and what pagination continues from.
        try Task.checkCancellation()
        await state.setQuery(query)
        let channelList = environment.channelListBuilder(query, client)
        try await channelList.get()
        try Task.checkCancellation()
        let channels = await channelList.state.channels
        await state.handleDidFetchQuery(query, channelList: channelList, channels: channels)
        return channels
    }
}

extension ChannelSearch {
    struct Environment {
        var channelListBuilder: (
            _ query: ChannelListQuery,
            _ client: ChatClient
        ) -> ChannelList = { query, client in
            client.makeChannelList(with: query)
        }
    }
}
