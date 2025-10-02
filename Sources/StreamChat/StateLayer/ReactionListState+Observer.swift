//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

extension ReactionListState {
    struct Observer {
        private let reactionListObserver: StateLayerDatabaseObserver<ListResult, ChatMessageReaction, MessageReactionDTO>
        
        init(query: ReactionListQuery, database: DatabaseContainer) {
            reactionListObserver = StateLayerDatabaseObserver(
                database: database,
                fetchRequest: MessageReactionDTO.reactionListFetchRequest(query: query),
                itemCreator: { try $0.asModel() },
                itemReuseKeyPaths: (\ChatMessageReaction.id, \MessageReactionDTO.id)
            )
        }
        
        struct Handlers {
            let reactionsDidChange: @Sendable @MainActor (StreamCollection<ChatMessageReaction>) async -> Void
        }
        
        func start(with handlers: Handlers) -> StreamCollection<ChatMessageReaction> {
            do {
                return try reactionListObserver.startObserving(didChange: handlers.reactionsDidChange)
            } catch {
                log.error("Failed to start the reaction list observer with error \(error)")
                return StreamCollection([])
            }
        }
    }
}
