//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

extension Endpoint {
    static func missingEvents<ExtraData: ExtraDataTypes>(
        since: Date,
        cids: [ChannelId]
    ) -> Endpoint<MissingEventsPayload<ExtraData>> {
        .init(
            path: "sync",
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: MissingEventsRequestBody(lastSyncedAt: since, cids: cids)
        )
    }
}
