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
                if let membership = channel.membership, membership.user.id == event.user.id {
                    channel.membership = nil
                }
                
                // If there are any MemberListQueries observing this channel,
                // we need to update them too
                member.queries.removeAll()
                
            case let event as NotificationAddedToChannelEventDTO:
                let channel = try session.saveChannel(payload: event.channel, query: nil)
                let member = try session.saveMember(payload: event.member, channelId: event.channel.cid)
                channel.membership = member
                
            case let event as NotificationRemovedFromChannelEventDTO:
                guard let channel = session.channel(cid: event.cid) else {
                    // No need to throw ChannelNotFound error here
                    log.debug("Channel \(event.cid) not found for NotificationRemovedFromChannelEventDTO")
                    break
                }
                
                guard let member = channel.members.first(where: { $0.user.id == event.member.user.id }) else {
                    // No need to throw MemberNotFound error here
                    log.debug("Member \(event.member.user.id) not found for NotificationRemovedFromChannelEventDTO")
                    break
                }
                
                // We remove the member from the channel
                channel.members.remove(member)
                if let membership = channel.membership, membership.user.id == event.member.user.id {
                    channel.membership = nil
                }
                
                // If there are any MemberListQueries observing this channel,
                // we need to update them too
                member.queries.removeAll()
                
            case let event as NotificationInviteAcceptedEventDTO:
                let channel = try session.saveChannel(payload: event.channel, query: nil)
                let member = try session.saveMember(payload: event.member, channelId: event.channel.cid)
                channel.membership = member
                
            case let event as NotificationInviteRejectedEventDTO:
                let channel = try session.saveChannel(payload: event.channel, query: nil)
                let member = try session.saveMember(payload: event.member, channelId: event.channel.cid)
                channel.membership = member
                
            case let event as NotificationInvitedEventDTO:
                guard let channel = session.channel(cid: event.cid) else {
                    // No need to throw ChannelNotFound error here
                    break
                }
                let member = try session.saveMember(payload: event.member, channelId: event.cid)
                channel.membership = member
            default:
                break
            }
        } catch {
            log.error("Failed to update channel members in the database, error: \(error)")
        }

        return event
    }
}
