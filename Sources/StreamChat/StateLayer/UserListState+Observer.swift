//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

extension UserListState {
    struct Observer {
        private let query: UserListQuery
        private let usersObserver: StateLayerDatabaseObserver<ListResult, ChatUser, UserDTO>
        let database: DatabaseContainer
        
        init(query: UserListQuery, database: DatabaseContainer) {
            self.database = database
            self.query = query
            usersObserver = StateLayerDatabaseObserver(
                database: database,
                fetchRequest: UserDTO.userListFetchRequest(query: query),
                itemCreator: { try $0.asModel() },
                itemReuseKeyPaths: (\ChatUser.id, \UserDTO.id)
            )
        }
        
        struct Handlers {
            let usersDidChange: (StreamCollection<ChatUser>, [ListChange<ChatUser>]) -> Void
        }
        
        func start(on queue: DispatchQueue, with handlers: Handlers) -> StreamCollection<ChatUser> {
            do {
                return try usersObserver.startObserving(on: queue, didChange: handlers.usersDidChange)
            } catch {
                log.error("Failed to start the user list observer for query: \(query)")
                return StreamCollection([])
            }
        }
    }
}
