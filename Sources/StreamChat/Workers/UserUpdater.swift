//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

/// Makes user-related calls to the backend and updates the local storage with the results.
class UserUpdater: Worker {
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
    
    /// Blocks the user with the provided `userId`.
    /// - Parameters:
    ///   - userId: The user identifier.
    ///   - completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    ///
    func blockUser(_ userId: UserId, completion: ((Error?) -> Void)? = nil) {
        apiClient.request(endpoint: .blockUser(userId)) {
            switch $0 {
            case .success:
                self.database.write({ session in
                    session.currentUser?.blockedUserIds.insert(userId)
                    let channel = ChannelDTO.directMessageChannel(
                        participantId: userId,
                        context: self.database.writableContext
                    )
                    channel?.isHidden = true
                }, completion: {
                    if let error = $0 {
                        log.error("Failed to save blocked user with id: <\(userId)> to the database. Error: \(error)")
                    }
                    completion?($0)
                })
            case let .failure(error):
                self.database.write { session in
                    session.currentUser?.blockedUserIds.remove(userId)
                }
                completion?(error)
            }
        }
    }

    /// Unblocks the user with the provided `userId`.
    /// - Parameters:
    ///   - userId: The user identifier.
    ///   - completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    ///
    func unblockUser(_ userId: UserId, completion: ((Error?) -> Void)? = nil) {
        apiClient.request(endpoint: .unblockUser(userId)) {
            switch $0 {
            case .success:
                self.database.write({ session in
                    session.currentUser?.blockedUserIds.remove(userId)
                    let channel = ChannelDTO.directMessageChannel(
                        participantId: userId,
                        context: self.database.writableContext
                    )
                    channel?.isHidden = false
                }, completion: {
                    if let error = $0 {
                        log.error("Failed to remove blocked user with id: <\(userId)> from the database. Error: \(error)")
                    }
                    completion?($0)
                })
            case let .failure(error):
                self.database.write { session in
                    session.currentUser?.blockedUserIds.insert(userId)
                }
                completion?(error)
            }
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
            .request(endpoint: .users(query: .user(withID: userId))) { (result: Result<UserListPayload, Error>) in
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
        let endpoint: Endpoint<FlagUserPayload> = .flagUser(flag, with: userId)
        apiClient.request(endpoint: endpoint) {
            switch $0 {
            case let .success(payload):
                self.database.write({ session in
                    let userDTO = try session.saveUser(payload: payload.flaggedUser)

                    let currentUserDTO = session.currentUser
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
    final class UserDoesNotExist: ClientError {
        init(userId: UserId) {
            super.init("There is no user with id: <\(userId)>.")
        }
    }
}

extension UserUpdater {
    func muteUser(_ userId: UserId) async throws {
        try await withCheckedThrowingContinuation { continuation in
            muteUser(userId) { error in
                continuation.resume(with: error)
            }
        }
    }
    
    func unmuteUser(_ userId: UserId) async throws {
        try await withCheckedThrowingContinuation { continuation in
            unmuteUser(userId) { error in
                continuation.resume(with: error)
            }
        }
    }
    
    func blockUser(_ userId: UserId) async throws {
        try await withCheckedThrowingContinuation { continuation in
            blockUser(userId) { error in
                continuation.resume(with: error)
            }
        }
    }
    
    func unblockUser(_ userId: UserId) async throws {
        try await withCheckedThrowingContinuation { continuation in
            unblockUser(userId) { error in
                continuation.resume(with: error)
            }
        }
    }
    
    func flag(_ userId: UserId) async throws {
        try await withCheckedThrowingContinuation { continuation in
            flagUser(true, with: userId) { error in
                continuation.resume(with: error)
            }
        }
    }
    
    func unflag(_ userId: UserId) async throws {
        try await withCheckedThrowingContinuation { continuation in
            flagUser(false, with: userId) { error in
                continuation.resume(with: error)
            }
        }
    }
}
