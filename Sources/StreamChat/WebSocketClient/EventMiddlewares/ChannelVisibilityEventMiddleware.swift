//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// The middleware listens for `ChannelHidden/Visible` events and updates `ChannelDTO` accordingly.
struct ChannelVisibilityEventMiddleware: EventMiddleware {
    func handle(event: Event, session: DatabaseSession) -> Event? {
        do {
            switch event {
            case let event as ChannelVisibleEventDTO:
                guard let cidString = event.cid, let cid = try? ChannelId(cid: cidString) else { break }
                guard let channelDTO = session.channel(cid: cid) else {
                    throw ClientError.ChannelDoesNotExist(cid: cid)
                }

                channelDTO.isHidden = false

            case let event as ChannelHiddenEventDTO:
                guard let cidString = event.cid, let cid = try? ChannelId(cid: cidString) else { break }
                guard let channelDTO = session.channel(cid: cid) else {
                    throw ClientError.ChannelDoesNotExist(cid: cid)
                }

                channelDTO.isHidden = true

                if event.clearHistory == true {
                    channelDTO.truncatedAt = event.createdAt.bridgeDate
                }

            // New Message will unhide the channel
            // but we won't get `ChannelVisibleEvent` for this case
            case let event as MessageNewEventDTO:
                guard let cidString = event.cid, let cid = try? ChannelId(cid: cidString) else { break }
                guard let channelDTO = session.channel(cid: cid) else {
                    throw ClientError.ChannelDoesNotExist(cid: cid)
                }

                if !event.message.shadowed && event.message.campaignId == nil && !channelDTO.isBlocked {
                    channelDTO.isHidden = false
                }

            // New Message will unhide the channel
            // but we won't get `ChannelVisibleEvent` for this case
            case let event as NotificationNewMessageEventDTO:
                let cid = try ChannelId(cid: event.channel.cid)
                guard let channelDTO = session.channel(cid: cid) else {
                    throw ClientError.ChannelDoesNotExist(cid: cid)
                }

                if !event.message.shadowed && event.message.campaignId == nil && !channelDTO.isBlocked {
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

extension MessageResponse {
    /// Custom-data key under which the originating campaign id is stored.
    static let campaignIdCustomKey = "created_by_campaign_id"

    var campaignId: String? {
        if case let .string(value) = custom[Self.campaignIdCustomKey] {
            return value
        }
        return nil
    }
}
