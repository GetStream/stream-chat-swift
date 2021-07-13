//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

extension Endpoint {
    static func channels<ExtraData: ExtraDataTypes>(query: _ChannelListQuery<ExtraData.Channel>)
        -> Endpoint<ChannelListPayload<ExtraData>> {
        .init(
            path: "channels",
            method: .get,
            queryItems: nil,
            requiresConnectionId: query.options.contains(oneOf: [.presence, .state, .watch]),
            body: ["payload": query]
        )
    }
    
    static func channel<ExtraData: ExtraDataTypes>(query: _ChannelQuery<ExtraData>) -> Endpoint<ChannelPayload<ExtraData>> {
        .init(
            path: "channels/" + query.apiPath + "/query",
            method: .post,
            queryItems: nil,
            requiresConnectionId: query.options.contains(oneOf: [.presence, .state, .watch]),
            body: query
        )
    }
    
    static func updateChannel<ExtraData: ExtraDataTypes>(channelPayload: ChannelEditDetailPayload<ExtraData>)
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

    static func acceptInvite(cid: ChannelId, acceptInvite: Bool) -> Endpoint<EmptyResponse> {
        .init(
            path: "channels/" + cid.apiPath,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["accept_invite": acceptInvite]
        )
    }

    static func rejectInvite(cid: ChannelId, rejectInvite: Bool) -> Endpoint<EmptyResponse> {
        .init(
            path: "channels/" + cid.apiPath,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["reject_invite": rejectInvite]
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
    
    static func sendMessage<ExtraData: ExtraDataTypes>(cid: ChannelId, messagePayload: MessageRequestBody<ExtraData>)
        -> Endpoint<MessagePayload<ExtraData>.Boxed> {
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
    
    static func channelWatchers<ExtraData: ExtraDataTypes>(query: ChannelWatcherListQuery) -> Endpoint<ChannelPayload<ExtraData>> {
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
}
