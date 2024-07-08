//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// An object which represents a list of ``ChatMessage`` for the specified search query.
public class MessageSearch {
    private let authenticationRepository: AuthenticationRepository
    private let messageUpdater: MessageUpdater
    private let stateBuilder: StateBuilder<MessageSearchState>
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
    @MainActor public lazy var state: MessageSearchState = stateBuilder.build()
    
    // MARK: - Search Results and Pagination
    
    /// Searches for messages with the specified full text search text and updates ``MessageSearchState/messages``.
    ///
    /// - Parameter text: A string to search for (which is a full text search).
    ///
    /// - Throws: An error while communicating with the Stream API.
    /// - Returns: An array of paginated chat messages matching to the search term.
    @discardableResult public func search(text: String) async throws -> [ChatMessage] {
        // Clear results when there is no text
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           let query = await state.query {
            try await messageUpdater.clearSearchResults(for: query)
            await state.set(query: nil, cursor: nil)
            return []
        }
        
        let currentUserId = try currentUserId()
        let query = MessageSearchQuery(
            channelFilter: .containMembers(userIds: [currentUserId]),
            messageFilter: .autocomplete(.text, text: text),
            sort: [.init(key: .createdAt, isAscending: false)]
        )
        return try await search(query: query)
    }
    
    /// Searches for messages with the specified query and updates ``MessageSearchState/messages``.
    ///
    /// - Parameter query: The search query specifying filters, sorting and pagination.
    ///
    /// - Throws: An error while communicating with the Stream API.
    /// - Returns: An array of paginated chat messages matching to the query.
    @discardableResult public func search(query: MessageSearchQuery) async throws -> [ChatMessage] {
        var query = query
        query.filterHash = explicitFilterHash
        let result = try await messageUpdater.search(query: query, policy: .replace)
        await state.set(query: query, cursor: result.payload.next)
        return result.models
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
    
    private func currentUserId() throws -> UserId {
        guard let id = authenticationRepository.currentUserId else { throw ClientError.CurrentUserDoesNotExist() }
        return id
    }
}

extension MessageSearch {
    struct Environment {
        var messageUpdaterBuilder: (
            _ isLocalStorageEnabled: Bool,
            _ messageRepository: MessageRepository,
            _ database: DatabaseContainer,
            _ apiClient: APIClient
        ) -> MessageUpdater = MessageUpdater.init
        
        var stateBuilder: @MainActor(
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
