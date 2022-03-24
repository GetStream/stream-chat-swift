//
// Copyright © 2022 Stream.io Inc. All rights reserved.
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
    func update(userListQuery: UserListQuery, policy: UpdatePolicy = .merge, completion: ((Error?) -> Void)? = nil) {
        fetch(userListQuery: userListQuery) { [weak self] (result: Result<UserListPayload, Error>) in
            switch result {
            case let .success(userListPayload):
                self?.database.write { session in
                    if case .replace = policy {
                        let dto = try session.saveQuery(query: userListQuery)
                        dto?.users.removeAll()
                    }
                    
                    try userListPayload.users.forEach {
                        try session.saveUser(payload: $0, query: userListQuery)
                    }
                } completion: { error in
                    if let error = error {
                        log.error("Failed to save `UserListPayload` to the database. Error: \(error)")
                        completion?(error)
                    } else {
                        completion?(nil)
                    }
                }
                
            case let .failure(error):
                completion?(error)
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
        completion: @escaping (Result<UserListPayload, Error>) -> Void
    ) {
        apiClient.request(
            endpoint: .users(query: userListQuery),
            completion: completion
        )
    }
}

/// Defines the update policy for this worker.
enum UpdatePolicy {
    /// The resulting user set of the query will be merged with the existing user set.
    case merge
    /// The resulting user set of the query will replace the existing user set.
    case replace
}
