//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// The middleware listens for `UserWatchingEvent`s and updates `ChannelDTO`s accordingly.
struct UserWatchingEventMiddleware<ExtraData: ExtraDataTypes>: EventMiddleware {
    func handle(event: Event, session: DatabaseSession) -> Event? {
        guard let userWatchingEvent = event as? UserWatchingEvent else { return event }
        
        do {
            guard let channelDTO = session.channel(cid: userWatchingEvent.cid) else {
                let currentUserId = session.currentUser?.user.id
                if userWatchingEvent.userId == currentUserId {
                    log.info(
                        "Ignoring watcher event for channel \(userWatchingEvent.cid) and current user"
                            + "since Channel doesn't exist locally."
                    )
                } else {
                    log.error(
                        "Failed to save watcher event for channel \(userWatchingEvent.cid)"
                            + "and user \(userWatchingEvent.userId) since Channel doesn't exist locally."
                    )
                }
                return event
            }

            channelDTO.watcherCount = Int64(userWatchingEvent.watcherCount)
            
            guard let userDTO = session.user(id: userWatchingEvent.userId) else {
                throw ClientError.UserDoesNotExist(userId: userWatchingEvent.userId)
            }
            
            if userWatchingEvent.isStarted {
                channelDTO.watchers.insert(userDTO)
            } else {
                channelDTO.watchers.remove(userDTO)
            }
        } catch {
            log.error("Failed to update channel watchers in the database, error: \(error)")
        }

        return event
    }
}
