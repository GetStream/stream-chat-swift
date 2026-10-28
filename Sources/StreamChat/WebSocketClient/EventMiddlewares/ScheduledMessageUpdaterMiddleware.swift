//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

struct ScheduledMessageUpdaterMiddleware: EventMiddleware {
    func handle(event: Event, session: DatabaseSession) -> Event? {
        event
    }

    func handle(event: Event, wsEvent: WSEvent, session: DatabaseSession) -> Event? {
        switch wsEvent {
        case let .typeScheduledMessageCreatedEvent(value):
            save(value.scheduledMessage, session: session)

        case let .typeScheduledMessageUpdatedEvent(value):
            save(value.scheduledMessage, session: session)

        case let .typeScheduledMessageFailedEvent(value):
            save(value.scheduledMessage, session: session)

        case let .typeScheduledMessageDeletedEvent(value):
            value.scheduledMessage.map { session.deleteScheduledMessage(id: $0.id) }

        case let .typeScheduledMessageSentEvent(value):
            value.scheduledMessage.map { session.deleteScheduledMessage(id: $0.id) }

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
