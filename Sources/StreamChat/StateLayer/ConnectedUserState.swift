//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// Represents a ``CurrentChatUser`` and its state.
@MainActor public final class ConnectedUserState: ObservableObject {
    private let observer: Observer
    
    init(user: CurrentChatUser, database: DatabaseContainer) {
        observer = Observer(database: database)
        self.user = user
        let initialUser = observer.start(
            with: .init(
                userDidChange: { [weak self] in self?.user = $0 }
            )
        )
        if let initialUser {
            self.user = initialUser
        }
    }
    
    /// The represented user.
    @Published public private(set) var user: CurrentChatUser
}
