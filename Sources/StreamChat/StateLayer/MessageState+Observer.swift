//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
extension MessageState {
    struct Observer {
        private let messageId: MessageId
        private let messageObserver: StateLayerDatabaseObserver<EntityResult, ChatMessage, MessageDTO>
        private let reactionsObserver: StateLayerDatabaseObserver<ListResult, ChatMessageReaction, MessageReactionDTO>
        private let repliesObserver: StateLayerDatabaseObserver<ListResult, ChatMessage, MessageDTO>
        
        init(
            messageId: MessageId,
            messageOrder: MessageOrdering,
            database: DatabaseContainer,
            clientConfig: ChatClientConfig
        ) {
            self.messageId = messageId
            messageObserver = StateLayerDatabaseObserver(
                databaseContainer: database,
                fetchRequest: MessageDTO.message(withID: messageId),
                itemCreator: { try $0.asModel() }
            )
            reactionsObserver = StateLayerDatabaseObserver(
                databaseContainer: database,
                fetchRequest: MessageReactionDTO.reactionsFetchRequest(
                    for: messageId,
                    sort: ChatMessageReaction.defaultSortingDescriptors()
                ),
                itemCreator: { try $0.asModel() }
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
                itemCreator: { try $0.asModel() }
            )
        }
        
        struct Handlers {
            let messageDidChange: (ChatMessage) async -> Void
            let reactionsDidChange: (StreamCollection<ChatMessageReaction>) async -> Void
            let repliesDidChange: (StreamCollection<ChatMessage>) async -> Void
        }
        
        func start(
            with handlers: Handlers
        ) -> (
            message: ChatMessage?,
            reactions: StreamCollection<ChatMessageReaction>,
            replies: StreamCollection<ChatMessage>
        ) {
            do {
                let message = try messageObserver.startObserving(onContextDidChange: { message in
                    guard let message else { return }
                    Task.mainActor { await handlers.messageDidChange(message) }
                })
                let reactions = try reactionsObserver.startObserving(didChange: handlers.reactionsDidChange)
                let replies = try repliesObserver.startObserving(didChange: handlers.repliesDidChange)
                return (message, reactions, replies)
            } catch {
                log.error("Failed to start the observers for message: \(messageId) with error \(error)")
                return (nil, StreamCollection([]), StreamCollection([]))
            }
        }
    }
}

@available(iOS 13.0, *)
extension ChatMessageReaction {
    static func defaultSorting(_ first: ChatMessageReaction, _ second: ChatMessageReaction) -> Bool {
        first.updatedAt > second.updatedAt
    }
    
    static func defaultSortingDescriptors() -> [NSSortDescriptor] {
        [NSSortDescriptor(keyPath: \MessageReactionDTO.updatedAt, ascending: false)]
    }
}
