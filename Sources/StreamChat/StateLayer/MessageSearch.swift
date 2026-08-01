//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// An object which represents a list of ``ChatMessage`` for the specified search query.
///
/// Search requests are debounced according to ``debouncePolicy``.
/// Calling ``search(text:sort:)`` or ``search(query:)`` again cancels the previous in-flight search.
public class MessageSearch: @unchecked Sendable {
    private let authenticationRepository: AuthenticationRepository
    private let messageUpdater: MessageUpdater
    /// The debounce policy used for search requests.
    ///
    /// Defaults to ``SearchDebouncePolicy/default`` (500ms for 1–2 characters, 300ms for 3+).
    var debouncePolicy: SearchDebouncePolicy = .default
    @MainActor private var stateBuilder: StateBuilder<MessageSearchState>
    private var searchTask: Task<[ChatMessage], Error>?
    let explicitFilterHash = UUID().uuidString
    
    init(client: ChatClient, environment: Environment = .init()) {
        authenticationRepository = client.authenticationRepository
        messageUpdater = environment.messageUpdaterBuilder(
            client.config.isLocalStorageEnabled,
            client.messageRepository,
            client.databaseContainer,
            client.apiClient
        )
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
            searchTask?.cancel()
            searchTask = nil
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
    /// - Throws: An error while communicating with the Stream API. Throws `CancellationError` when superseded by a newer search.
    /// - Returns: An array of paginated chat messages matching to the query.
    @discardableResult public func search(query: MessageSearchQuery) async throws -> [ChatMessage] {
        try await search(
            query: query,
            queryLength: SearchQueryLength.fromFilter(query.messageFilter)
        )
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
        searchTask?.cancel()
        guard debouncePolicy.shouldPerformSearch(forQueryLength: queryLength) else {
            searchTask = nil
            return await state.messages
        }

        let debouncePolicy = debouncePolicy
        let filterHash = explicitFilterHash
        let task = Task { [weak self, debouncePolicy, filterHash] in
            guard let self else { throw ClientError("MessageSearch was deallocated") }
            let interval = debouncePolicy.interval(forQueryLength: queryLength)
            if interval > 0 {
                try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            }
            try Task.checkCancellation()

            var query = query
            query.filterHash = filterHash
            let result = try await self.messageUpdater.search(query: query, policy: .replace)
            try Task.checkCancellation()
            await self.state.set(query: query, cursor: result.payload.next)
            return result.models
        }
        searchTask = task
        return try await task.value
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
