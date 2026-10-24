//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

struct ScheduledMessageUpdaterMiddleware: EventMiddleware {
    func handle(event: Event, session: DatabaseSession) -> Event? {
        switch event {
        case let event as ScheduledMessageCreatedEventDTO:
            save(event.scheduledMessage, session: session)

        case let event as ScheduledMessageUpdatedEventDTO:
            save(event.scheduledMessage, session: session)

        case let event as ScheduledMessageFailedEventDTO:
            save(event.scheduledMessage, session: session)

        case let event as ScheduledMessageDeletedEventDTO:
            event.scheduledMessage.map { session.deleteScheduledMessage(id: $0.id) }

        case let event as ScheduledMessageSentEventDTO:
            event.scheduledMessage.map { session.deleteScheduledMessage(id: $0.id) }

        default:
            break
        }
        return event
    }

    private func save(_ payload: ScheduledMessageResponse?, session: DatabaseSession) {
        guard let payload else { return }
        do {
            try session.saveScheduledMessage(payload: payload)
        } catch {
            log.error("Failed to save scheduled message: \(error)")
        }
    }
}
