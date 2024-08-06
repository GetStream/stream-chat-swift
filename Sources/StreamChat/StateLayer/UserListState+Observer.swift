//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

extension UserListState {
    struct Observer {
        private let query: UserListQuery
        private let usersObserver: StateLayerDatabaseObserver<ListResult, ChatUser, UserDTO>
        
        init(query: UserListQuery, database: DatabaseContainer) {
            self.query = query
            usersObserver = StateLayerDatabaseObserver(
                database: database,
                fetchRequest: UserDTO.userListFetchRequest(query: query),
                itemCreator: { try $0.asModel() },
                itemReuseKeyPaths: (\ChatUser.id, \UserDTO.id)
            )
        }
        
        struct Handlers {
            let usersDidChange: (StreamCollection<ChatUser>) async -> Void
        }
        
        func start(with handlers: Handlers) -> StreamCollection<ChatUser> {
            do {
                return try usersObserver.startObserving(didChange: handlers.usersDidChange)
            } catch {
                log.error("Failed to start the user list observer for query: \(query)")
                return StreamCollection([])
            }
        }
    }
}
