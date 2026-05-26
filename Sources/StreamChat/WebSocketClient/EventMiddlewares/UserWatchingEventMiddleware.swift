//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// The middleware listens for `UserWatchingEvent`s and updates `ChannelDTO`s accordingly.
struct UserWatchingEventMiddleware: EventMiddleware {
    func handle(event: Event, session: DatabaseSession) -> Event? {
        if let startEvent = event as? UserWatchingStartEventDTO {
            apply(cidString: startEvent.cid, userId: startEvent.user.id, watcherCount: startEvent.watcherCount, isStarted: true, session: session)
        } else if let stopEvent = event as? UserWatchingStopEventDTO {
            apply(cidString: stopEvent.cid, userId: stopEvent.user.id, watcherCount: stopEvent.watcherCount, isStarted: false, session: session)
        }
        return event
    }

    private func apply(cidString: String?, userId: UserId, watcherCount: Int, isStarted: Bool, session: DatabaseSession) {
        guard let cidString, let cid = try? ChannelId(cid: cidString) else { return }

        do {
            guard let channelDTO = session.channel(cid: cid) else {
                let currentUserId = session.currentUser?.user.id
                if userId == currentUserId {
                    log.info(
                        "Ignoring watcher event for channel \(cid) and current user"
                            + "since Channel doesn't exist locally."
                    )
                } else {
                    log.error(
                        "Failed to save watcher event for channel \(cid)"
                            + "and user \(userId) since Channel doesn't exist locally."
                    )
                }
                return
            }

            channelDTO.watcherCount = Int64(watcherCount)

            guard let userDTO = session.user(id: userId) else {
                throw ClientError.UserDoesNotExist(userId: userId)
            }

            if isStarted {
                channelDTO.watchers.insert(userDTO)
            } else {
                channelDTO.watchers.remove(userDTO)
            }
        } catch {
            log.error("Failed to update channel watchers in the database, error: \(error)")
        }
    }
}
