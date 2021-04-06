//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// A middleware which updates a channel's read events as websocket events arrive.
struct ChannelReadUpdaterMiddleware<ExtraData: ExtraDataTypes>: EventMiddleware {
    func handle(event: Event, session: DatabaseSession) -> Event? {
        if let event = event as? MessageReadEvent<ExtraData> {
            updateReadEvent(for: event.cid, userId: event.userId, lastReadAt: event.readAt, session: session)
        } else if let event = event as? NotificationMarkReadEvent<ExtraData> {
            updateReadEvent(for: event.cid, userId: event.userId, lastReadAt: event.readAt, session: session)
        } else if let event = event as? NotificationMarkAllReadEvent<ExtraData> {
            session.loadChannelReads(for: event.userId).forEach { read in
                read.lastReadAt = event.readAt
                read.unreadMessageCount = 0
            }
        }

        return event
    }
    
    private func updateReadEvent(
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
}
