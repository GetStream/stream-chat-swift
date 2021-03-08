//
// Copyright © 2021 Stream.io Inc. All rights reserved.
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
    
    /// Flags or unflags the user with the provided `userId` depending on `flag` value.
    /// - Parameters:
    ///   - flag: The indicator saying whether the user should be flagged or unflagged.
    ///   - userId: The identifier of a user that should be flagged or unflagged.
    ///   - completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    ///
    func flagUser(_ flag: Bool, with userId: UserId, completion: ((Error?) -> Void)? = nil) {
        let endpoint: Endpoint<FlagUserPayload<ExtraData.User>> = .flagUser(flag, with: userId)
        apiClient.request(endpoint: endpoint) {
            switch $0 {
            case let .success(payload):
                self.database.write({ session in
                    let userDTO = try session.saveUser(payload: payload.flaggedUser)
                    
                    let currentUserDTO = session.currentUser()
                    if flag {
                        currentUserDTO?.flaggedUsers.insert(userDTO)
                    } else {
                        currentUserDTO?.flaggedUsers.remove(userDTO)
                    }
                }, completion: {
                    if let error = $0 {
                        log.error("Failed to save flagged user with id: <\(userId)> to the database. Error: \(error)")
                    }
                    completion?($0)
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
