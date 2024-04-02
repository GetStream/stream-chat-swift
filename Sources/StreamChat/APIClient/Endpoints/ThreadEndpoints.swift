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

    // MARK: - Helper data structures

    struct ThreadPayloadResponse: Decodable {
        var thread: ThreadPayload
    }
}
