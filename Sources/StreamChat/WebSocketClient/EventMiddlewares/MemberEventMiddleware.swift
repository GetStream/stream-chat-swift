//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// The middleware listens for `MemberEvent`s and updates `ChannelDTO`s accordingly.
struct MemberEventMiddleware<ExtraData: ExtraDataTypes>: EventMiddleware {
    let database: DatabaseContainer
    
    func handle(event: Event, completion: @escaping (Event?) -> Void) {
        guard let memberEvent = event as? MemberEvent else {
            completion(event)
            return
        }
        
        database.write { session in
            switch memberEvent {
            case is MemberAddedEvent, is MemberUpdatedEvent:
                guard let eventWithMemberPayload = event as? EventWithMemberPayload,
                      let eventPayload = eventWithMemberPayload.payload as? EventPayload<ExtraData>,
                      let memberPayload = eventPayload.memberContainer?.member
                else {
                    return
                }
                try session.saveMember(payload: memberPayload, channelId: memberEvent.cid)
            case is MemberRemovedEvent:
                guard let channel = session.channel(cid: memberEvent.cid) else {
                    // No need to throw ChannelNotFound error here
                    return
                }
                
                guard let member = channel.members.first(where: { $0.user.id == memberEvent.userId }) else {
                    // No need to throw MemberNotFound error here
                    return
                }
                
                channel.members.remove(member)
            default:
                break
            }
        } completion: { error in
            if let error = error {
                log.error("Failed to update channel members in the database, error: \(error)")
            }
            completion(event)
        }
    }
}
