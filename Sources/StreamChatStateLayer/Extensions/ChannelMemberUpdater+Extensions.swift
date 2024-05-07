//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat

@available(iOS 13.0, *)
extension ChannelMemberUpdater {
    func banMember(_ userId: UserId, in cid: ChannelId, shadow: Bool, for timeoutInMinutes: Int?, reason: String?) async throws {
        try await withCheckedThrowingContinuation { continuation in
            banMember(userId, in: cid, shadow: shadow, for: timeoutInMinutes, reason: reason) { error in
                continuation.resume(with: error)
            }
        }
    }
    
    func unbanMember(_ userId: UserId, in cid: ChannelId) async throws {
        try await withCheckedThrowingContinuation { continuation in
            unbanMember(userId, in: cid) { error in
                continuation.resume(with: error)
            }
        }
    }
}
