//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreData

/// A middleware which updates `currentlyTypingUsers` for a specific channel based on received `TypingEvent`.
struct UserTypingStateUpdaterMiddleware: EventMiddleware {
    func handle(event: Event, session: DatabaseSession) -> Event? {
        switch event {
        case let event as TypingEventDTO:
            guard event.parentId == nil else { break }
            guard let channelDTO = session.channel(cid: event.cid) else { break }

            let userDTO: UserDTO?
            if let existingUser = session.user(id: event.user.id) {
                userDTO = existingUser
            } else {
                userDTO = try? session.saveUser(payload: event.user, query: nil, cache: nil)
            }

            guard let userDTO else { break }

            if event.isTyping {
                if let member = event.member {
                    channelDTO.updateTypingMemberInfo(userId: userDTO.id, from: member)
                }
                channelDTO.currentlyTypingUsers.insert(userDTO)
            } else {
                channelDTO.currentlyTypingUsers.remove(userDTO)
                channelDTO.clearTypingMemberInfo(userId: userDTO.id)
            }

        case let event as CleanUpTypingEvent:
            guard
                let channelDTO = session.channel(cid: event.cid),
                let userDTO = session.user(id: event.userId)
            else { break }

            channelDTO.currentlyTypingUsers.remove(userDTO)
            channelDTO.clearTypingMemberInfo(userId: event.userId)

        default:
            break
        }

        return event
    }
}
