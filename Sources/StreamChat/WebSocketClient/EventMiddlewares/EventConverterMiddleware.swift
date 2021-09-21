//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// The middleware responsible for converting event DTOs to events.
struct EventConverterMiddleware: EventMiddleware {
    func handle(event: Event, session: DatabaseSession) -> Event? {
        if let eventDTO = event as? EventWithPayload {
            return eventDTO.toDomainEvent(session: session)
        } else {
            return event
        }
    }
}
