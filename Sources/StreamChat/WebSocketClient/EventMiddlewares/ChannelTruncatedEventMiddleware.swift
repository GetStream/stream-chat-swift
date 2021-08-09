//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// The middleware listens for `ChannelTruncatedEventMiddleware` events and updates `ChannelDTO` accordingly.
struct ChannelTruncatedEventMiddleware: EventMiddleware {
    func handle(event: Event, session: DatabaseSession) -> Event? {
        guard
            let truncatedEvent = event as? ChannelTruncatedEvent,
            let payload = truncatedEvent.payload as? EventPayload
        else {
            return event
        }

        do {
            if let channelDTO = session.channel(cid: truncatedEvent.cid) {
                channelDTO.truncatedAt = payload.createdAt
            } else {
                throw ClientError.ChannelDoesNotExist(cid: truncatedEvent.cid)
            }
        } catch {
            log.error("Failed to write the `truncatedAt` field update in the database, error: \(error)")
        }
        
        return event
    }
}
