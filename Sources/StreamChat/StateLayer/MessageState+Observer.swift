//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
extension MessageState {
    struct Observer {
        private let messageId: MessageId
        let messageObserver: StateLayerDatabaseObserver<EntityResult, ChatMessage, MessageDTO>
        let repliesObserver: StateLayerDatabaseObserver<ListResult, ChatMessage, MessageDTO>
        
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
                itemCreator: { try $0.asModel() as ChatMessage },
                sorting: []
            )
        }
        
        struct Handlers {
            let messageDidChange: (ChatMessage) async -> Void
            let reactionsDidChange: ([ChatMessageReaction]) async -> Void
            let repliesDidChange: (StreamCollection<ChatMessage>) async -> Void
        }
        
        func start(with handlers: Handlers) {
            do {
                var lastReactions: Set<ChatMessageReaction>?
                try messageObserver.startObserving(didChange: { message in
                    guard let message else { return }
                    let currentReactions = message.latestReactions
                    if lastReactions != currentReactions {
                        lastReactions = currentReactions
                        let sortedReactions = currentReactions.sorted(by: { $0.updatedAt > $1.updatedAt })
                        await handlers.reactionsDidChange(sortedReactions)
                    }
                    await handlers.messageDidChange(message)
                })
            } catch {
                log.error("Failed to start the messages observer for message: \(messageId)")
            }
            do {
                try repliesObserver.startObserving(didChange: handlers.repliesDidChange)
            } catch {
                log.error("Failed to start the replies observer for message: \(messageId)")
            }
        }
    }
}
