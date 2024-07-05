//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

extension Endpoint {
    // MARK: - Fetch Threads List
    
    static func threads(query: ThreadListQuery) -> Endpoint<ThreadListPayload> {
        .init(
            path: .threads,
            method: .post,
            queryItems: nil,
            requiresConnectionId: query.watch == true,
            body: query
        )
    }

    // MARK: - Fetch Thread

    static func thread(query: ThreadQuery) -> Endpoint<ThreadPayloadResponse> {
        .init(
            path: .thread(messageId: query.messageId),
            method: .get,
            queryItems: query,
            requiresConnectionId: query.watch == true,
            body: nil
        )
    }

    // MARK: - Partial Update Thread

    static func partialThreadUpdate(
        messageId: MessageId,
        request: ThreadPartialUpdateRequest
    ) -> Endpoint<ThreadPartialUpdateResponse> {
        .init(
            path: .thread(messageId: messageId),
            method: .patch,
            queryItems: nil,
            requiresConnectionId: false,
            body: request
        )
    }

    // MARK: - Thread read

    static func markThreadRead(cid: ChannelId, threadId: MessageId) -> Endpoint<EmptyResponse> {
        .init(
            path: .markThreadRead(cid: cid),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: [
                "thread_id": threadId
            ]
        )
    }

    // MARK: - Thread unread

    static func markThreadUnread(cid: ChannelId, threadId: MessageId) -> Endpoint<EmptyResponse> {
        .init(
            path: .markThreadUnread(cid: cid),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: [
                "thread_id": threadId
            ]
        )
    }
}

// MARK: - Helper data structures

struct ThreadPayloadResponse: Decodable {
    let thread: ThreadPayload
}

struct ThreadPartialUpdateResponse: Decodable {
    let thread: ThreadPartialPayload
}

struct ThreadPartialUpdateRequest: Encodable {
    let set: SetProperties?
    let unset: [String]?

    init(set: SetProperties?, unset: [String]? = nil) {
        self.set = set
        self.unset = unset
    }

    /// The available thread properties that can be updated.
    struct SetProperties: Encodable {
        var title: String?
        var extraData: [String: RawJSON]?

        enum CodingKeys: CodingKey {
            case title
            case extraData
        }

        func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encodeIfPresent(title, forKey: .title)
            try extraData?.encode(to: encoder)
        }
    }
}
