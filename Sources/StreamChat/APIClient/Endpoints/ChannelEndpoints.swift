//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension Endpoint {
    static func groupedChannels(
        request: GroupedQueryChannelsRequestBody
    ) -> Endpoint<GroupedQueryChannelsPayload> {
        .init(
            path: .groupedChannels,
            method: .post,
            queryItems: nil,
            requiresConnectionId: request.watch || request.presence,
            body: request
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
    
    static func addMembers(
        cid: ChannelId,
        members: [MemberInfoRequest],
        hideHistory: Bool,
        hideHistoryBefore: Date? = nil,
        messagePayload: MessageRequestBody? = nil
    ) -> Endpoint<EmptyResponse> {
        var body: [String: AnyEncodable] = [
            "add_members": AnyEncodable(members)
        ]
        if let hideHistoryBefore {
            body["hide_history_before"] = AnyEncodable(hideHistoryBefore)
        } else {
            body["hide_history"] = AnyEncodable(hideHistory)
        }
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

    static func startTypingEvent(cid: ChannelId, parentMessageId: MessageId?) -> Endpoint<EmptyResponse> {
        .sendEvent(
            type: cid.type.rawValue,
            id: cid.id,
            sendEventRequest: SendEventRequest(event: EventRequest(parentId: parentMessageId, type: EventType.userStartTyping.rawValue))
        )
    }

    static func stopTypingEvent(cid: ChannelId, parentMessageId: MessageId?) -> Endpoint<EmptyResponse> {
        .sendEvent(
            type: cid.type.rawValue,
            id: cid.id,
            sendEventRequest: SendEventRequest(event: EventRequest(parentId: parentMessageId, type: EventType.userStopTyping.rawValue))
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

    static func freezeChannel(_ freeze: Bool, cid: ChannelId) -> Endpoint<EmptyResponse> {
        .init(
            path: .channelUpdate(cid.apiPath),
            method: .patch,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["set": ["frozen": freeze]]
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
