//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// The middleware listens for `MemberEvent`s and updates `ChannelDTO`s accordingly.
struct MemberEventMiddleware<ExtraData: ExtraDataTypes>: EventMiddleware {
    func handle(event: Event, session: DatabaseSession) -> Event? {
        guard let memberEvent = event as? MemberEvent else { return event }
        
        do {
            switch memberEvent {
            case is MemberAddedEvent, is MemberUpdatedEvent:
                guard let eventWithMemberPayload = event as? EventWithMemberPayload,
                      let eventPayload = eventWithMemberPayload.payload as? EventPayload<ExtraData>,
                      let memberPayload = eventPayload.memberContainer?.member
                else {
                    break
                }
                try session.saveMember(payload: memberPayload, channelId: memberEvent.cid)
            case is MemberRemovedEvent:
                guard let channel = session.channel(cid: memberEvent.cid) else {
                    // No need to throw ChannelNotFound error here
                    break
                }
                
                guard let member = channel.members.first(where: { $0.user.id == memberEvent.userId }) else {
                    // No need to throw MemberNotFound error here
                    break
                }
                
                channel.members.remove(member)
            default:
                break
            }
        } catch {
            log.error("Failed to update channel members in the database, error: \(error)")
        }

        return event
    }
}
