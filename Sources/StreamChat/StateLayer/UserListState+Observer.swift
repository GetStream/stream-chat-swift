//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
extension UserListState {
    struct Observer {
        private let query: UserListQuery
        private let usersObserver: BackgroundListDatabaseObserver<ChatUser, UserDTO>
        
        init(query: UserListQuery, database: DatabaseContainer) {
            self.query = query
            usersObserver = BackgroundListDatabaseObserver(
                context: database.backgroundReadOnlyContext,
                fetchRequest: UserDTO.userListFetchRequest(query: query),
                itemCreator: { try $0.asModel() },
                sorting: []
            )
        }
        
        struct Handlers {
            let usersDidChange: (StreamCollection<ChatUser>) async -> Void
        }
        
        func start(with handlers: Handlers) {
            usersObserver.onDidChange = { [weak usersObserver] _ in
                guard let items = usersObserver?.items else { return }
                let collection = StreamCollection(items)
                Task { await handlers.usersDidChange(collection) }
            }
            do {
                try usersObserver.startObserving()
            } catch {
                log.error("Failed to start the user list observer for query: \(query)")
            }
        }
    }
}
