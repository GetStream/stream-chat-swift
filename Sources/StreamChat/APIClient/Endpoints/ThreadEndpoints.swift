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
    ) -> Endpoint<ThreadPayloadResponse> {
        .init(
            path: .thread(messageId: messageId),
            method: .patch,
            queryItems: nil,
            requiresConnectionId: false,
            body: request
        )
    }
}

// MARK: - Helper data structures

struct ThreadPayloadResponse: Decodable {
    var thread: ThreadPayload
}

struct ThreadPartialUpdateRequest: Encodable {
    var set: SetProperties
    var unset: [String]?

    /// The available thread properties that can be updated.
    struct SetProperties: Encodable {
        var title: String?
    }
}
