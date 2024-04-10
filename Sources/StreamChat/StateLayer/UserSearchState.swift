//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// Represents a list of user search results.
@available(iOS 13.0, *)
public final class UserSearchState: ObservableObject {
    /// The last initiated search query.
    ///
    /// - Note: If searching fails, this property points to the failing query.
    @Published public private(set) var query: UserListQuery?
    
    /// An array of search results for the specified query and pagination state.
    @Published public internal(set) var users = StreamCollection<ChatUser>([])
}

// MARK: - Mutating the State on the Main Actor

@available(iOS 13.0, *)
extension UserSearchState {
    @MainActor func value<Value>(forKeyPath keyPath: KeyPath<UserSearchState, Value>) -> Value {
        self[keyPath: keyPath]
    }
    
    @MainActor private func setValue<Value>(_ value: Value, for keyPath: ReferenceWritableKeyPath<UserSearchState, Value>) {
        self[keyPath: keyPath] = value
    }
        
    @MainActor func handleStartingFetchingQuery(_ query: UserListQuery) {
        self.query = query
    }

    func handleFinishedFetchingQuery(_ completedQuery: UserListQuery, users incomingUsers: [ChatUser]) async {
        if let query = await value(forKeyPath: \.query), query.hasFilterOrSortingChanged(completedQuery) {
            // Discard since filter or sorting has changed
            return
        }
        let result: StreamCollection<ChatUser>
        if completedQuery.pagination?.offset == 0 {
            // Reset to the first page
            result = StreamCollection(incomingUsers)
        } else {
            // Filter and sorting are the same but incoming users might contain duplicates (depends how pagination is used)
            let incomingIds = Set(incomingUsers.map(\.id))
            let incomingRemovedUsers = users.filter { !incomingIds.contains($0.id) }
            let sortValues = completedQuery.sort.map(\.sortValue)
            result = StreamCollection((incomingRemovedUsers + incomingUsers).sort(using: sortValues))
        }
        await setValue(result, for: \.users)
    }
}

@available(iOS 13.0, *)
extension UserListQuery {
    func hasFilterOrSortingChanged(_ otherQuery: UserListQuery) -> Bool {
        guard filter?.filterHash == otherQuery.filter?.filterHash else { return true }
        guard sort == otherQuery.sort else { return true }
        return false
    }
}
