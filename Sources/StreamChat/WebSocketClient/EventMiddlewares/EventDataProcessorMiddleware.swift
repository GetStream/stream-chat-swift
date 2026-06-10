//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A middleware which saves the incoming data from the Event to the database.
struct EventDataProcessorMiddleware: EventMiddleware {
    func handle(event: Event, session: DatabaseSession) -> Event? {
        if let connectedEvent = event as? ConnectedEvent, let me = connectedEvent.me {
            do {
                try session.saveCurrentUser(payload: me)
            } catch {
                log.error("Failed saving the current user from the connection event to DB. Error: \(error)")
            }
        }
        return event
    }

    func handle(event: Event, wsEvent: WSEvent, session: DatabaseSession) -> Event? {
        do {
            try session.saveEvent(event: wsEvent)
            log.debug("Event data saved to db: \(wsEvent.type)")
            return event
        } catch {
            log.error("Failed saving incoming `Event` data to DB. Error: \(error)")
            return nil
        }
    }
}
