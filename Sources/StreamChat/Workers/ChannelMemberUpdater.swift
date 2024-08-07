//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// Makes channel member related calls to the backend.
class ChannelMemberUpdater: Worker {
    /// Bans the user in the channel.
    /// - Parameters:
    ///   - userId: The user identifier to ban.
    ///   - cid: The channel identifier to ban in.
    ///   - shadow: If true, it performs a shadow ban.
    ///   - timeoutInMinutes: The # of minutes the user should be banned for.
    ///   - reason: The ban reason.
    ///   - completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    func banMember(
        _ userId: UserId,
        in cid: ChannelId,
        shadow: Bool,
        for timeoutInMinutes: Int? = nil,
        reason: String? = nil,
        completion: ((Error?) -> Void)? = nil
    ) {
        apiClient.request(
            endpoint: .banMember(userId, cid: cid, shadow: shadow, timeoutInMinutes: timeoutInMinutes, reason: reason)
        ) {
            completion?($0.error)
        }
    }

    /// Unbans the user in the channel.
    /// - Parameters:
    ///   - userId: The user identifier to unban.
    ///   - cid: The channel identifier to unban in.
    ///   - completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    func unbanMember(
        _ userId: UserId,
        in cid: ChannelId,
        completion: ((Error?) -> Void)? = nil
    ) {
        apiClient.request(endpoint: .unbanMember(userId, cid: cid)) {
            completion?($0.error)
        }
    }
}

extension ChannelMemberUpdater {
    func banMember(
        _ userId: UserId,
        in cid: ChannelId,
        shadow: Bool,
        for timeoutInMinutes: Int?,
        reason: String?
    ) async throws {
        try await withCheckedThrowingContinuation { continuation in
            banMember(
                userId,
                in: cid,
                shadow: shadow,
                for: timeoutInMinutes,
                reason: reason
            ) { error in
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
