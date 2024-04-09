//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
extension ConnectedUserState {
    struct Observer {
        private let userObserver: StateLayerDatabaseObserver<EntityResult, CurrentChatUser, CurrentUserDTO>
        
        init(database: DatabaseContainer) {
            userObserver = StateLayerDatabaseObserver(
                databaseContainer: database,
                fetchRequest: CurrentUserDTO.defaultFetchRequest,
                itemCreator: { try $0.asModel() }
            )
        }
        
        struct Handlers {
            let userDidChange: (CurrentChatUser) async -> Void
        }
        
        func start(with handlers: Handlers) {
            do {
                try userObserver.startObserving(didChange: { user in
                    guard let user else { return }
                    await handlers.userDidChange(user)
                })
            } catch {
                log.error("Failed to start the current user observer")
            }
        }
    }
}
