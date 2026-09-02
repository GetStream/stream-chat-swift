//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension Endpoint {
    // MARK: - Thread read

    static func markThreadRead(cid: ChannelId, threadId: MessageId) -> Endpoint<EmptyResponse> {
        .init(
            path: .markThreadRead(cid: cid),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["thread_id": threadId]
        )
    }

    // MARK: - Thread unread

    static func markThreadUnread(cid: ChannelId, threadId: MessageId) -> Endpoint<EmptyResponse> {
        .init(
            path: .markThreadUnread(cid: cid),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["thread_id": threadId]
        )
    }
}
