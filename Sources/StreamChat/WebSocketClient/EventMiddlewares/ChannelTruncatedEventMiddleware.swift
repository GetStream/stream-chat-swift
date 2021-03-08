//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// The middleware listens for `ChannelTruncatedEventMiddleware` events and updates `ChannelDTO` accordingly.
struct ChannelTruncatedEventMiddleware<ExtraData: ExtraDataTypes>: EventMiddleware {
    let database: DatabaseContainer

    func handle(event: Event, completion: @escaping (Event?) -> Void) {
        guard
            let truncatedEvent = event as? ChannelTruncatedEvent,
            let payload = truncatedEvent.payload as? EventPayload<ExtraData>
        else {
            completion(event)
            return
        }

        database.write { session in
            if let channelDTO = session.channel(cid: truncatedEvent.cid) {
                channelDTO.truncatedAt = payload.createdAt
            } else {
                throw ClientError.ChannelDoesNotExist(cid: truncatedEvent.cid)
            }
        } completion: { error in
            if let error = error {
                log.error("Failed to write the `truncatedAt` field update in the database, error: \(error)")
            }
            completion(event)
        }
    }
}
