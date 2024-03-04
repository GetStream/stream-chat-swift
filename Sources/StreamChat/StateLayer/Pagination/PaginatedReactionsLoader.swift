//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// Loads paginated reactions for messages.
@available(iOS 13.0, *)
struct PaginatedReactionsLoader {
    let cid: ChannelId
    let messageUpdater: MessageUpdater
    
    func loadReactions(to state: MessageState?, cid: ChannelId, messageId: MessageId, pagination: Pagination) async throws -> [ChatMessageReaction] {
        let newSortedReactions = try await messageUpdater.loadReactions(cid: cid, messageId: messageId, pagination: pagination)
            .sort(using: [.init(keyPath: \.updatedAt, isAscending: false)])
        
        if let state {
            await insertNewReactions(newSortedReactions, to: state)
        }
        
        return newSortedReactions
    }
    
    private func insertNewReactions(_ newReactions: [ChatMessageReaction], to state: MessageState) async {
        let currentReactions = await state.value(forKeyPath: \.reactions)
        let result = currentReactions.uniquelyMerged(
            newReactions,
            
            areInIncreasingOrder: { first, second in
                first.updatedAt > second.updatedAt
            },
            
            dropsExisting: { first, second in
                first.author == second.author && first.type == second.type
            }
        )
        await state.setSortedReactions(result)
    }
}