//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import CoreData

/// A middleware which updates `currentlyTypingMembers` for a specific channel based on received `TypingEvent`.
struct ChannelMemberTypingStateUpdaterMiddleware<ExtraData: ExtraDataTypes>: EventMiddleware {
    func handle(event: Event, session: DatabaseSession) -> Event? {
        guard
            let typingEvent = event as? TypingEvent,
            let channelDTO = session.channel(cid: typingEvent.cid),
            let memberDTO = session.member(userId: typingEvent.userId, cid: typingEvent.cid)
        else { return event }

        if typingEvent.isTyping {
            channelDTO.currentlyTypingMembers.insert(memberDTO)
        } else {
            channelDTO.currentlyTypingMembers.remove(memberDTO)
        }
        
        return event
    }
}
