//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// Represents a list of users matching to the specified query.
@MainActor public final class UserListState: ObservableObject {
    private let observer: Observer
    
    init(query: UserListQuery, database: DatabaseContainer) {
        observer = Observer(query: query, database: database)
        self.query = query

        users = observer.start(
            with: .init(usersDidChange: { [weak self] users, changes in
                guard let self else { return }
                self.users = users
                self.usersDidChangeHandler?(changes)
            })
        )
    }

    /// The query specifying and filtering the list of users.
    public let query: UserListQuery

    /// An array of users for the specified ``UserListQuery``.
    @Published public private(set) var users: [ChatUser] = []

    var usersDidChangeHandler: (@MainActor ([ListChange<ChatUser>]) -> Void)? {
        didSet {
            guard let usersDidChangeHandler else { return }
            usersDidChangeHandler(users.enumerated().map({ .insert($1, index: IndexPath(item: $0, section: 0)) }))
        }
    }
}
