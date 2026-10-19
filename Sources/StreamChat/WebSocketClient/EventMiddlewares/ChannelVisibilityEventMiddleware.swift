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
                guard let channelDTO = session.channel(cid: event.cid) else {
                    throw ClientError.ChannelDoesNotExist(cid: event.cid)
                }

                channelDTO.isHidden = false

            case let event as ChannelHiddenEventDTO:
                guard let channelDTO = session.channel(cid: event.cid) else {
                    throw ClientError.ChannelDoesNotExist(cid: event.cid)
                }

                channelDTO.isHidden = true

                if event.clearHistory ?? false {
                    channelDTO.truncatedAt = event.createdAt.bridgeDate
                }

            // New Message will unhide the channel
            // but we won't get `ChannelVisibleEvent` for this case
            case let event as MessageNewEventDTO:
                guard let channelDTO = session.channel(cid: event.cid) else {
                    throw ClientError.ChannelDoesNotExist(cid: event.cid)
                }

                if shouldUnhide(channelDTO, for: event.message, session: session) {
                    channelDTO.isHidden = false
                }

            // New Message will unhide the channel
            // but we won't get `ChannelVisibleEvent` for this case
            case let event as NotificationNewMessageEventDTO:
                guard let channelDTO = session.channel(cid: event.channel.cid) else {
                    throw ClientError.ChannelDoesNotExist(cid: event.channel.cid)
                }

                if shouldUnhide(channelDTO, for: event.message, session: session) {
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

    // Campaign messages un-hide only when the campaign has `show_channels`, which the message does not carry.
    private func shouldUnhide(_ channelDTO: ChannelDTO, for message: MessageResponse, session: DatabaseSession) -> Bool {
        let isUnhidingType = [MessageType.regular.rawValue, MessageType.reply.rawValue].contains(message.type)
        let isSenderBlocked = session.currentUser?.blockedUserIds.contains(message.user.id) == true
        return isUnhidingType && !message.shadowed && message.campaignId == nil && !channelDTO.isBlocked && !isSenderBlocked
    }
}
