//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

/// The middleware listens for `ChannelTruncatedEventMiddleware` events and updates `ChannelDTO` accordingly.
struct ChannelTruncatedEventMiddleware: EventMiddleware {
    func handle(event: Event, session: DatabaseSession) -> Event? {
        guard
            let truncatedEvent = event as? ChannelTruncatedEventDTO
        else {
            return event
        }

        do {
            if let channelDTO = session.channel(cid: truncatedEvent.channel.cid) {
                channelDTO.truncatedAt = truncatedEvent.channel.truncatedAt
            } else {
                throw ClientError.ChannelDoesNotExist(cid: truncatedEvent.channel.cid)
            }
        } catch {
            log.error("Failed to write the `truncatedAt` field update in the database, error: \(error)")
        }
        
        return event
    }
}
