//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// Represents a list of user search results.
@available(iOS 13.0, *)
public final class UserSearchState: ObservableObject {
    /// The search query the results corresponds to.
    @Published public private(set) var query: UserListQuery?
    
    /// An array of search results for the specified query and pagination state.
    @Published public private(set) var users = StreamCollection<ChatUser>([])
    
    // MARK: - Private
    
    private var activeTask: Task<[ChatUser], Error>?
}

// MARK: - Mutating the State on the Main Actor

@available(iOS 13.0, *)
extension UserSearchState {
    @MainActor func value<Value>(forKeyPath keyPath: KeyPath<UserSearchState, Value>) -> Value {
        self[keyPath: keyPath]
    }
        
    @MainActor func setActiveTask(_ task: Task<[ChatUser], Error>, query: UserListQuery) {
        if let activeTask {
            activeTask.cancel()
        }
        activeTask = task
        self.query = query
    }
    
    @MainActor func setUsers(_ newUsers: [ChatUser], for query: UserListQuery, pagination: Pagination) {
        // When the query changes we set the pagination to 0, otherwise we are loading more results for the same query
        if pagination.offset == 0 {
            users = StreamCollection(newUsers)
        } else {
            var result = Array(users[..<pagination.offset])
            result.append(contentsOf: newUsers)
            users = StreamCollection(result)
        }
    }
}
