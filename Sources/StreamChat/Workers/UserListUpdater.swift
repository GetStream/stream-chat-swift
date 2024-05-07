//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData

/// Makes a users query call to the backend and updates the local storage with the results.
package class UserListUpdater: Worker {
    /// Makes a users query call to the backend and updates the local storage with the results.
    ///
    /// - Parameters:
    ///   - userListQuery: The users query used in the request
    ///   - policy: The update policy for the resulting user set. See `UpdatePolicy`
    ///   - completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    ///
    package func update(userListQuery: UserListQuery, policy: UpdatePolicy = .merge, completion: ((Result<[ChatUser], Error>) -> Void)? = nil) {
        fetch(userListQuery: userListQuery) { [weak self] (result: Result<UserListPayload, Error>) in
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
    package func fetch(
        userListQuery: UserListQuery,
        completion: @escaping (Result<UserListPayload, Error>) -> Void
    ) {
        apiClient.request(
            endpoint: .users(query: userListQuery),
            completion: completion
        )
    }
}

/// Defines the update policy for this worker.
package enum UpdatePolicy {
    /// The resulting user set of the query will be merged with the existing user set.
    case merge
    /// The resulting user set of the query will replace the existing user set.
    case replace
}

extension UserPayload {
    package func asModel() -> ChatUser {
        ChatUser(
            id: id,
            name: name,
            imageURL: imageURL,
            isOnline: isOnline,
            isBanned: isBanned,
            isFlaggedByCurrentUser: false, // TODO: isFlaggedByCurrentUser is not set
            userRole: role,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deactivatedAt: deactivatedAt,
            lastActiveAt: lastActiveAt,
            teams: Set(teams),
            language: language.map(TranslationLanguage.init),
            extraData: extraData
        )
    }
}
