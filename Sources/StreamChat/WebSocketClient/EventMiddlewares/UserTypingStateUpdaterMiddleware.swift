//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import CoreData

/// A middleware which updates `currentlyTypingUsers` for a specific channel based on received `TypingEvent`.
struct UserTypingStateUpdaterMiddleware: EventMiddleware {
    func handle(event: Event, session: DatabaseSession) -> Event? {
        switch event {
        case let event as TypingEventDTO:
            guard
                let channelDTO = session.channel(cid: event.cid),
                let userDTO = session.user(id: event.user.id)
            else { break }

            if event.isTyping {
                channelDTO.currentlyTypingUsers.insert(userDTO)
            } else {
                channelDTO.currentlyTypingUsers.remove(userDTO)
            }

        case let event as CleanUpTypingEvent:
            guard
                let channelDTO = session.channel(cid: event.cid),
                let userDTO = session.user(id: event.userId)
            else { break }

            channelDTO.currentlyTypingUsers.remove(userDTO)

        default:
            break
        }

        return event
    }
}
