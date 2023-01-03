//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

extension Endpoint {
    static func missingEvents(
        since: Date,
        cids: [ChannelId]
    ) -> Endpoint<MissingEventsPayload> {
        .init(
            path: .sync,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: MissingEventsRequestBody(lastSyncedAt: since, cids: cids)
        )
    }
}
