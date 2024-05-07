//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat

@available(iOS 13.0, *)
extension ReactionListState {
    struct Observer {
        private let reactionListObserver: StateLayerDatabaseObserver<ListResult, ChatMessageReaction, MessageReactionDTO>
        
        init(query: ReactionListQuery, database: DatabaseContainer) {
            reactionListObserver = StateLayerDatabaseObserver(
                databaseContainer: database,
                fetchRequest: MessageReactionDTO.reactionListFetchRequest(query: query),
                itemCreator: { try $0.asModel() }
            )
        }
        
        struct Handlers {
            let reactionsDidChange: (StreamCollection<ChatMessageReaction>) async -> Void
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
