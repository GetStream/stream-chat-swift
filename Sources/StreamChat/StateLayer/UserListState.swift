//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// Represents a list of users matching to the specified query.
@MainActor public final class UserListState: UserListStateBase {}

final class UserListBackgroundState: UserListStateBase {}

public class UserListStateBase: ObservableObject {
    private let observer: UserListState.Observer
    let queue: DispatchQueue
    
    init(main: Bool, query: UserListQuery, database: DatabaseContainer) {
        observer = UserListState.Observer(query: query, database: database)
        queue = main ? .main : DispatchQueue(label: "io.getstream.userliststate", target: .global())
        self.query = query
        users = observer.start(
            on: queue,
            with: .init(usersDidChange: { [weak self] users, changes in
                self?.usersLatestChanges = changes
                self?.users = users
            })
        )
    }
    
    /// The query specifying and filtering the list of users.
    public let query: UserListQuery
    
    /// An array of users for the specified ``UserListQuery``.
    @Published public private(set) var users = StreamCollection<ChatUser>([])
    
    // MARK: - Internal
    
    @Published private(set) var usersLatestChanges = [ListChange<ChatUser>]()
}
