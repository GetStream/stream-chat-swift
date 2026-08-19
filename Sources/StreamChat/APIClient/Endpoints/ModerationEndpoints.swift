//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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
        with userId: UserId,
        reason: String? = nil,
        extraData: [String: RawJSON]? = nil
    ) -> Endpoint<FlagUserPayload> {
        .init(
            path: .flagUser,
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
        with messageId: MessageId,
        reason: String? = nil,
        extraData: [String: RawJSON]? = nil
    ) -> Endpoint<FlagMessagePayload> {
        .init(
            path: .flagMessage,
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
