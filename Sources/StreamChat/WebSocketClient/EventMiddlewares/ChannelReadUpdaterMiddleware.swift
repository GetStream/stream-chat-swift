//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// A middleware which updates a channel's read events as websocket events arrive.
struct ChannelReadUpdaterMiddleware<ExtraData: ExtraDataTypes>: EventMiddleware {
    func handle(event: Event, session: DatabaseSession) -> Event? {
        switch event {
        case let event as MessageNewEvent:
            increaseUnreadCountIfNeeded(
                for: event.cid,
                userId: event.userId,
                newMessageAt: event.createdAt,
                session: session
            )
            
        case let event as NotificationMessageNewEvent:
            increaseUnreadCountIfNeeded(
                for: event.cid,
                userId: event.userId,
                newMessageAt: event.createdAt,
                session: session
            )
            
        case let event as MessageReadEvent:
            resetChannelRead(for: event.cid, userId: event.userId, lastReadAt: event.readAt, session: session)

        case let event as NotificationMarkReadEvent:
            resetChannelRead(for: event.cid, userId: event.userId, lastReadAt: event.readAt, session: session)

        case let event as NotificationMarkAllReadEvent:
            session.loadChannelReads(for: event.userId).forEach { read in
                read.lastReadAt = event.readAt
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
        if let read = session.loadChannelRead(cid: cid, userId: userId) {
            read.lastReadAt = lastReadAt
            read.unreadMessageCount = 0
        } else {
            log.error("Failed to update channel read for cid \(cid) and userId \(userId).")
        }
    }
    
    private func increaseUnreadCountIfNeeded(
        for cid: ChannelId,
        userId: UserId,
        newMessageAt: Date,
        session: DatabaseSession
    ) {
        guard let currentUserId = session.currentUser?.user.id, currentUserId != userId else {
            // Own messages don't increase unread count
            return
        }
        
        // Try to get the existing channel read for the CURRENT user
        if let read = session.loadChannelRead(cid: cid, userId: currentUserId) {
            if newMessageAt > read.lastReadAt {
                read.unreadMessageCount += 1
            }
        } else {
            log.error(
                "Can't increase unread count for \(cid) because the `ChannelReadDTO` for " +
                    "the current user doesn't exist."
            )
        }
    }
}
