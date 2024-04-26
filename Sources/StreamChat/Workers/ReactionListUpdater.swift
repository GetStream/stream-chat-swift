//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData

class ReactionListUpdater: Worker {
    func loadReactions(
        query: ReactionListQuery,
        for messageId: MessageId,
        completion: @escaping (Result<[ChatMessageReaction], Error>) -> Void
    ) {
        apiClient.request(
            endpoint: .loadReactionsV2(messageId: messageId, query: query)
        ) { [weak self] (result: Result<MessageReactionsPayload, Error>) in
            switch result {
            case let .success(payload):
                var reactions: [ChatMessageReaction] = []
                self?.database.write({ session in
                    reactions = try session.saveReactions(payload: payload).map { try $0.asModel() }
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
}
