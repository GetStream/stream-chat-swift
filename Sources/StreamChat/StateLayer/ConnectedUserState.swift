//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// Represents a ``CurrentChatUser`` and its state.
@available(iOS 13.0, *)
@dynamicMemberLookup
@MainActor public final class ConnectedUserState: ObservableObject {
    private let observer: Observer
    
    init(user: CurrentChatUser, database: DatabaseContainer) {
        self.observer = Observer(database: database)
        self.user = user
        observer.start(
            with: .init(
                userDidChange: { [weak self] in self?.user = $0 })
        )
        if let user = observer.userObserver.item {
            self.user = user
        }
    }
    
    /// The represented user.
    @Published public private(set) var user: CurrentChatUser
    
    // MARK: - Dynamic Member Lookup
    
    /// Provides data about the represented user.
    public subscript<T>(dynamicMember keyPath: KeyPath<CurrentChatUser, T>) -> T {
        user[keyPath: keyPath]
    }
}
