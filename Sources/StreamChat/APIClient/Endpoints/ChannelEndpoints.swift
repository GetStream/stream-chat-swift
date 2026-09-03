//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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
}
