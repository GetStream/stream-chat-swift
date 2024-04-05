//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
extension MessageSearchState {
    final class Observer {
        private let database: DatabaseContainer
        private var messagesObserver: StateLayerListDatabaseObserver<ChatMessage, MessageDTO>?

        init(database: DatabaseContainer) {
            self.database = database
        }
        
        deinit {
            guard let query else { return }
            database.write { $0.deleteQuery(query) }
        }
        
        struct Handlers {
            let messagesDidChange: (StreamCollection<ChatMessage>) async -> Void
        }
        
        private var handlers: Handlers?
        
        func start(with handlers: Handlers) {
            self.handlers = handlers
        }
        
        var query: MessageSearchQuery? {
            didSet {
                reset(to: query)
            }
        }
        
        private func reset(to query: MessageSearchQuery?) {
            guard let handlers else { return }
            if let query {
                messagesObserver = StateLayerListDatabaseObserver(
                    databaseContainer: database,
                    fetchRequest: MessageDTO.messagesFetchRequest(for: query),
                    itemCreator: { try $0.asModel() as ChatMessage },
                    sorting: []
                )
                do {
                    try messagesObserver?.startObserving(initial: true, didChange: handlers.messagesDidChange)
                } catch {
                    log.error("Failed to start the message result observer for query (\(query) with error \(error)")
                }
            } else {
                messagesObserver = nil
            }
        }
    }
}
