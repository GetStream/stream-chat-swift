//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// The middleware listens for `MemberEvent`s and updates `ChannelDTO`s accordingly.
struct MemberEventMiddleware: EventMiddleware {
    func handle(event: Event, session: DatabaseSession) -> Event? {
        do {
            switch event {
            case is MemberAddedEvent, is MemberUpdatedEvent:
                guard let eventWithMemberPayload = event as? EventWithPayload,
                      let eventPayload = eventWithMemberPayload.payload as? EventPayload,
                      let memberPayload = eventPayload.memberContainer?.member
                else {
                    break
                }
                try session.saveMember(payload: memberPayload, channelId: (event as! MemberEvent).cid)

            case let event as MemberRemovedEvent:
                guard let channel = session.channel(cid: event.cid) else {
                    // No need to throw ChannelNotFound error here
                    break
                }
                
                guard let member = channel.members.first(where: { $0.user.id == event.memberUserId }) else {
                    // No need to throw MemberNotFound error here
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

            // If the added/remove member was the current user, we should also reset the channel list queries, because
            // they usually depend on this.

            // Notification events are always about the current user
            let isMemberNotificationEvent = event is NotificationAddedToChannelEvent || event is NotificationRemovedFromChannelEvent

            // If we watch the channel, we don't receive notification events, but "normal" member events
            var isCurrentUserMemberEvent = false
            if let currentUserId = session.currentUser?.user.id {
                if event is MemberAddedEvent || event is MemberRemovedEvent,
                   (event as? MemberEvent)?.memberUserId == currentUserId {
                    isCurrentUserMemberEvent = true
                }
            }

            if isMemberNotificationEvent || isCurrentUserMemberEvent, let cid = (event as? ChannelSpecificEvent)?.cid {
                guard let channelDTO = session.channel(cid: cid) else {
                    throw ClientError.ChannelDoesNotExist(cid: cid)
                }
                channelDTO.queries = []
                channelDTO.needsRefreshQueries = true
            }

        } catch {
            log.error("Failed to update channel members in the database, error: \(error)")
        }

        return event
    }
}
