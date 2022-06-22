//
// Copyright © 2022 Stream.io Inc. All rights reserved.
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
    
    static func muteChannel(cid: ChannelId, mute: Bool) -> Endpoint<EmptyResponse> {
        .init(
            path: .muteChannel(mute),
            method: .post,
            queryItems: nil,
            requiresConnectionId: true,
            body: ["channel_cid": cid]
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
    
    static func sendMessage(cid: ChannelId, messagePayload: MessageRequestBody)
        -> Endpoint<MessagePayload.Boxed> {
        .init(
            path: .sendMessage(cid),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["message": messagePayload]
        )
    }
    
    static func addMembers(cid: ChannelId, userIds: Set<UserId>) -> Endpoint<EmptyResponse> {
        .init(
            path: .channelUpdate(cid.apiPath),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["add_members": userIds]
        )
    }
    
    static func removeMembers(cid: ChannelId, userIds: Set<UserId>) -> Endpoint<EmptyResponse> {
        .init(
            path: .channelUpdate(cid.apiPath),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["remove_members": userIds]
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
