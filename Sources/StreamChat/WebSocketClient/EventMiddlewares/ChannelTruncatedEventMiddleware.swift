//
// Copyright © 2024 Stream.io Inc. All rights reserved.
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
            let cid = truncatedEvent.channel.cid
            guard let channelDTO = session.channel(cid: cid) else {
                throw ClientError.ChannelDoesNotExist(cid: cid)
            }

            channelDTO.truncatedAt = truncatedEvent.channel.truncatedAt?.bridgeDate

            // Until BE returns valid values for user's read after truncation, we are clearing them.
            if let userId = truncatedEvent.user?.id, let read = session.loadChannelRead(cid: cid, userId: userId) {
                read.lastReadMessageId = nil
                read.lastReadAt = truncatedEvent.channel.truncatedAt?.bridgeDate ?? DBDate()
                read.unreadMessageCount = 0
            }
        } catch {
            log.error("Failed to write the `truncatedAt` field update in the database, error: \(error)")
        }

        return event
    }
}
