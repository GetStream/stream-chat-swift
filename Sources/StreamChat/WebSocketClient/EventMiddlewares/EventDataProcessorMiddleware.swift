//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// A middleware which saves the incoming data from the Event to the database.
struct EventDataProcessorMiddleware<ExtraData: ExtraDataTypes>: EventMiddleware {
    let database: DatabaseContainer
    
    func handle(event: Event, completion: @escaping (Event?) -> Void) {
        guard let eventWithPayload = (event as? EventWithPayload) else {
            completion(event)
            return
        }
        
        guard let payload = eventWithPayload.payload as? EventPayload<ExtraData> else {
            log.assertationFailure("""
            Type mismatch between `EventPayload.ExtraData` and `EventDataProcessorMiddleware.ExtraData`."
                EventPayload type: \(type(of: eventWithPayload.payload))
                EventDataProcessorMiddleware type: \(type(of: self))
            """)
            completion(nil)
            return
        }
        
        database.write({ (session) in
            try session.saveEvent(payload: payload)
            log.debug("Event data saved to db: \(payload)")
            
        }, completion: { (error) in
            if let error = error {
                log.error("Failed saving incoming `Event` data to DB. Error: \(error)")
                completion(nil)
                return
            }
            completion(event)
        })
    }
}
