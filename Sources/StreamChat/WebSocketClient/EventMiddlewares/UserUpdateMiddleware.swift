//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// The middleware listens for `UserUpdatedEvent`s and updates the database accordingly.
struct UserUpdateMiddleware: EventMiddleware {
    func handle(event: Event, session: DatabaseSession) -> Event? {
        guard let userUpdatedEvent = event as? StreamChatUserUpdatedEvent,
              let user = userUpdatedEvent.user else { return event }
        do {
            try session.saveUser(payload: user, query: nil, cache: nil)
        } catch {
            log.error("Failed to update user in the database, error: \(error)")
        }
        return event
    }
}
