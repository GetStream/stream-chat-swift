//
// Copyright © 2024 Stream.io Inc. All rights reserved.
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

// MARK: - User blocking

extension Endpoint {
    static func blockUser(_ userId: UserId) -> Endpoint<BlockingUserPayload> {
        .init(
            path: .blockUser,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["blocked_user_id": userId]
        )
    }

    static func unblockUser(_ userId: UserId) -> Endpoint<EmptyResponse> {
        .init(
            path: .unblockUser,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["blocked_user_id": userId]
        )
    }
    
    static func loadBlockedUsers() -> Endpoint<BlocksPayload> {
        .init(
            path: .blockUser,
            method: .get,
            queryItems: nil,
            requiresConnectionId: false
        )
    }
}

// MARK: - User banning

extension Endpoint {
    static func banMember(
        _ userId: UserId,
        cid: ChannelId,
        shadow: Bool,
        timeoutInMinutes: Int?,
        reason: String?
    ) -> Endpoint<EmptyResponse> {
        .init(
            path: .banMember,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ChannelMemberBanRequestPayload(
                userId: userId,
                cid: cid,
                shadow: shadow,
                timeoutInMinutes: timeoutInMinutes,
                reason: reason
            )
        )
    }

    static func unbanMember(_ userId: UserId, cid: ChannelId) -> Endpoint<EmptyResponse> {
        .init(
            path: .banMember,
            method: .delete,
            queryItems: ChannelMemberUnbanRequestPayload(userId: userId, cid: cid),
            requiresConnectionId: false,
            body: nil
        )
    }
}

// MARK: - User flagging

extension Endpoint {
    static func flagUser(
        _ flag: Bool,
        with userId: UserId,
        reason: String? = nil,
        extraData: [String: RawJSON]? = nil
    ) -> Endpoint<FlagUserPayload> {
        .init(
            path: .flagUser(flag),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: FlagRequestBody(
                reason: reason,
                targetMessageId: nil,
                targetUserId: userId,
                custom: extraData
            )
        )
    }
}

// MARK: - Message flagging

extension Endpoint {
    static func flagMessage(
        _ flag: Bool,
        with messageId: MessageId,
        reason: String? = nil,
        extraData: [String: RawJSON]? = nil
    ) -> Endpoint<FlagMessagePayload> {
        .init(
            path: .flagMessage(flag),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: FlagRequestBody(
                reason: reason,
                targetMessageId: messageId,
                targetUserId: nil,
                custom: extraData
            )
        )
    }
}

// MARK: - Private

private extension Endpoint {
    static func muteUser(_ mute: Bool, with userId: UserId) -> Endpoint<EmptyResponse> {
        .init(
            path: .muteUser(mute),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["target_id": userId]
        )
    }
}
