//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

/// The middleware responsible for converting event DTOs to events.
struct EventDTOConverterMiddleware: EventMiddleware {
    func handle(event: Event, session: DatabaseSession) -> Event? {
        if let eventDTO = event as? EventDTO {
            return eventDTO.toDomainEvent(session: session)
        } else {
            return event
        }
    }
}
