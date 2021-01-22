//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import CoreData

/// Makes a users query call to the backend and updates the local storage with the results.
class UserListUpdater<ExtraData: UserExtraData>: Worker {
    /// Defines the update policy for this worker.
    enum UpdatePolicy {
        /// The resulting user set of the query will be merged with the existing user set.
        case merge
        /// The resulting user set of the query will replace the existing user set.
        case replace
    }

    /// Makes a users query call to the backend and updates the local storage with the results.
    ///
    /// - Parameters:
    ///   - userListQuery: The users query used in the request
    ///   - policy: The update policy for the resulting user set. See `UpdatePolicy`
    ///   - completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    ///
    func update(userListQuery: _UserListQuery<ExtraData>, policy: UpdatePolicy = .merge, completion: ((Error?) -> Void)? = nil) {
        apiClient
            .request(endpoint: .users(query: userListQuery)) { (result: Result<UserListPayload<ExtraData>, Error>) in
                switch result {
                case let .success(userListPayload):
                    self.database.write { session in
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
}
