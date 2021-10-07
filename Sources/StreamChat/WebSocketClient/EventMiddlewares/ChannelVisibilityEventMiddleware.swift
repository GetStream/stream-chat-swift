//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// The middleware listens for `ChannelHidden/Visible` events and updates `ChannelDTO` accordingly.
struct ChannelVisibilityEventMiddleware: EventMiddleware {
    func handle(event: Event, session: DatabaseSession) -> Event? {
        do {
            switch event {
            case let event as ChannelVisibleEventDTO:
                guard let channelDTO = session.channel(cid: event.cid) else {
                    throw ClientError.ChannelDoesNotExist(cid: event.cid)
                }
                
                channelDTO.hidden = false
                
            case let event as ChannelHiddenEventDTO:
                guard let channelDTO = session.channel(cid: event.cid) else {
                    throw ClientError.ChannelDoesNotExist(cid: event.cid)
                }
                
                channelDTO.hidden = true
                
                if event.isHistoryCleared {
                    channelDTO.truncatedAt = event.createdAt
                }
                
            default:
                break
            }
        } catch {
            log.error("Failed to write changes from \(event) to the database. Error: \(error)")
        }

        return event
    }
}
