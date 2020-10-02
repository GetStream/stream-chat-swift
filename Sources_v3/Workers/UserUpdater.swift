//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

/// Makes user-related calls to the backend and updates the local storage with the results.
class UserUpdater<ExtraData: ExtraDataTypes>: Worker {
    /// Mutes the user with the provided `userId`.
    /// - Parameters:
    ///   - userId: The user identifier.
    ///   - completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    ///
    func muteUser(_ userId: UserId, completion: ((Error?) -> Void)? = nil) {
        apiClient.request(endpoint: .muteUser(userId)) {
            completion?($0.error)
        }
    }
    
    /// Unmutes the user with the provided `userId`.
    /// - Parameters:
    ///   - userId: The user identifier.
    ///   - completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    ///
    func unmuteUser(_ userId: UserId, completion: ((Error?) -> Void)? = nil) {
        apiClient.request(endpoint: .unmuteUser(userId)) {
            completion?($0.error)
        }
    }
    
    /// Makes a single user query call to the backend and updates the local storage with the results.
    ///
    /// - Parameters:
    ///   - userId: The user identifier
    ///   - completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    ///
    func loadUser(_ userId: UserId, completion: ((Error?) -> Void)? = nil) {
        apiClient
            .request(endpoint: .users(query: .user(withID: userId))) { (result: Result<UserListPayload<ExtraData.User>, Error>) in
                switch result {
                case let .success(payload):
                    guard payload.users.count <= 1 else {
                        completion?(ClientError.Unexpected(
                            "UserUpdater.loadUser must fetch exactly 0 or 1 user. Fetched: \(payload.users)"
                        ))
                        return
                    }
                
                    guard let user = payload.users.first else {
                        completion?(ClientError.UserDoesNotExist(userId: userId))
                        return
                    }
                
                    self.database.write({ session in
                        try session.saveUser(payload: user)
                    }, completion: { error in
                        if let error = error {
                            log.error("Failed to save user with id: <\(userId)> to the database. Error: \(error)")
                        }
                        completion?(error)
                    })
                case let .failure(error):
                    completion?(error)
                }
            }
    }
}

extension ClientError {
    class UserDoesNotExist: ClientError {
        init(userId: UserId) {
            super.init("There is no user with id: <\(userId)>.")
        }
    }
}
