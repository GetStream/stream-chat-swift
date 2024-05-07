//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat

@available(iOS 13.0, *)
extension UserListUpdater {
    @discardableResult func update(userListQuery: UserListQuery, policy: UpdatePolicy = .merge) async throws -> [ChatUser] {
        try await withCheckedThrowingContinuation { continuation in
            update(userListQuery: userListQuery, policy: policy) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    func fetch(userListQuery: UserListQuery, pagination: Pagination) async throws -> [ChatUser] {
        let payload = try await withCheckedThrowingContinuation { continuation in
            fetch(userListQuery: userListQuery.withPagination(pagination)) { result in
                continuation.resume(with: result)
            }
        }
        return payload.users.map { $0.asModel() }
    }
    
    func loadUsers(_ userListQuery: UserListQuery, pagination: Pagination) async throws -> [ChatUser] {
        let policy: UpdatePolicy = pagination.offset == 0 && pagination.cursor == nil ? .replace : .merge
        return try await update(userListQuery: userListQuery.withPagination(pagination), policy: policy)
    }
    
    func loadNextUsers(_ userListQuery: UserListQuery, limit: Int, offset: Int) async throws -> [ChatUser] {
        try await loadUsers(userListQuery, pagination: Pagination(pageSize: limit, offset: offset))
    }
}

extension UserListQuery {
    func withPagination(_ pagination: Pagination) -> Self {
        var query = self
        query.pagination = pagination
        return query
    }
}
