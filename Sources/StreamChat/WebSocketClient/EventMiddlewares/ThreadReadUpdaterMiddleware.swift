//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

struct ThreadReadUpdaterMiddleware: EventMiddleware {
    func handle(event: Event, session: DatabaseSession) -> Event? {
        switch event {
        case let event as MessageReadEventDTO:
            if let thread = event.payload.thread {
                session.markThreadAsRead(parentMessageId: thread.parentMessageId, userId: event.user.id, at: event.createdAt)
            }
        case let event as NotificationMarkUnreadEventDTO:
            // TODO: At the moment, the thread is not returned in the event,
            // and I found that if lastReadMessageId is not present, it means it is a thread
            if event.lastReadMessageId == nil {
                session.markThreadAsUnread(for: event.firstUnreadMessageId, userId: event.user.id)
            }
        default:
            break
        }
        return event
    }
}
