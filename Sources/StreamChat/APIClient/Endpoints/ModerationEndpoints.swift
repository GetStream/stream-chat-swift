//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

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
