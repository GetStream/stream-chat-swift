//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// The middleware listens for `MessageUpdatedEventDTO` event and inserts or removes the message from the `ChannelDTO` based on restricted visibility.
struct MessageVisibilityEventMiddleware: EventMiddleware {
    func handle(event: Event, session: DatabaseSession) -> Event? {
        switch event {
        case let event as MessageUpdatedEventDTO:
            guard let currentUserId = session.currentUser?.user.id else { break }
            guard let channelDTO = session.channel(cid: event.cid) else { break }
            
            // Change visibility only when the updated message is part of the loaded list
            if let oldestLoadedDate = channelDTO.oldestMessageAt?.bridgeDate, event.message.createdAt < oldestLoadedDate {
                break
            }
            if let newestLoadedDate = channelDTO.newestMessageAt, event.message.createdAt > newestLoadedDate.bridgeDate {
                break
            }
            
            let restrictedVisibility = Set(event.message.restrictedVisibility)
            // Insert the message if restricted visibility includes the current user or restricted visibility was reset
            if restrictedVisibility.contains(currentUserId) || restrictedVisibility.isEmpty {
                guard let messageDTO = try? session.saveMessage(
                    payload: event.message,
                    channelDTO: channelDTO,
                    syncOwnReactions: false,
                    skipDraftUpdate: true,
                    cache: nil
                ) else { break }
                if messageDTO.parentMessageId == nil {
                    channelDTO.messages.insert(messageDTO)
                }
            } else if !restrictedVisibility.isEmpty, !restrictedVisibility.contains(currentUserId) {
                if let messageDTO = session.message(id: event.message.id), channelDTO.messages.contains(messageDTO) {
                    channelDTO.messages.remove(messageDTO)
                }
            }
        default:
            break
        }
        return event
    }
}
