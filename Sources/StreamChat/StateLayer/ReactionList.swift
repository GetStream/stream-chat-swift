//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// An object which represents a list of `ChatMessageReaction` for the specified query.
public final class ReactionList {
    private let query: ReactionListQuery
    private let reactionListUpdater: ReactionListUpdater
    private let stateBuilder: StateBuilder<ReactionListState>
    
    init(query: ReactionListQuery, client: ChatClient, environment: Environment = .init()) {
        self.query = query
        reactionListUpdater = environment.reactionListUpdaterBuilder(
            client.databaseContainer,
            client.apiClient
        )
        stateBuilder = StateBuilder {
            environment.stateBuilder(
                query,
                client.databaseContainer
            )
        }
    }
    
    // MARK: - Accessing the State
    
    /// An observable object representing the current state of the reaction list.
    @MainActor public lazy var state: ReactionListState = stateBuilder.build()
    
    /// Fetches the most recent state from the server and updates the local store.
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func get() async throws {
        let pagination = Pagination(pageSize: query.pagination.pageSize)
        try await loadReactions(with: pagination)
    }
    
    // MARK: - Reactions Pagination
    
    /// Loads reactions for the specified pagination parameters and updates ``ReactionListState/reactions``.
    ///
    /// - Parameter pagination: The pagination configuration which includes a limit and an offset or a cursor.
    ///
    /// - Throws: An error while communicating with the Stream API.
    /// - Returns: An array of message reaction for the pagination.
    @discardableResult public func loadReactions(with pagination: Pagination) async throws -> [ChatMessageReaction] {
        let query = query.withPagination(pagination)
        return try await reactionListUpdater.loadReactions(query: query)
    }
    
    /// Loads more message reactions and updates ``MemberListState/members``.
    ///
    /// - Parameters
    ///   - limit: The limit for the page size. The default limit is 25.
    ///
    /// - Throws: An error while communicating with the Stream API.
    /// - Returns: An array of message reactions.
    @discardableResult public func loadMoreReactions(limit: Int? = nil) async throws -> [ChatMessageReaction] {
        let pageSize = limit ?? query.pagination.pageSize
        let pagination = Pagination(
            pageSize: pageSize,
            offset: await state.reactions.count
        )
        return try await loadReactions(with: pagination)
    }
}

extension ReactionList {
    struct Environment {
        var reactionListUpdaterBuilder: (
            _ database: DatabaseContainer,
            _ apiClient: APIClient
        ) -> ReactionListUpdater = ReactionListUpdater.init
        
        var stateBuilder: @MainActor(
            _ query: ReactionListQuery,
            _ database: DatabaseContainer
        ) -> ReactionListState = { @MainActor in
            ReactionListState(query: $0, database: $1)
        }
    }
}

private extension ReactionListQuery {
    func withPagination(_ pagination: Pagination) -> Self {
        var result = self
        result.pagination = pagination
        return result
    }
}
