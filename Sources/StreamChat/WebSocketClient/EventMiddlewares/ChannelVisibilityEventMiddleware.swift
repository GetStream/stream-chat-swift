//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// The middleware listens for `ChannelHidden/Visible` events and updates `ChannelDTO` accordingly.
struct ChannelVisibilityEventMiddleware: EventMiddleware {
    func handle(event: Event, session: DatabaseSession) -> Event? {
        do {
            switch event {
            case let event as ChannelVisibleEvent:
                let cid = try ChannelId(cid: event.cid)
                guard let channelDTO = session.channel(cid: cid) else {
                    throw ClientError.ChannelDoesNotExist(cid: cid)
                }

                channelDTO.isHidden = false

            case let event as ChannelHiddenEvent:
                let cid = try ChannelId(cid: event.cid)
                guard let channelDTO = session.channel(cid: cid) else {
                    throw ClientError.ChannelDoesNotExist(cid: cid)
                }

                channelDTO.isHidden = true

                if event.clearHistory {
                    channelDTO.truncatedAt = event.createdAt.bridgeDate
                }

            // New Message will unhide the channel
            // but we won't get `ChannelVisibleEvent` for this case
            case let event as MessageNewEvent:
                let cid = try ChannelId(cid: event.cid)
                guard let channelDTO = session.channel(cid: cid) else {
                    throw ClientError.ChannelDoesNotExist(cid: cid)
                }

                if event.message?.shadowed == false {
                    channelDTO.isHidden = false
                }

            // New Message will unhide the channel
            // but we won't get `ChannelVisibleEvent` for this case
            case let event as NotificationNewMessageEvent:
                guard let channel = event.channel,
                      let cid = try? ChannelId(cid: channel.cid),
                      let channelDTO = session.channel(cid: cid) else {
                    throw ClientError.Unknown()
                }

                if !event.message.shadowed {
                    channelDTO.isHidden = false
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
