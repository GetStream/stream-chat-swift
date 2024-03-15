//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
extension ConnectedUserState {
    struct Observer {
        private let userObserver: BackgroundEntityDatabaseObserver<CurrentChatUser, CurrentUserDTO>
        
        init(database: DatabaseContainer) {
            userObserver = BackgroundEntityDatabaseObserver(
                context: database.backgroundReadOnlyContext,
                fetchRequest: CurrentUserDTO.defaultFetchRequest,
                itemCreator: { try $0.asModel() }
            )
        }
        
        struct Handlers {
            let userDidChange: (CurrentChatUser) async -> Void
        }
        
        func start(with handlers: Handlers) {
            userObserver.onChange(do: { change in Task { await handlers.userDidChange(change.item) } })
            do {
                try userObserver.startObserving()
            } catch {
                log.error("Failed to start the current user observer")
            }
        }
    }
}
