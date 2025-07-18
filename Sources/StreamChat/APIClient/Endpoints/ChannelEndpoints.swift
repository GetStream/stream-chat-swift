//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

extension Endpoint {
    static func channels(query: ChannelListQuery) -> Endpoint<ChannelListPayload> {
        .init(
            path: .channels,
            method: .get,
            queryItems: nil,
            requiresConnectionId: query.options.contains(oneOf: [.presence, .state, .watch]),
            body: ["payload": query]
        )
    }

    static func createChannel(query: ChannelQuery) -> Endpoint<ChannelPayload> {
        createOrUpdateChannel(path: .createChannel(query.apiPath), query: query)
    }

    static func updateChannel(query: ChannelQuery) -> Endpoint<ChannelPayload> {
        createOrUpdateChannel(path: .updateChannel(query.apiPath), query: query)
    }
    
    static func channelState(query: ChannelQuery) -> Endpoint<ChannelPayload> {
        assert(!query.options.contains(oneOf: [.presence, .watch]), "This method is only for fetching channel data")
        return .init(
            path: .updateChannel(query.apiPath),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false, // presence and watch require connection id
            body: query
        )
    }

    private static func createOrUpdateChannel(path: EndpointPath, query: ChannelQuery) -> Endpoint<ChannelPayload> {
        .init(
            path: path,
            method: .post,
            queryItems: nil,
            requiresConnectionId: query.options.contains(oneOf: [.presence, .state, .watch]),
            body: query
        )
    }

    static func updateChannel(channelPayload: ChannelEditDetailPayload)
        -> Endpoint<EmptyResponse> {
        .init(
            path: .channelUpdate(channelPayload.apiPath),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["data": channelPayload]
        )
    }

    static func partialChannelUpdate(updates: ChannelEditDetailPayload, unsetProperties: [String]) -> Endpoint<EmptyResponse> {
        let body: [String: AnyEncodable] = [
            "set": AnyEncodable(updates),
            "unset": AnyEncodable(unsetProperties)
        ]

        return .init(
            path: .channelUpdate(updates.apiPath),
            method: .patch,
            queryItems: nil,
            requiresConnectionId: false,
            body: body
        )
    }
    
    static func muteChannel(
        cid: ChannelId,
        expiration: Int? = nil
    ) -> Endpoint<MutedChannelPayloadResponse> {
        var body: [String: AnyEncodable] = ["channel_cid": AnyEncodable(cid)]
        
        if let expiration = expiration {
            body["expiration"] = AnyEncodable(expiration)
        }
        
        return .init(
            path: .muteChannel(true),
            method: .post,
            queryItems: nil,
            requiresConnectionId: true,
            body: body
        )
    }

    static func unmuteChannel(
        cid: ChannelId
    ) -> Endpoint<EmptyResponse> {
        let body: [String: AnyEncodable] = ["channel_cid": AnyEncodable(cid)]

        return .init(
            path: .muteChannel(false),
            method: .post,
            queryItems: nil,
            requiresConnectionId: true,
            body: body
        )
    }

    static func deleteChannel(cid: ChannelId) -> Endpoint<EmptyResponse> {
        .init(
            path: .deleteChannel(cid.apiPath),
            method: .delete,
            queryItems: nil,
            requiresConnectionId: false,
            body: nil
        )
    }

    static func truncateChannel(
        cid: ChannelId,
        skipPush: Bool,
        hardDelete: Bool,
        message: MessageRequestBody?
    ) -> Endpoint<EmptyResponse> {
        .init(
            path: .truncateChannel(cid.apiPath),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ChannelTruncateRequestPayload(
                skipPush: skipPush,
                hardDelete: hardDelete,
                message: message
            )
        )
    }

    static func hideChannel(cid: ChannelId, clearHistory: Bool) -> Endpoint<EmptyResponse> {
        .init(
            path: .showChannel(cid.apiPath, false),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["clear_history": clearHistory]
        )
    }

    static func showChannel(cid: ChannelId) -> Endpoint<EmptyResponse> {
        .init(
            path: .showChannel(cid.apiPath, true),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: nil
        )
    }

    static func sendMessage(
        cid: ChannelId,
        messagePayload: MessageRequestBody,
        skipPush: Bool,
        skipEnrichUrl: Bool
    )
        -> Endpoint<MessagePayload.Boxed> {
        let body: [String: AnyEncodable] = [
            "message": AnyEncodable(messagePayload),
            "skip_push": AnyEncodable(skipPush),
            "skip_enrich_url": AnyEncodable(skipEnrichUrl)
        ]
        return .init(
            path: .sendMessage(cid),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: body
        )
    }

    static func addMembers(
        cid: ChannelId,
        members: [MemberInfoRequest],
        hideHistory: Bool,
        messagePayload: MessageRequestBody? = nil
    ) -> Endpoint<EmptyResponse> {
        var body: [String: AnyEncodable] = [
            "add_members": AnyEncodable(members),
            "hide_history": AnyEncodable(hideHistory)
        ]
        if let messagePayload = messagePayload {
            body["message"] = AnyEncodable(messagePayload)
        }
        return .init(
            path: .channelUpdate(cid.apiPath),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: body
        )
    }

    static func removeMembers(
        cid: ChannelId,
        userIds: Set<UserId>,
        messagePayload: MessageRequestBody? = nil
    ) -> Endpoint<EmptyResponse> {
        var body: [String: AnyEncodable] = [
            "remove_members": AnyEncodable(userIds)
        ]
        if let messagePayload = messagePayload {
            body["message"] = AnyEncodable(messagePayload)
        }
        return .init(
            path: .channelUpdate(cid.apiPath),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: body
        )
    }

    static func inviteMembers(
        cid: ChannelId,
        userIds: Set<UserId>
    ) -> Endpoint<EmptyResponse> {
        .init(
            path: .channelUpdate(cid.apiPath),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["invites": userIds]
        )
    }

    static func acceptInvite(
        cid: ChannelId,
        message: String?
    ) -> Endpoint<EmptyResponse> {
        .init(
            path: .channelUpdate(cid.apiPath),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ChannelInvitePayload(
                accept: true,
                reject: false,
                message: .init(message: message)
            )
        )
    }

    static func rejectInvite(cid: ChannelId) -> Endpoint<EmptyResponse> {
        .init(
            path: .channelUpdate(cid.apiPath),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ChannelInvitePayload(
                accept: false,
                reject: true,
                message: nil
            )
        )
    }

    static func markRead(cid: ChannelId) -> Endpoint<EmptyResponse> {
        .init(
            path: .markChannelRead(cid.apiPath),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: nil
        )
    }

    static func markUnread(cid: ChannelId, messageId: MessageId, userId: UserId) -> Endpoint<EmptyResponse> {
        .init(
            path: .markChannelUnread(cid.apiPath),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: [
                "message_id": messageId,
                "user_id": userId
            ]
        )
    }

    static func markAllRead() -> Endpoint<EmptyResponse> {
        .init(
            path: .markAllChannelsRead,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: nil
        )
    }

    static func sendEvent(cid: ChannelId, eventType: EventType) -> Endpoint<EmptyResponse> {
        .init(
            path: .channelEvent(cid.apiPath),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["event": ["type": eventType]]
        )
    }

    static func sendEvent<Payload: CustomEventPayload>(_ payload: Payload, cid: ChannelId) -> Endpoint<EmptyResponse> {
        .init(
            path: .channelEvent(cid.apiPath),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["event": CustomEventRequestBody(payload: payload)]
        )
    }

    static func startTypingEvent(cid: ChannelId, parentMessageId: MessageId?) -> Endpoint<EmptyResponse> {
        let eventType = EventType.userStartTyping
        let body: Encodable
        if let parentMessageId = parentMessageId {
            body = ["event": ["type": eventType.rawValue, "parent_id": parentMessageId]]
        } else {
            body = ["event": ["type": eventType]]
        }
        return .init(
            path: .channelEvent(cid.apiPath),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: body
        )
    }

    static func stopTypingEvent(cid: ChannelId, parentMessageId: MessageId?) -> Endpoint<EmptyResponse> {
        let eventType = EventType.userStopTyping
        let body: Encodable
        if let parentMessageId = parentMessageId {
            body = ["event": ["type": eventType.rawValue, "parent_id": parentMessageId]]
        } else {
            body = ["event": ["type": eventType]]
        }
        return .init(
            path: .channelEvent(cid.apiPath),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: body
        )
    }

    static func enableSlowMode(cid: ChannelId, cooldownDuration: Int) -> Endpoint<EmptyResponse> {
        .init(
            path: .channelUpdate(cid.apiPath),
            method: .patch,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["set": ["cooldown": cooldownDuration]]
        )
    }

    static func stopWatching(cid: ChannelId) -> Endpoint<EmptyResponse> {
        .init(
            path: .stopWatchingChannel(cid.apiPath),
            method: .post,
            queryItems: nil,
            requiresConnectionId: true,
            body: nil
        )
    }

    static func channelWatchers(query: ChannelWatcherListQuery) -> Endpoint<ChannelPayload> {
        .init(
            path: .updateChannel(query.cid.apiPath),
            method: .post,
            queryItems: nil,
            requiresConnectionId: true,
            body: query
        )
    }

    static func freezeChannel(_ freeze: Bool, cid: ChannelId) -> Endpoint<EmptyResponse> {
        .init(
            path: .channelUpdate(cid.apiPath),
            method: .patch,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["set": ["frozen": freeze]]
        )
    }

    static func pinnedMessages(cid: ChannelId, query: PinnedMessagesQuery) -> Endpoint<PinnedMessagesPayload> {
        .init(
            path: .pinnedMessages(cid.apiPath),
            method: .get,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["payload": query]
        )
    }
}

struct MemberInfoRequest: Encodable {
    let userId: UserId
    let extraData: [String: RawJSON]?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case extraData
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userId, forKey: .userId)
        try extraData?.encode(to: encoder)
    }
}
