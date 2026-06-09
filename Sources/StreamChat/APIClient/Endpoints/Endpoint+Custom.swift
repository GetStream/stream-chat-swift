//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension Endpoint {
    /// Channel query endpoint used by `ChannelRepository.getChannel` and the
    /// channel-already-exists hot path.
    static func channelQuery(_ query: ChannelQuery, requiresConnectionId: Bool? = nil) -> Endpoint<ChannelStateResponse> {
        let request = query.asChannelGetOrCreateRequest()
        return .init(
            path: query.id.map { .getOrCreateChannel(type: query.type.rawValue, id: $0) } ?? .getOrCreateDistinctChannel(type: query.type.rawValue),
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId ?? query.options.contains(oneOf: [.presence, .state, .watch]),
            body: request
        )
    }

    /// Channel watcher list — uses channel query endpoint with a watcher-shaped query.
    static func channelWatchers(query: ChannelWatcherListQuery) -> Endpoint<ChannelStateResponse> {
        .init(
            path: .getOrCreateChannel(type: query.cid.type.rawValue, id: query.cid.id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: true,
            body: query
        )
    }

    /// Flag / unflag a message. Flag delegates to the generated endpoint; unflag
    /// stays custom until OpenAPI exposes a generated unflag operation.
    static func flagMessage(_ flag: Bool, with messageId: MessageId, reason: String? = nil, extraData: [String: RawJSON]? = nil) -> Endpoint<FlagResponse> {
        if flag {
            return .flag(flagRequest: FlagRequest(custom: extraData, entityId: messageId, entityType: "message", reason: reason))
        }
        return .init(
            path: .custom("moderation/\(flag ? "flag" : "unflag")"),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: FlagRequest(custom: extraData, entityId: messageId, entityType: "message", reason: reason)
        )
    }

    /// Flag / unflag a user. Flag delegates to the generated endpoint; unflag
    /// stays custom until OpenAPI exposes a generated unflag operation.
    static func flagUser(_ flag: Bool, with userId: UserId, reason: String? = nil, extraData: [String: RawJSON]? = nil) -> Endpoint<FlagResponse> {
        if flag {
            return .flag(flagRequest: FlagRequest(custom: extraData, entityId: userId, entityType: "user", reason: reason))
        }
        return .init(
            path: .custom("moderation/\(flag ? "flag" : "unflag")"),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: FlagRequest(custom: extraData, entityId: userId, entityType: "user", reason: reason)
        )
    }

    /// Loads the pinned messages of a channel. The OpenAPI spec does not expose
    /// a `pinned_messages` operation, so the path is built manually.
    static func pinnedMessages(cid: ChannelId, query: PinnedMessagesQuery) -> Endpoint<MessageListPayload> {
        .init(
            path: .custom("channels/\(cid.apiPath)/pinned_messages"),
            method: .get,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["payload": query]
        )
    }

    /// Unbans a channel member. The OpenAPI `ban` operation is POST-only;
    /// `DELETE /moderation/ban` has no generated factory yet.
    static func unbanMember(_ userId: UserId, cid: ChannelId) -> Endpoint<EmptyResponse> {
        .init(
            path: .custom("moderation/ban"),
            method: .delete,
            queryItems: [
                "target_user_id": userId,
                "channel_cid": cid.rawValue
            ],
            requiresConnectionId: false,
            body: nil
        )
    }

    /// User unmute — OpenAPI only exposes channel unmute, so this endpoint
    /// remains custom until the user unmute operation is generated.
    static func unmuteUser(_ userId: UserId) -> Endpoint<EmptyResponse> {
        .init(
            path: .custom("moderation/unmute"),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["target_id": userId]
        )
    }

    /// WebSocket connect endpoint. The OpenAPI spec exposes `longPoll` for the
    /// long-polling fallback, but the actual WebSocket establishment uses
    /// `?json=<payload>` on `/connect` with a hand-shaped auth body.
    static func webSocketConnect(userInfo: UserInfo) -> Endpoint<EmptyResponse> {
        .init(
            path: .custom("connect"),
            method: .get,
            queryItems: nil,
            requiresConnectionId: false,
            body: [
                "json": WSAuthMessage(
                    products: nil,
                    token: "",
                    userDetails: ConnectUserDetailsRequest(
                        custom: userInfo.extraData,
                        id: userInfo.id,
                        image: userInfo.imageURL?.absoluteString,
                        invisible: userInfo.isInvisible,
                        language: userInfo.language?.languageCode,
                        name: userInfo.name,
                        privacySettings: userInfo.privacySettings.map(\.asPrivacySettingsResponse)
                    )
                )
            ]
        )
    }
}
