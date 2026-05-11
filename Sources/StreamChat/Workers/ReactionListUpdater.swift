//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreData

class ReactionListUpdater: Worker, @unchecked Sendable {
    func loadReactions(
        query: ReactionListQuery,
        completion: @escaping @Sendable (Result<[ChatMessageReaction], Error>) -> Void
    ) {
        let filter = query.filter?.toRawJSONDictionary() ?? [:]
        let request = QueryReactionsRequest(
            filter: filter.isEmpty ? nil : filter,
            limit: query.pagination.pageSize,
            next: nil,
            prev: nil,
            sort: nil
        )
        apiClient.request(
            endpoint: Endpoint<QueryReactionsResponse>.queryReactions(
                id: query.messageId,
                queryReactionsRequest: request
            )
        ) { [weak self] (result: Result<QueryReactionsResponse, Error>) in
            switch result {
            case let .success(payload):
                let reactionsPayload = GetReactionsResponse(duration: payload.duration, reactions: payload.reactions)
                self?.database.write(converting: { session in
                    try session.saveReactions(payload: reactionsPayload, query: query).map { try $0.asModel() }
                }, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
    
    func loadReactions(query: ReactionListQuery) async throws -> [ChatMessageReaction] {
        try await withCheckedThrowingContinuation { continuation in
            loadReactions(query: query) { completion in
                continuation.resume(with: completion)
            }
        }
    }
}
