//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// The middleware listens for `UserWatchingEvent`s and updates `ChannelDTO`s accordingly.
struct UserWatchingEventMiddleware<ExtraData: ExtraDataTypes>: EventMiddleware {
    let database: DatabaseContainer
    
    func handle(event: Event, completion: @escaping (Event?) -> Void) {
        guard let userWatchingEvent = event as? UserWatchingEvent else {
            completion(event)
            return
        }
        
        database.write { session in
            guard let channelDTO = session.channel(cid: userWatchingEvent.cid) else {
                throw ClientError.ChannelDoesNotExist(cid: userWatchingEvent.cid)
            }
            
            guard let userDTO = session.user(id: userWatchingEvent.userId) else {
                throw ClientError.UserDoesNotExist(userId: userWatchingEvent.userId)
            }
            
            if userWatchingEvent.isStarted {
                channelDTO.watchers.insert(userDTO)
            } else {
                channelDTO.watchers.remove(userDTO)
            }
            channelDTO.watcherCount = Int64(userWatchingEvent.watcherCount)
        } completion: { error in
            if let error = error {
                log.error("Failed to update channel watchers in the database, error: \(error)")
            }
            completion(event)
        }
    }
}
