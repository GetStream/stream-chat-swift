//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData

class ReactionListUpdater: Worker {
    func loadReactions(
        query: ReactionListQuery,
        completion: @escaping (Result<[ChatMessageReaction], Error>) -> Void
    ) {
        apiClient.request(
            endpoint: .loadReactionsV2(query: query)
        ) { [weak self] (result: Result<MessageReactionsPayload, Error>) in
            switch result {
            case let .success(payload):
                var reactions: [ChatMessageReaction] = []
                self?.database.write({ session in
                    reactions = try session.saveReactions(payload: payload, query: query).map { try $0.asModel() }
                }, completion: { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(reactions))
                    }
                })
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
