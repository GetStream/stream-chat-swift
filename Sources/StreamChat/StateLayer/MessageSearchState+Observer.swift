//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
extension MessageSearchState {
    final class Observer {
        private let database: DatabaseContainer
        private var messagesObserver: BackgroundListDatabaseObserver<ChatMessage, MessageDTO>?

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
            if let query {
                messagesObserver = BackgroundListDatabaseObserver(
                    context: database.backgroundReadOnlyContext,
                    fetchRequest: MessageDTO.messagesFetchRequest(for: query),
                    itemCreator: { try $0.asModel() as ChatMessage },
                    sorting: []
                )
                messagesObserver?.onDidChange = { [messagesObserver, handlers] _ in
                    guard let handlers else { return }
                    guard let items = messagesObserver?.items else { return }
                    let collection = StreamCollection(items)
                    Task { await handlers.messagesDidChange(collection) }
                }
                do {
                    try messagesObserver?.startObserving()
                } catch {
                    log.error("Failed to start the message result observer for query (\(query) with error \(error)")
                }
            } else {
                messagesObserver = nil
            }
        }
    }
}
