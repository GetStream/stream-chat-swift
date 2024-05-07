//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat

@available(iOS 13.0, *)
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
