//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

// MARK: - User muting

extension Endpoint {
    static func muteUser(_ userId: UserId) -> Endpoint<EmptyResponse> {
        muteUser(true, with: userId)
    }
    
    static func unmuteUser(_ userId: UserId) -> Endpoint<EmptyResponse> {
        muteUser(false, with: userId)
    }
}

// MARK: - User banning

extension Endpoint {
    static func banMember(
        _ userId: UserId,
        cid: ChannelId,
        timeoutInMinutes: Int? = nil,
        reason: String? = nil
    ) -> Endpoint<EmptyResponse> {
        .init(
            path: "moderation/ban",
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ChannelMemberBanRequestPayload(
                userId: userId,
                cid: cid,
                timeoutInMinutes: timeoutInMinutes,
                reason: reason
            )
        )
    }
    
    static func unbanMember(_ userId: UserId, cid: ChannelId) -> Endpoint<EmptyResponse> {
        .init(
            path: "moderation/ban",
            method: .delete,
            queryItems: ChannelMemberBanRequestPayload(userId: userId, cid: cid),
            requiresConnectionId: false,
            body: nil
        )
    }
}

// MARK: - Private

private extension Endpoint {
    static func muteUser(_ mute: Bool, with userId: UserId) -> Endpoint<EmptyResponse> {
        .init(
            path: "moderation/\(mute ? "mute" : "unmute")",
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["target_id": userId]
        )
    }
}
