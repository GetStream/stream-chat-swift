//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

/// The middleware listens for `MemberEvent`s and updates `ChannelDTO`s accordingly.
struct MemberEventMiddleware: EventMiddleware {
    func handle(event: Event, session: DatabaseSession) -> Event? {
        do {
            switch event {
            case let event as MemberUpdatedEventDTO:
                try session.saveMember(payload: event.member, channelId: event.cid)
                
            case let event as MemberAddedEventDTO:
                try session.saveMember(payload: event.member, channelId: event.cid)

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
                _ = try session.saveChannel(payload: event.channel, query: nil)
                
            case let event as NotificationRemovedFromChannelEventDTO:
                guard let channel = session.channel(cid: event.cid) else {
                    // No need to throw ChannelNotFound error here
                    log.debug("Channel \(event.cid) not found for MemberRemovedEventDTO")
                    break
                }
                
                guard let member = channel.members.first(where: { $0.user.id == event.member.user.id }) else {
                    // No need to throw MemberNotFound error here
                    log.debug("Member \(event.member.user.id) not found for MemberRemovedEventDTO")
                    break
                }
                
                // We remove the member from the channel
                channel.members.remove(member)
                
                // If there are any MemberListQueries observing this channel,
                // we need to update them too
                member.queries.removeAll()
            default:
                break
            }
        } catch {
            log.error("Failed to update channel members in the database, error: \(error)")
        }

        return event
    }
}
