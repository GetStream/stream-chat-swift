//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

struct ReminderUpdaterMiddleware: EventMiddleware {
    func handle(event: Event, session: DatabaseSession) -> Event? {
        switch event {
        case let event as ReminderCreatedEventDTO:
            guard let reminder = event.payload.reminder else { break }
            do {
                try session.saveReminder(payload: reminder, cache: nil)
            } catch {
                log.error("Failed to save reminder: \(error)")
            }
            
        case let event as ReminderUpdatedEventDTO:
            guard let reminder = event.payload.reminder else { break }
            do {
                try session.saveReminder(payload: reminder, cache: nil)
            } catch {
                log.error("Failed to update reminder: \(error)")
            }
            
        case let event as ReminderDueNotificationEventDTO:
            guard let reminder = event.payload.reminder else { break }
            do {
                try session.saveReminder(payload: reminder, cache: nil)
            } catch {
                log.error("Failed to update reminder in due notification: \(error)")
            }
            
        case let event as ReminderDeletedEventDTO:
            let messageId = event.messageId
            session.deleteReminder(messageId: messageId)
        default:
            break
        }
        return event
    }
}
