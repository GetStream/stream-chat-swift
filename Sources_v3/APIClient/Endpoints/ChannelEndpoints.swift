//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

extension Endpoint {
    static func channels<ExtraData: ExtraDataTypes>(query: ChannelListQuery)
        -> Endpoint<ChannelListPayload<ExtraData>> {
        .init(
            path: "channels",
            method: .get,
            queryItems: nil,
            requiresConnectionId: query.options.contains(oneOf: [.presence, .state, .watch]),
            body: ["payload": query]
        )
    }
    
    static func channel<ExtraData: ExtraDataTypes>(query: ChannelQuery<ExtraData>) -> Endpoint<ChannelPayload<ExtraData>> {
        .init(
            path: "channels/\(query.cid.type.rawValue)/\(query.cid.id)/query",
            method: .post,
            queryItems: nil,
            requiresConnectionId: query.options.contains(oneOf: [.presence, .state, .watch]),
            body: query
        )
    }
    
    static func updateChannel<ExtraData: ExtraDataTypes>(channelPayload: ChannelEditDetailPayload<ExtraData>)
        -> Endpoint<EmptyResponse> {
        .init(
            path: "channels/\(channelPayload.cid.type)/\(channelPayload.cid.id)",
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
            path: "channels/\(cid.type)/\(cid.id)",
            method: .delete,
            queryItems: nil,
            requiresConnectionId: false,
            body: nil
        )
    }
    
    static func hideChannel(cid: ChannelId, userId: UserId, clearHistory: Bool) -> Endpoint<EmptyResponse> {
        .init(
            path: "channels/\(cid.type)/\(cid.id)/hide",
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: HideChannelRequest(userId: userId, clearHistory: clearHistory)
        )
    }
    
    static func showChannel(cid: ChannelId, userId: UserId) -> Endpoint<EmptyResponse> {
        .init(
            path: "channels/\(cid.type)/\(cid.id)/show",
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["userId": userId]
        )
    }
    
    static func sendMessage<ExtraData: ExtraDataTypes>(cid: ChannelId, messagePayload: MessageRequestBody<ExtraData>)
        -> Endpoint<EmptyResponse> {
        .init(
            path: "channels/\(cid.type)/\(cid.id)/message",
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["message": messagePayload]
        )
    }
    
    static func addMembers(cid: ChannelId, userIds: Set<UserId>) -> Endpoint<EmptyResponse> {
        .init(
            path: "channels/\(cid.type)/\(cid.id)",
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["add_members": userIds]
        )
    }
    
    static func removeMembers(cid: ChannelId, userIds: Set<UserId>) -> Endpoint<EmptyResponse> {
        .init(
            path: "channels/\(cid.type)/\(cid.id)",
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["remove_members": userIds]
        )
    }
    
    static func markRead(cid: ChannelId) -> Endpoint<EmptyResponse> {
        .init(
            path: "channels/\(cid.type)/\(cid.id)/read",
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
            path: "channels/\(cid.type)/\(cid.id)/event",
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["event": ["type": eventType]]
        )
    }
}
