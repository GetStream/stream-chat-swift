//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

// https://getstream.io/chat/docs/ios-swift/message-reminders/

import Foundation
import StreamChat

@MainActor
final class Snippets_04_09_MessageReminders {
    var chatClient: ChatClient!
    var reminderListController: MessageReminderListController!

    func creatingAMessageReminder() {
        // Get a message controller for the message
        let messageController = chatClient.messageController(
            cid: ChannelId(type: .messaging, id: "general"),
            messageId: "message-id"
        )

        // Create a reminder with a specific due date
        messageController.createReminder(
            remindAt: Date().addingTimeInterval(3600) // Reminder in 1 hour
        ) { result in
            switch result {
            case .success(let reminder):
                print("Reminder created: \(reminder)")
            case .failure(let error):
                print("Failed to create reminder: \(error)")
            }
        }

        // Create a "Save for later" reminder without a specific time
        messageController.createReminder(
            remindAt: nil // No specific reminder time
        ) { result in
            switch result {
            case .success(let reminder):
                print("Message saved for later: \(reminder)")
            case .failure(let error):
                print("Failed to save message for later: \(error)")
            }
        }
    }

    func updatingAMessageReminder() {
        // Get a message controller for the message
        let messageController = chatClient.messageController(
            cid: ChannelId(type: .messaging, id: "general"),
            messageId: "message-id"
        )

        // Update a reminder with a new due date
        messageController.updateReminder(
            remindAt: Date().addingTimeInterval(7200) // New reminder time (2 hours)
        ) { result in
            switch result {
            case .success(let reminder):
                print("Reminder updated: \(reminder)")
            case .failure(let error):
                print("Failed to update reminder: \(error)")
            }
        }

        // Convert a timed reminder to "Save for later"
        messageController.updateReminder(
            remindAt: nil // Remove specific reminder time
        ) { result in
            switch result {
            case .success(let reminder):
                print("Reminder updated to save for later: \(reminder)")
            case .failure(let error):
                print("Failed to update reminder: \(error)")
            }
        }
    }

    func deletingAMessageReminder() {
        // Get a message controller for the message
        let messageController = chatClient.messageController(
            cid: ChannelId(type: .messaging, id: "general"),
            messageId: "message-id"
        )

        // Delete the reminder for the message
        messageController.deleteReminder { error in
            if let error {
                print("Failed to delete reminder: \(error)")
            } else {
                print("Reminder deleted successfully")
            }
        }
    }

    func queryingMessageReminders() {}

    // Get notified about reminders changes
    class ReminderListObserver: MessageReminderListControllerDelegate {
        let controller: MessageReminderListController

        init(chatClient: ChatClient) {
            // Create a reminder list controller
            controller = chatClient.messageReminderListController()
            controller.delegate = self

            // Sync reminders
            controller.synchronize { error in
                if let error = error {
                    print("Failed to synchronize reminders: \(error)")
                }
            }
        }

        func controller(
            _ controller: MessageReminderListController,
            didChangeReminders changes: [ListChange<MessageReminder>]
        ) {
            // Handle changes to reminders
            print("New reminders: \(controller.reminders)")
        }
    }

    func filteringReminders() {
        // Create filter for overdue reminders
        let overdueQuery = MessageReminderListQuery(
            filter: .overdue, // Same as .less(.remindAt, than: Date())
            sort: [.init(key: .remindAt, isAscending: false)]
        )

        // Create filter for upcoming reminders
        let upcomingQuery = MessageReminderListQuery(
            filter: .upcoming, // Same as .greater(.remindAt, than: Date())
            sort: [.init(key: .remindAt, isAscending: true)]
        )

        // Create filter for reminders with no due date (saved for later)
        let savedForLaterQuery = MessageReminderListQuery(
            filter: .isNil(.remindAt),
            sort: [.init(key: .createdAt, isAscending: false)]
        )

        // Apply the filter to the controller
        let reminderListController = chatClient.messageReminderListController(query: overdueQuery)
        reminderListController.delegate = self
        reminderListController.synchronize()
        suppressUnusedWarning(upcomingQuery, savedForLaterQuery)
    }

    func pagination() {
        // Load more reminders
        reminderListController.loadMoreReminders { result in
            switch result {
            case .success(let newReminders):
                print("Loaded \(newReminders.count) more reminders")
            case .failure(let error):
                print("Failed to load more reminders: \(error)")
            }
        }
    }

    func events() {}

    class ReminderEventsObserver: EventsControllerDelegate {
        let eventsController: EventsController

        init(chatClient: ChatClient) {
            eventsController = chatClient.eventsController()
            eventsController.delegate = self
        }

        func eventsController(_ controller: EventsController, didReceiveEvent event: any Event) {
            if let event = event as? MessageReminderCreatedEvent {
                print("Reminder created for message: \(event.messageId)")
            } else if let event = event as? MessageReminderUpdatedEvent {
                print("Reminder updated for message: \(event.messageId)")
            } else if let event = event as? MessageReminderDeletedEvent {
                print("Reminder deleted for message: \(event.messageId)")
            } else if let event = event as? MessageReminderDueEvent {
                print("Reminder due for message: \(event.messageId)")
            }
        }
    }
}

// The page sets `self` as the delegate of a reminder list controller
extension Snippets_04_09_MessageReminders: MessageReminderListControllerDelegate {
    func controller(
        _ controller: MessageReminderListController,
        didChangeReminders changes: [ListChange<MessageReminder>]
    ) {}
}
