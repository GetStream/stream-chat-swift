//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// A middleware which updates a channel's read events as websocket events arrive.
struct ChannelReadUpdaterMiddleware: EventMiddleware {
    func handle(event: Event, session: DatabaseSession) -> Event? {
        guard let eventWithPayload = (event as? EventWithPayload) else {
            return event
        }

        guard let payload = eventWithPayload.payload as? EventPayload else {
            log.error("""
            Type mismatch between `EventPayload` and `EventDataProcessorMiddleware`."
                EventPayload type: \(type(of: eventWithPayload.payload))
                EventDataProcessorMiddleware type: \(type(of: self))
            """)
            return nil
        }

        switch event {
        case let event as MessageNewEvent:
            guard let message = payload.message else {
                return event
            }
            increaseUnreadCountIfNeeded(
                for: event.cid,
                message: message,
                session: session
            )

        case let event as NotificationMessageNewEvent:
            guard let message = payload.message else {
                return event
            }
            increaseUnreadCountIfNeeded(
                for: event.cid,
                message: message,
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
            // We have a read object saved, we can update it
            read.lastReadAt = lastReadAt
            read.unreadMessageCount = 0
        } else if let channel = session.channel(cid: cid), channel.members.contains(where: { $0.user.id == userId }) {
            // We don't have a read object, but the user is a member.
            // We can safely create a read object for the user
            do {
                _ = try session.saveChannelRead(cid: cid, userId: userId, lastReadAt: lastReadAt, unreadMessageCount: 0)
            } catch {
                log.error("Failed to update channel read for cid \(cid) and userId \(userId): \(error)")
            }
        } else {
            // If we don't have a read object saved for the user,
            // and the user is not a member,
            // we can safely discard this event.
            log.debug(
                "Discarding read event for cid \(cid) and userId \(userId). "
                    + "This is expected when the user calls `markRead` but they're not a member."
            )
        }
    }
    
    private func increaseUnreadCountIfNeeded(
        for cid: ChannelId,
        message: MessagePayload,
        session: DatabaseSession
    ) {
        // Silent messages don't increase unread count
        if message.isSilent {
            return
        }

        // Thread replies don't increase unread count
        if message.parentId != nil && !message.showReplyInChannel {
            return
        }

        // Own messages don't increase unread count
        guard let currentUserId = session.currentUser?.user.id, currentUserId != message.user.id else {
            return
        }

        // Try to get the existing channel read for the current user
        if let read = session.loadChannelRead(cid: cid, userId: currentUserId) {
            if message.createdAt > read.lastReadAt {
                read.unreadMessageCount += 1
            }
        } else {
            log.info(
                "Can't increase unread count for \(cid) because the `ChannelReadDTO` for " +
                    "the current user doesn't exist."
            )
        }
    }
}
