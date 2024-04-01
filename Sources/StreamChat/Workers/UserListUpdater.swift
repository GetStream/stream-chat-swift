//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData

/// Makes a users query call to the backend and updates the local storage with the results.
class UserListUpdater: Worker {
    /// Makes a users query call to the backend and updates the local storage with the results.
    ///
    /// - Parameters:
    ///   - userListQuery: The users query used in the request
    ///   - policy: The update policy for the resulting user set. See `UpdatePolicy`
    ///   - completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    ///
    func update(userListQuery: UserListQuery, policy: UpdatePolicy = .merge, completion: ((Result<[ChatUser], Error>) -> Void)? = nil) {
        fetch(userListQuery: userListQuery) { [weak self] (result: Result<QueryUsersResponse, Error>) in
            switch result {
            case let .success(userListPayload):
                var users = [ChatUser]()
                self?.database.write { session in
                    if case .replace = policy {
                        let dto = try session.saveQuery(query: userListQuery)
                        dto?.users.removeAll()
                    }

                    let dtos = session.saveUsers(payload: userListPayload, query: userListQuery)
                    if completion != nil {
                        users = try dtos.map { try $0.asModel() }
                    }
                } completion: { error in
                    if let error = error {
                        log.error("Failed to save `UserListPayload` to the database. Error: \(error)")
                        completion?(.failure(error))
                    } else {
                        completion?(.success(users))
                    }
                }
            case let .failure(error):
                completion?(.failure(error))
            }
        }
    }

    /// Makes a users query call to the backend and returns the results via completion.
    ///
    /// - Parameters:
    ///   - userListQuery: The query to fetch.
    ///   - completion: The completion to call with the results.
    ///
    func fetch(
        userListQuery: UserListQuery,
        completion: @escaping (Result<QueryUsersResponse, Error>) -> Void
    ) {
        var filter: [String: RawJSON]?
        if let data = try? JSONEncoder.default.encode(userListQuery.filter) {
            filter = try? JSONDecoder.default.decode([String: RawJSON].self, from: data)
        }
        
        let sort = userListQuery.sort.map { sortingKey in
            SortParam(direction: sortingKey.direction, field: sortingKey.key.rawValue)
        }
        
        let request = QueryUsersPayload(
            filterConditions: filter ?? [:],
            limit: userListQuery.pagination?.pageSize,
            offset: userListQuery.pagination?.offset,
            presence: userListQuery.options.contains(.presence),
            sort: sort
        )
        api.queryUsers(payload: request, completion: completion)
    }
}

/// Defines the update policy for this worker.
enum UpdatePolicy {
    /// The resulting user set of the query will be merged with the existing user set.
    case merge
    /// The resulting user set of the query will replace the existing user set.
    case replace
}

@available(iOS 13.0, *)
extension UserListUpdater {
    func update(userListQuery: UserListQuery, policy: UpdatePolicy = .merge) async throws -> [ChatUser] {
        try await withCheckedThrowingContinuation { continuation in
            update(userListQuery: userListQuery) { result in
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
        try await update(userListQuery: userListQuery.withPagination(pagination), policy: .merge)
    }
    
    func loadNextUsers(_ userListQuery: UserListQuery, limit: Int, offset: Int) async throws -> [ChatUser] {
        try await loadUsers(userListQuery, pagination: Pagination(pageSize: limit, offset: offset))
    }
}

private extension UserListQuery {
    func withPagination(_ pagination: Pagination) -> Self {
        var query = self
        query.pagination = pagination
        return query
    }
}

private extension QueryUserResult {
    func asModel() -> ChatUser {
        ChatUser(
            id: id,
            name: name,
            imageURL: URL(string: image ?? ""),
            isOnline: online,
            isBanned: banned,
            isFlaggedByCurrentUser: false, // TODO: isFlaggedByCurrentUser is not set
            userRole: UserRole(rawValue: role),
            createdAt: createdAt,
            updatedAt: updatedAt,
            deactivatedAt: nil,
            lastActiveAt: nil,
            teams: Set(teams),
            language: TranslationLanguage(languageCode: language),
            extraData: custom
        )
    }
}
