//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

extension ConnectedUserState {
    struct Observer {
        private let userObserver: StateLayerDatabaseObserver<EntityResult, CurrentChatUser, CurrentUserDTO>
        
        init(database: DatabaseContainer) {
            userObserver = StateLayerDatabaseObserver(
                database: database,
                fetchRequest: CurrentUserDTO.defaultFetchRequest,
                itemCreator: { try $0.asModel() }
            )
        }
        
        struct Handlers {
            let userDidChange: @MainActor(CurrentChatUser) async -> Void
        }
        
        func start(with handlers: Handlers) -> CurrentChatUser? {
            do {
                let user = try userObserver.startObserving(didChange: { user in
                    guard let user else { return }
                    await handlers.userDidChange(user)
                })
                return user
            } catch {
                log.error("Failed to start the current user observer")
                return nil
            }
        }
    }
}
