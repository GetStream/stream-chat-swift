//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
extension MessageState {
    struct Observer {
        private let messageId: MessageId
        private let messageObserver: StateLayerDatabaseObserver<EntityResult, ChatMessage, MessageDTO>
        private let repliesObserver: StateLayerDatabaseObserver<ListResult, ChatMessage, MessageDTO>
        
        init(messageId: MessageId, messageOrder: MessageOrdering, database: DatabaseContainer, clientConfig: ChatClientConfig) {
            self.messageId = messageId
            messageObserver = StateLayerDatabaseObserver(
                databaseContainer: database,
                fetchRequest: MessageDTO.message(withID: messageId),
                itemCreator: { try $0.asModel() as ChatMessage }
            )
            repliesObserver = StateLayerDatabaseObserver(
                databaseContainer: database,
                fetchRequest: MessageDTO.repliesFetchRequest(
                    for: messageId,
                    pageSize: .messagesPageSize,
                    sortAscending: messageOrder.isAscending,
                    deletedMessagesVisibility: clientConfig.deletedMessagesVisibility,
                    shouldShowShadowedMessages: clientConfig.shouldShowShadowedMessages
                ),
                itemCreator: { try $0.asModel() as ChatMessage }
            )
        }
        
        struct Handlers {
            let messageDidChange: ((message: ChatMessage, changedReactions: [ChatMessageReaction]?)) async -> Void
            let repliesDidChange: (StreamCollection<ChatMessage>) async -> Void
        }
        
        func start(
            with handlers: Handlers
        ) -> (
            message: ChatMessage?,
            reactions: [ChatMessageReaction],
            replies: StreamCollection<ChatMessage>
        ) {
            do {
                var lastSortedReactions: [ChatMessageReaction]?
                let message = try messageObserver.startObserving(onContextDidChange: { message in
                    guard let message else { return }
                    let changedReactions: [ChatMessageReaction]?
                    let currentReactions = message.latestReactions.sorted(by: ChatMessageReaction.defaultSorting)
                    if lastSortedReactions != currentReactions {
                        lastSortedReactions = currentReactions
                        changedReactions = currentReactions
                    } else {
                        changedReactions = nil
                    }
                    Task.mainActor {
                        await handlers.messageDidChange((message, changedReactions))
                    }
                })
                let reactions = message?.latestReactions.sorted(by: ChatMessageReaction.defaultSorting) ?? []
                let replies = try repliesObserver.startObserving(didChange: handlers.repliesDidChange)
                return (message, reactions, replies)
            } catch {
                log.error("Failed to start the observers for message: \(messageId) with error \(error)")
                return (nil, [], StreamCollection([]))
            }
        }
    }
}
