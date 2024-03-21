//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// Represents a list of users matching to the specified query.
@available(iOS 13.0, *)
public final class UserListState: ObservableObject {
    private let observer: Observer
    
    init(users: [ChatUser], query: UserListQuery, database: DatabaseContainer) {
        observer = Observer(query: query, database: database)
        self.users = StreamCollection(users)
        observer.start(
            with: .init(usersDidChange: { [weak self] change in await self?.setValue(change, for: \.users) })
        )
    }
    
    /// An array of users for the specified ``UserListQuery``.
    @Published public private(set) var users = StreamCollection<ChatUser>([])
    
    // MARK: - Mutating the State
    
    @MainActor private func setValue<Value>(_ value: Value, for keyPath: ReferenceWritableKeyPath<UserListState, Value>) {
        self[keyPath: keyPath] = value
    }
}
