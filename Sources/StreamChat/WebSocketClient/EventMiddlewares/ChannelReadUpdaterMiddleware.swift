//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

/// A middleware which updates a channel's read events as websocket events arrive.
struct ChannelReadUpdaterMiddleware: EventMiddleware {
    func handle(event: Event, session: DatabaseSession) -> Event? {
        switch event {
        case let event as MessageNewEventDTO:
            increaseUnreadCountIfNeeded(
                for: event.cid,
                message: event.message,
                session: session
            )

        case let event as NotificationMessageNewEventDTO:
            increaseUnreadCountIfNeeded(
                for: event.channel.cid,
                message: event.message,
                session: session
            )
            
        case let event as MessageReadEventDTO:
            resetChannelRead(for: event.cid, userId: event.user.id, lastReadAt: event.createdAt, session: session)

        case let event as NotificationMarkReadEventDTO:
            resetChannelRead(for: event.cid, userId: event.user.id, lastReadAt: event.createdAt, session: session)

        case let event as NotificationMarkAllReadEventDTO:
            session.loadChannelReads(for: event.user.id).forEach { read in
                read.lastReadAt = event.createdAt
                read.unreadMessageCount = 0
            }
            
        default:
            break
        }

        return event
    }
    
    private func resetChannelRead(
        for cid: ChannelId,
        userId: UserId,
        lastReadAt: Date,
        session: DatabaseSession
    ) {
        session.markChannelAsRead(cid: cid, userId: userId, at: lastReadAt)
    }
    
    private func increaseUnreadCountIfNeeded(
        for cid: ChannelId,
        message: MessagePayload,
        session: DatabaseSession
    ) {
        guard let currentUserId = session.currentUser?.user.id, currentUserId != message.user.id else {
            log.debug("Own messages don't increase unread count")
            return
        }
        
        guard let read = session.loadChannelRead(cid: cid, userId: currentUserId) else {
            log.debug("There's no current user's read object for \(cid)")
            return
        }
        
        guard message.createdAt > read.lastReadAt else {
            log.debug("Current user's channel read for \(cid) already covers message \(message.id)")
            return
        }
        
        if message.parentId != nil && !message.showReplyInChannel {
            read.unreadThreadRepliesCount += 1
        } else if message.isSilent {
            read.unreadSilentMessagesCount += 1
        } else {
            read.unreadMessageCount += 1
        }
    }
}
