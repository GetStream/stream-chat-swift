//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// The middleware listens for `ChannelHidden/Visible` events and updates `ChannelDTO` accordingly.
struct ChannelVisibilityEventMiddleware<ExtraData: ExtraDataTypes>: EventMiddleware {
    func handle(event: Event, session: DatabaseSession) -> Event? {
        guard event is ChannelHiddenEvent || event is ChannelVisibleEvent else { return event }

        let cid = (event as! EventWithChannelId).cid
        do {
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
