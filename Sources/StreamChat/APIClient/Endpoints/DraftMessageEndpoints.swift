//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

extension Endpoint {
    static func drafts(query: DraftListQuery) -> Endpoint<DraftMessageListPayloadResponse> {
        .init(
            path: .drafts,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            requiresToken: true,
            body: query
        )
    }

    static func updateDraftMessage(channelId: ChannelId, requestBody: DraftMessageRequestBody) -> Endpoint<DraftMessagePayloadResponse> {
        let body: [String: AnyEncodable] = [
            "message": AnyEncodable(requestBody)
        ]
        return .init(
            path: .draftMessage(channelId),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: body
        )
    }

    static func getDraftMessage(channelId: ChannelId) -> Endpoint<DraftMessagePayloadResponse> {
        .init(
            path: .draftMessage(channelId),
            method: .get,
            queryItems: nil,
            requiresConnectionId: false,
            body: nil
        )
    }

    static func deleteDraftMessage(channelId: ChannelId) -> Endpoint<EmptyResponse> {
        .init(
            path: .draftMessage(channelId),
            method: .delete,
            queryItems: nil,
            requiresConnectionId: false,
            body: nil
        )
    }
}
