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

// MARK: - Observing the Local State

@available(iOS 13.0, *)
extension UserListState {
    struct Observer {
        private let query: UserListQuery
        private let usersObserver: BackgroundListDatabaseObserver<ChatUser, UserDTO>
        
        init(query: UserListQuery, database: DatabaseContainer) {
            self.query = query
            usersObserver = BackgroundListDatabaseObserver(
                context: database.backgroundReadOnlyContext,
                fetchRequest: UserDTO.userListFetchRequest(query: query),
                itemCreator: { try $0.asModel() },
                sorting: []
            )
        }
        
        struct Handlers {
            let usersDidChange: (StreamCollection<ChatUser>) async -> Void
        }
        
        func start(with handlers: Handlers) {
            usersObserver.onDidChange = { [weak usersObserver] _ in
                guard let items = usersObserver?.items else { return }
                let collection = StreamCollection(items)
                Task { await handlers.usersDidChange(collection) }
            }
            do {
                try usersObserver.startObserving()
            } catch {
                log.error("Failed to start the user list observer for query: \(query)")
            }
        }
    }
}
