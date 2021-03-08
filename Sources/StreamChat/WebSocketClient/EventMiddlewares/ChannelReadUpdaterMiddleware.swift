//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// A middleware which updates a channel's read events as websocket events arrive.
struct ChannelReadUpdaterMiddleware<ExtraData: ExtraDataTypes>: EventMiddleware {
    let database: DatabaseContainer
    
    func handle(event: Event, completion: @escaping (Event?) -> Void) {
        if let event = event as? MessageReadEvent<ExtraData> {
            updateReadEvent(for: event.cid, userId: event.userId, lastReadAt: event.readAt) { completion(event) }
        } else if let event = event as? NotificationMarkReadEvent<ExtraData> {
            updateReadEvent(for: event.cid, userId: event.userId, lastReadAt: event.readAt) { completion(event) }
        } else if let event = event as? NotificationMarkAllReadEvent<ExtraData> {
            database.write({ session in
                session.loadChannelReads(for: event.userId).forEach { read in
                    read.lastReadAt = event.readAt
                    read.unreadMessageCount = 0
                }
            }, completion: { error in
                if let error = error {
                    log.error("Failed to update channel reads for userId \(event.userId), error: \(error)")
                }
                completion(event)
            })
        } else {
            completion(event)
        }
    }
    
    private func updateReadEvent(for cid: ChannelId, userId: UserId, lastReadAt: Date, completion: @escaping () -> Void) {
        database.write({ session in
            if let read = session.loadChannelRead(cid: cid, userId: userId) {
                read.lastReadAt = lastReadAt
                read.unreadMessageCount = 0
            }
        }, completion: { error in
            if let error = error {
                log.error("Failed to update channel read for cid \(cid) and userId \(userId), error: \(error)")
            }
            completion()
        })
    }
}
