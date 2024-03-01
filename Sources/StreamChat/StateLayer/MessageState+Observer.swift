//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
extension MessageState {
    struct Observer {
        private let messageId: MessageId
        private let messageObserver: BackgroundEntityDatabaseObserver<ChatMessage, MessageDTO>
        private let repliesObserver: BackgroundListDatabaseObserver<ChatMessage, MessageDTO>
        
        init(messageId: MessageId, database: DatabaseContainer) {
            self.messageId = messageId
            let context = database.backgroundReadOnlyContext
            messageObserver = BackgroundEntityDatabaseObserver(
                context: context,
                fetchRequest: MessageDTO.message(withID: messageId),
                itemCreator: { try $0.asModel() as ChatMessage }
            )
            repliesObserver = BackgroundListDatabaseObserver(
                context: context,
                fetchRequest: MessageDTO.repliesFetchRequest(
                    for: messageId,
                    pageSize: .messagesPageSize,
                    sortAscending: true,
                    deletedMessagesVisibility: context.deletedMessagesVisibility ?? .visibleForCurrentUser,
                    shouldShowShadowedMessages: context.shouldShowShadowedMessages ?? false
                ),
                itemCreator: { try $0.asModel() as ChatMessage },
                sorting: []
            )
        }
        
        struct Handlers {
            let messageDidChange: (ChatMessage) async -> Void
            let reactionsDidChange: ([ChatMessageReaction]) async -> Void
            let repliesDidChange: ([ListChange<ChatMessage>]) async -> Void
        }
        
        func start(with handlers: Handlers) {
            messageObserver.onChange(do: { change in Task { await handlers.messageDidChange(change.item) } })
            messageObserver.onFieldChange(\.latestReactions, do: { change in
                let sortedReactions = change.item.sorted(by: { $0.updatedAt > $1.updatedAt })
                Task { await handlers.reactionsDidChange(sortedReactions) }
            })
            repliesObserver.onDidChange = { changes in Task { await handlers.repliesDidChange(changes) } }
            
            do {
                try messageObserver.startObserving()
            } catch {
                log.error("Failed to start the messages observer for message: \(messageId)")
            }
            do {
                try repliesObserver.startObserving()
            } catch {
                log.error("Failed to start the replies observer for message: \(messageId)")
            }
        }
    }
}
