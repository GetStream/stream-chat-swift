//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// A middleware which saves the incoming data from the Event to the database.
struct EventDataProcessorMiddleware<ExtraData: ExtraDataTypes>: EventMiddleware {
    func handle(event: Event, session: DatabaseSession) -> Event? {
        guard let eventWithPayload = (event as? EventWithPayload) else {
            return event
        }
        
        guard let payload = eventWithPayload.payload as? EventPayload<ExtraData> else {
            log.assertionFailure("""
            Type mismatch between `EventPayload.ExtraData` and `EventDataProcessorMiddleware.ExtraData`."
                EventPayload type: \(type(of: eventWithPayload.payload))
                EventDataProcessorMiddleware type: \(type(of: self))
            """)
            return nil
        }
        
        do {
            try session.saveEvent(payload: payload)
            log.debug("Event data saved to db: \(payload)")
            return event
        } catch {
            log.error("Failed saving incoming `Event` data to DB. Error: \(error)")
            return nil
        }
    }
}
