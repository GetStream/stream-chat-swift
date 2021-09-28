//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// The middleware listens for `MemberEvent`s and updates `ChannelDTO`s accordingly.
struct MemberEventMiddleware: EventMiddleware {
    func handle(event: Event, session: DatabaseSession) -> Event? {
        do {
            var updatedChannelID: ChannelId?
            
            switch event {
            case let event as MemberUpdatedEventDTO:
                try session.saveMember(payload: event.member, channelId: event.cid)
                
                updatedChannelID = event.cid
                
            case let event as MemberAddedEventDTO:
                try session.saveMember(payload: event.member, channelId: event.cid)
                
                updatedChannelID = event.cid
            case let event as MemberRemovedEventDTO:
                guard let channel = session.channel(cid: event.cid) else {
                    // No need to throw ChannelNotFound error here
                    break
                }
                
                guard let member = channel.members.first(where: { $0.user.id == event.user.id }) else {
                    // No need to throw MemberNotFound error here
                    break
                }
                
                // We remove the member from the channel
                channel.members.remove(member)
                
                // If there are any MemberListQueries observing this channel,
                // we need to update them too
                member.queries.removeAll()
                
            case let event as NotificationAddedToChannelEventDTO:
                updatedChannelID = event.channel.cid
            case let event as NotificationRemovedFromChannelEventDTO:
                updatedChannelID = event.cid
            default:
                break
            }
            
            if let cid = updatedChannelID, let channelDTO = session.channel(cid: cid) {
                // Trigger channel update so channel list queries get updated
                let tmp = channelDTO.cid
                channelDTO.cid = tmp
            }
        } catch {
            log.error("Failed to update channel members in the database, error: \(error)")
        }

        return event
    }
}
