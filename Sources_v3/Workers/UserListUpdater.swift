//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import CoreData

/// Makes a users query call to the backend and updates the local storage with the results.
class UserListUpdater<ExtraData: UserExtraData>: Worker {
    /// Makes a users query call to the backend and updates the local storage with the results.
    ///
    /// - Parameters:
    ///   - userListQuery: The users query used in the request
    ///   - completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    ///
    func update(userListQuery: UserListQuery<ExtraData>, completion: ((Error?) -> Void)? = nil) {
        apiClient
            .request(endpoint: .users(query: userListQuery)) { (result: Result<UserListPayload<ExtraData>, Error>) in
                switch result {
                case let .success(userListPayload):
                    self.database.write { session in
                        do {
                            try userListPayload.users.forEach {
                                try session.saveUser(payload: $0, query: userListQuery)
                            }
                            
                            completion?(nil)
                            
                        } catch {
                            log.error("Failed to save `UserListPayload` to the database. Error: \(error)")
                            completion?(error)
                        }
                    }
                    
                case let .failure(error):
                    completion?(error)
                }
            }
    }
}
