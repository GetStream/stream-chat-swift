//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// Represents a list of users matching to the specified query.
@MainActor public final class UserListState: ObservableObject {
    private let observer: Observer
    
    init(query: UserListQuery, database: DatabaseContainer) {
        observer = Observer(query: query, database: database)
        self.query = query
        
        users = observer.start(
            with: .init(usersDidChange: { [weak self] in self?.users = $0 })
        )
    }
    
    /// The query specifying and filtering the list of users.
    public let query: UserListQuery
    
    /// An array of users for the specified ``UserListQuery``.
    @Published public private(set) var users = StreamCollection<ChatUser>([])
}
