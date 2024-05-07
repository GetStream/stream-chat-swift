//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat

@available(iOS 13.0, *)
extension ReactionListUpdater {
    func loadReactions(query: ReactionListQuery) async throws -> [ChatMessageReaction] {
        try await withCheckedThrowingContinuation { continuation in
            loadReactions(query: query) { completion in
                continuation.resume(with: completion)
            }
        }
    }
}
