//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

extension Endpoint {
    static func channels(query: ChannelListQuery)
        -> Endpoint<ChannelListPayload> {
        .init(
            path: "channels",
            method: .get,
            queryItems: nil,
            requiresConnectionId: query.options.contains(oneOf: [.presence, .state, .watch]),
            body: ["payload": query]
        )
    }
    
    static func channel(query: ChannelQuery) -> Endpoint<ChannelPayload> {
        .init(
            path: "channels/" + query.apiPath + "/query",
            method: .post,
            queryItems: nil,
            requiresConnectionId: query.options.contains(oneOf: [.presence, .state, .watch]),
            body: query
        )
    }
    
    static func updateChannel(channelPayload: ChannelEditDetailPayload)
        -> Endpoint<EmptyResponse> {
        .init(
            path: "channels/" + channelPayload.apiPath,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["data": channelPayload]
        )
    }
    
    static func muteChannel(cid: ChannelId, mute: Bool) -> Endpoint<EmptyResponse> {
        .init(
            path: "moderation/\(mute ? "mute" : "unmute")/channel",
            method: .post,
            queryItems: nil,
            requiresConnectionId: true,
            body: ["channel_cid": cid]
        )
    }
    
    static func deleteChannel(cid: ChannelId) -> Endpoint<EmptyResponse> {
        .init(
            path: "channels/" + cid.apiPath,
            method: .delete,
            queryItems: nil,
            requiresConnectionId: false,
            body: nil
        )
    }

    static func truncateChannel(cid: ChannelId) -> Endpoint<EmptyResponse> {
        .init(
            path: "channels/" + cid.apiPath + "/truncate",
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: nil
        )
    }

    static func hideChannel(cid: ChannelId, clearHistory: Bool) -> Endpoint<EmptyResponse> {
        .init(
            path: "channels/" + cid.apiPath + "/hide",
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["clear_history": clearHistory]
        )
    }
    
    static func showChannel(cid: ChannelId) -> Endpoint<EmptyResponse> {
        .init(
            path: "channels/" + cid.apiPath + "/show",
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: nil
        )
    }
    
    static func sendMessage(cid: ChannelId, messagePayload: MessageRequestBody)
        -> Endpoint<MessagePayload.Boxed> {
        .init(
            path: "channels/" + cid.apiPath + "/message",
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["message": messagePayload]
        )
    }
    
    static func addMembers(cid: ChannelId, userIds: Set<UserId>) -> Endpoint<EmptyResponse> {
        .init(
            path: "channels/" + cid.apiPath,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["add_members": userIds]
        )
    }
    
    static func removeMembers(cid: ChannelId, userIds: Set<UserId>) -> Endpoint<EmptyResponse> {
        .init(
            path: "channels/" + cid.apiPath,
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
            path: "channels/" + cid.apiPath,
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
            path: "channels/" + cid.apiPath,
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
            path: "channels/" + cid.apiPath,
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
            path: "channels/" + cid.apiPath + "/read",
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: nil
        )
    }
    
    static func markAllRead() -> Endpoint<EmptyResponse> {
        .init(
            path: "channels/read",
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: nil
        )
    }
    
    static func sendEvent(cid: ChannelId, eventType: EventType) -> Endpoint<EmptyResponse> {
        .init(
            path: "channels/" + cid.apiPath + "/event",
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["event": ["type": eventType]]
        )
    }
    
    static func sendEvent<Payload: CustomEventPayload>(_ payload: Payload, cid: ChannelId) -> Endpoint<EmptyResponse> {
        .init(
            path: "channels/" + cid.apiPath + "/event",
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["event": CustomEventRequestBody(payload: payload)]
        )
    }
    
    static func enableSlowMode(cid: ChannelId, cooldownDuration: Int) -> Endpoint<EmptyResponse> {
        .init(
            path: "channels/" + cid.apiPath,
            method: .patch,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["set": ["cooldown": cooldownDuration]]
        )
    }
    
    static func stopWatching(cid: ChannelId) -> Endpoint<EmptyResponse> {
        .init(
            path: "channels/" + cid.apiPath + "/stop-watching",
            method: .post,
            queryItems: nil,
            requiresConnectionId: true,
            body: nil
        )
    }
    
    static func channelWatchers(query: ChannelWatcherListQuery) -> Endpoint<ChannelPayload> {
        .init(
            path: "channels/" + query.cid.apiPath + "/query",
            method: .post,
            queryItems: nil,
            requiresConnectionId: true,
            body: query
        )
    }
    
    static func freezeChannel(_ freeze: Bool, cid: ChannelId) -> Endpoint<EmptyResponse> {
        .init(
            path: "channels/" + cid.apiPath,
            method: .patch,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["set": ["frozen": freeze]]
        )
    }
    
    static func pinnedMessages(cid: ChannelId, query: PinnedMessagesQuery) -> Endpoint<PinnedMessagesPayload> {
        .init(
            path: "channels/" + cid.apiPath + "/pinned_messages",
            method: .get,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["payload": query]
        )
    }
}
