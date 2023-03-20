//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

/// The middleware listens for `UserWatchingEvent`s and updates `ChannelDTO`s accordingly.
struct UserWatchingEventMiddleware: EventMiddleware {
    func handle(event: Event, session: DatabaseSession) -> Event? {
        guard let userWatchingEvent = event as? UserWatchingEventDTO else { return event }

        do {
            guard let channelDTO = session.channel(cid: userWatchingEvent.cid) else {
                let currentUserId = session.currentUser?.user.id
                if userWatchingEvent.user.id == currentUserId {
                    log.info(
                        "Ignoring watcher event for channel \(userWatchingEvent.cid) and current user"
                            + "since Channel doesn't exist locally."
                    )
                } else {
                    log.error(
                        "Failed to save watcher event for channel \(userWatchingEvent.cid)"
                            + "and user \(userWatchingEvent.user.id) since Channel doesn't exist locally."
                    )
                }
                return event
            }

            channelDTO.watcherCount = Int64(userWatchingEvent.watcherCount)

            let userDTO = try session.saveUser(payload: userWatchingEvent.user)

            if let member = channelDTO.members.first(where: { $0.user.id == userDTO.id }) {
                member.user = userDTO
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
