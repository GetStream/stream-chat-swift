//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension Endpoint {
    /// Channel query endpoint used by `ChannelRepository.getChannel` and the
    /// channel-already-exists hot path.
    static func channelQuery(_ query: ChannelQuery) -> Endpoint<ChannelStateResponse> {
        let request = query.asChannelGetOrCreateRequest()
        let requiresConnectionId = query.options.contains(oneOf: [.presence, .watch])
        if let id = query.id {
            return .getOrCreateChannel(
                type: query.type.rawValue,
                id: id,
                channelGetOrCreateRequest: request,
                requiresConnectionId: requiresConnectionId
            )
        }
        return .getOrCreateDistinctChannel(
            type: query.type.rawValue,
            channelGetOrCreateRequest: request,
            requiresConnectionId: requiresConnectionId
        )
    }

    /// Channel watcher list — uses channel query endpoint with a watcher-shaped query.
    static func channelWatchers(query: ChannelWatcherListQuery) -> Endpoint<ChannelStateResponse> {
        .init(
            path: .getOrCreateChannel(type: query.cid.type.rawValue, id: query.cid.id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: true,
            body: ChannelGetOrCreateRequest(
                state: true,
                watch: true,
                watchers: query.pagination.asPaginationParams()
            )
        )
    }

    /// Flag / unflag a message. Flag delegates to the generated endpoint; unflag
    /// stays on the v1 path — the backend exposes no v2 unflag route and treats
    /// the v1 endpoint as a validate-only no-op kept for backwards compatibility.
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
    /// stays on the v1 path — the backend exposes no v2 unflag route and treats
    /// the v1 endpoint as a validate-only no-op kept for backwards compatibility.
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

    /// Loads the pinned messages of a channel. The endpoint is served under
    /// `/api/v2/chat/` but excluded from the OpenAPI spec, so the path is built
    /// manually until generation covers it.
    static func pinnedMessages(cid: ChannelId, query: PinnedMessagesQuery) -> Endpoint<MessageListPayload> {
        .init(
            path: .custom("/api/v2/chat/channels/\(cid.apiPath)/pinned_messages"),
            method: .get,
            queryItems: [
                "payload": (try? CodableHelper.encode(query).get()).flatMap { String(data: $0, encoding: .utf8) }
            ],
            requiresConnectionId: false,
            body: nil
        )
    }

    /// Unbans a channel member. Stays on the v1 path — the v2
    /// `POST /api/v2/moderation/unban` operation is server-side only.
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

    /// User unmute — stays on the v1 path; the v2
    /// `POST /api/v2/moderation/unmute` operation is server-side only.
    static func unmuteUser(_ userId: UserId) -> Endpoint<EmptyResponse> {
        .init(
            path: .custom("moderation/unmute"),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["target_id": userId]
        )
    }

    /// WebSocket connect endpoint (v2 connect protocol). Authentication happens
    /// via the first WebSocket frame (`WSAuthMessage`) sent by `ConnectionRepository`
    /// when the socket opens; the upgrade request itself only carries the `api_key`
    /// query item and auth headers added by the request encoder.
    static func webSocketConnect() -> Endpoint<EmptyResponse> {
        .init(
            path: .custom("/api/v2/connect"),
            method: .get,
            queryItems: nil,
            requiresConnectionId: false,
            body: nil
        )
    }
}
