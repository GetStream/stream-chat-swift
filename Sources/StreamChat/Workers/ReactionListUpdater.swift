//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import CoreData

class ReactionListUpdater: Worker, @unchecked Sendable {
    func loadReactions(
        query: ReactionListQuery,
        completion: @escaping @Sendable(Result<[ChatMessageReaction], Error>) -> Void
    ) {
        apiClient.request(
            endpoint: .loadReactionsV2(query: query)
        ) { [weak self] (result: Result<MessageReactionsPayload, Error>) in
            switch result {
            case let .success(payload):
                self?.database.write(converting: { session in
                    try session.saveReactions(payload: payload, query: query).map { try $0.asModel() }
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
