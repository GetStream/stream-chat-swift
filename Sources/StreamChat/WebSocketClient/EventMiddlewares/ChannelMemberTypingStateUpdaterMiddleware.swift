//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import CoreData

/// A middleware which updates `currentlyTypingMembers` for a specific channel based on received `TypingEvent`.
struct ChannelMemberTypingStateUpdaterMiddleware<ExtraData: ExtraDataTypes>: EventMiddleware {
    func handle(event: Event, session: DatabaseSession) -> Event? {
        switch event {
        case let event as TypingEvent:
            guard
                let channelDTO = session.channel(cid: event.cid),
                let memberDTO = session.member(userId: event.userId, cid: event.cid)
            else { break }
            
            if event.isTyping {
                channelDTO.currentlyTypingMembers.insert(memberDTO)
            } else {
                channelDTO.currentlyTypingMembers.remove(memberDTO)
            }
        case let event as CleanUpTypingEvent:
            guard
                let channelDTO = session.channel(cid: event.cid),
                let memberDTO = session.member(userId: event.userId, cid: event.cid)
            else { break }
            
            channelDTO.currentlyTypingMembers.remove(memberDTO)
        default:
            break
        }
        
        return event
    }
}
