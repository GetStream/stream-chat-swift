//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// Makes channel member related calls to the backend.
class ChannelMemberUpdater: Worker {
    /// Bans the user in the channel for a specific # of minutes.
    /// - Parameters:
    ///   - userId: The user identifier to ban.
    ///   - cid: The channel identifier to ban in.
    ///   - timeoutInMinutes: The # of minutes the user should be banned for.
    ///   - reason: The ban reason.
    ///   - completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    func banMember(
        _ userId: UserId,
        in cid: ChannelId,
        for timeoutInMinutes: Int? = nil,
        reason: String? = nil,
        completion: ((Error?) -> Void)? = nil
    ) {
        apiClient.request(endpoint: .banMember(userId, cid: cid, timeoutInMinutes: timeoutInMinutes, reason: reason)) {
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
        in cid: ChannelId, completion: ((Error?) -> Void)? = nil
    ) {
        apiClient.request(endpoint: .unbanMember(userId, cid: cid)) {
            completion?($0.error)
        }
    }
}
