//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// An object which represents a list of ``ChatMessage`` for the specified search query.
///
/// Text searches are debounced: 500ms for 1-2 characters, 300ms for 3 or more.
/// Calling ``search(text:sort:)`` or ``search(query:)`` again cancels the previous in-flight search.
public class MessageSearch: @unchecked Sendable {
    private let authenticationRepository: AuthenticationRepository
    private let messageUpdater: MessageUpdater
    private let searchDebouncer: AsyncSearchDebouncer
    @MainActor private var stateBuilder: StateBuilder<MessageSearchState>
    let explicitFilterHash = UUID().uuidString

    init(
        client: ChatClient,
        environment: Environment = .init(),
        debouncePolicy: SearchDebouncePolicy = .default
    ) {
        authenticationRepository = client.authenticationRepository
        messageUpdater = environment.messageUpdaterBuilder(
            client.config.isLocalStorageEnabled,
            client.messageRepository,
            client.databaseContainer,
            client.apiClient
        )
        searchDebouncer = AsyncSearchDebouncer(policy: debouncePolicy)
        stateBuilder = StateBuilder { environment.stateBuilder(client.databaseContainer) }
    }
    
    // MARK: - Accessing the State
    
    /// An observable object representing the current state of the search.
    @MainActor public var state: MessageSearchState { stateBuilder.state }
    
    // MARK: - Search Results and Pagination
    
    /// Searches for messages with the specified full text search text and updates ``MessageSearchState/messages``.
    ///
    /// - Parameters:
    ///   - text: A string to search for (which is a full text search).
    ///   - sort: Optional sort order for search results. When `nil`, defaults to newest first (createdAt descending).
    ///
    /// - Throws: An error while communicating with the Stream API. Throws `CancellationError` when superseded by a newer search.
    /// - Returns: An array of paginated chat messages matching to the search term.
    @discardableResult public func search(text: String, sort: [Sorting<MessageSearchSortingKey>]? = nil) async throws -> [ChatMessage] {
        // Clear results when there is no text
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            await searchDebouncer.cancel()
            if let query = await state.query {
                try await messageUpdater.clearSearchResults(for: query)
                await state.set(query: nil, cursor: nil)
            }
            return []
        }

        let currentUserId = try currentUserId()
        let sortOrder = sort ?? [.init(key: .createdAt, isAscending: false)]
        let query = MessageSearchQuery(
            channelFilter: .containMembers(userIds: [currentUserId]),
            messageFilter: .autocomplete(.text, text: text),
            sort: sortOrder
        )
        return try await search(query: query, queryLength: text.count)
    }
    
    /// Searches for messages with the specified query and updates ``MessageSearchState/messages``.
    ///
    /// - Parameter query: The search query specifying filters, sorting and pagination.
    ///
    /// - Note: A query built around a text-search operator (`.autocomplete`, `.queryText`) is
    /// debounced on the length of that text, even when combined with other filters. A query
    /// with no search text is not typed character by character, so it runs right away — a
    /// later search still cancels it either way.
    ///
    /// - Throws: An error while communicating with the Stream API. Throws `CancellationError` when superseded by a newer search.
    /// - Returns: An array of paginated chat messages matching to the query.
    @discardableResult public func search(query: MessageSearchQuery) async throws -> [ChatMessage] {
        if let queryLength = SearchQueryLength.fromFilter(query.messageFilter) {
            return try await search(query: query, queryLength: queryLength)
        }
        return try await searchDebouncer.perform { [weak self] in
            guard let self else { throw ClientError("MessageSearch was deallocated") }
            return try await self.performSearch(query: query)
        }
    }
    
    /// Searches for more messages matching with the last search query.
    ///
    /// - Parameter limit: The limit for the page size. The default limit is 25.
    ///
    /// - Throws: An error while communicating with the Stream API.
    /// - Returns: A next page of chat messages matching to the last query.
    @discardableResult public func loadMoreMessages(limit: Int? = nil) async throws -> [ChatMessage] {
        guard let query = await state.query else { throw ClientError("Call search() before calling for next page") }
        let limit = (limit ?? query.pagination?.pageSize) ?? Int.messagesPageSize
        let pagination: Pagination = await {
            if !query.sort.isEmpty, let nextPageCursor = await state.nextPageCursor {
                return Pagination(pageSize: limit, cursor: nextPageCursor)
            } else {
                return Pagination(pageSize: limit, offset: await state.messages.count)
            }
        }()
        let result = try await messageUpdater.search(
            query: query.withPagination(pagination),
            policy: .merge
        )
        await state.set(query: query, cursor: result.payload.next)
        return result.models
    }
    
    // MARK: - Private

    private func search(query: MessageSearchQuery, queryLength: Int) async throws -> [ChatMessage] {
        let result = try await searchDebouncer.schedule(queryLength: queryLength) { [weak self] in
            guard let self else { throw ClientError("MessageSearch was deallocated") }
            return try await self.performSearch(query: query)
        }
        if let result {
            return result
        }
        return await state.messages
    }

    private func performSearch(query: MessageSearchQuery) async throws -> [ChatMessage] {
        var query = query
        query.filterHash = explicitFilterHash
        let result = try await messageUpdater.search(query: query, policy: .replace)
        try Task.checkCancellation()
        await state.set(query: query, cursor: result.payload.next)
        return result.models
    }
    
    private func currentUserId() throws -> UserId {
        guard let id = authenticationRepository.currentUserId else { throw ClientError.CurrentUserDoesNotExist() }
        return id
    }
}

extension MessageSearch {
    struct Environment: Sendable {
        var messageUpdaterBuilder: @Sendable (
            _ isLocalStorageEnabled: Bool,
            _ messageRepository: MessageRepository,
            _ database: DatabaseContainer,
            _ apiClient: APIClient
        ) -> MessageUpdater = {
            MessageUpdater(
                isLocalStorageEnabled: $0,
                messageRepository: $1,
                database: $2,
                apiClient: $3
            )
        }
        
        var stateBuilder: @Sendable @MainActor (
            _ database: DatabaseContainer
        ) -> MessageSearchState = { @MainActor in
            MessageSearchState(database: $0)
        }
    }
}

private extension MessageSearchQuery {
    func withPagination(_ pagination: Pagination) -> Self {
        var result = self
        result.pagination = pagination
        return result
    }
}
