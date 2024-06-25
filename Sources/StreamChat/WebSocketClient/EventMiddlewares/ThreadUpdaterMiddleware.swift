//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

struct ThreadUpdaterMiddleware: EventMiddleware {
    func handle(event: Event, session: DatabaseSession) -> Event? {
        switch event {
        case let event as MessageReadEventDTO:
            if let threadDetails = event.payload.threadDetails {
                session.markThreadAsRead(parentMessageId: threadDetails.parentMessageId, userId: event.user.id, at: event.createdAt)
            }
        case let event as NotificationMarkUnreadEventDTO:
            // At the moment, this event does not return the thread id, so
            // this is the only way to identify that this event is related to a thread
            let isUnreadThread = event.lastReadMessageId == nil
            if isUnreadThread {
                session.markThreadAsUnread(for: event.firstUnreadMessageId, userId: event.user.id)
            }
        case let event as ThreadMessageNewEventDTO:
            let messagePayload = event.message
            guard let channelId = event.message.cid,
                  let parentMessageId = messagePayload.parentId,
                  let channelDTO = session.channel(cid: channelId) else {
                break
            }
            guard let message = try? session.saveMessage(
                payload: messagePayload,
                channelDTO: channelDTO,
                syncOwnReactions: false,
                cache: nil
            )
            else {
                break
            }

            /// Add message to thread replies
            let thread = session.thread(parentMessageId: parentMessageId, cache: nil)
            thread?.latestReplies.insert(message)
            thread?.updatedAt = Date().bridgeDate

            guard let currentUserId = session.currentUser?.user.id else {
                break
            }

            /// Increase the unread count of the thread
            let read = session.loadThreadRead(parentMessageId: parentMessageId, userId: currentUserId)
            read?.unreadMessagesCount += 1
        default:
            break
        }
        return event
    }
}
