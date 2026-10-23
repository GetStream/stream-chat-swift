//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension ScheduledMessageListState {
    struct Observer {
        private let scheduledMessageListObserver: StateLayerDatabaseObserver<ListResult, ScheduledMessage, ScheduledMessageDTO>

        init(query: ScheduledMessageListQuery, database: DatabaseContainer) {
            scheduledMessageListObserver = StateLayerDatabaseObserver(
                database: database,
                fetchRequest: ScheduledMessageDTO.scheduledMessagesFetchRequest(query: query),
                itemCreator: { try $0.asModel() },
                itemReuseKeyPaths: (\ScheduledMessage.id, \ScheduledMessageDTO.id)
            )
        }

        struct Handlers {
            let scheduledMessagesDidChange: @Sendable @MainActor ([ScheduledMessage]) async -> Void
        }

        func start(with handlers: Handlers) -> [ScheduledMessage] {
            do {
                return try scheduledMessageListObserver.startObserving(didChange: handlers.scheduledMessagesDidChange)
            } catch {
                log.error("Failed to start the scheduled message list observer with error \(error)")
                return []
            }
        }
    }
}
