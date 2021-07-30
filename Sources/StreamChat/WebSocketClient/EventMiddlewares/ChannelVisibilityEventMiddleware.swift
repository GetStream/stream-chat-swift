//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// The middleware listens for `ChannelHidden/Visible` events and updates `ChannelDTO` accordingly.
struct ChannelVisibilityEventMiddleware: EventMiddleware {
    func handle(event: Event, session: DatabaseSession) -> Event? {
        guard event is ChannelVisibleEvent || event is ChannelHiddenEvent else { return event }

        do {
            guard let cid = (event as? ChannelSpecificEvent)?.cid else {
                throw ClientError.InvalidChannelId("Failed to extract `cid` from event \(event).")
            }

            guard let channelDTO = session.channel(cid: cid) else {
                throw ClientError.ChannelDoesNotExist(cid: cid)
            }

            if let hiddenEvent = event as? ChannelHiddenEvent {
                channelDTO.hiddenAt = hiddenEvent.hiddenAt
                if hiddenEvent.isHistoryCleared {
                    channelDTO.truncatedAt = hiddenEvent.hiddenAt
                }
            }

            if event is ChannelVisibleEvent {
                channelDTO.hiddenAt = nil
            }

        } catch {
            log.error("Failed to write changes from \(event) to the database. Error: \(error)")
        }

        return event
    }
}
