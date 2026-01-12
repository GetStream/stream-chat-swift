//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

extension MessageReminderListController {
    /// A publisher emitting a new value every time the state of the controller changes.
    public var statePublisher: AnyPublisher<DataController.State, Never> {
        basePublishers.state.keepAlive(self)
    }

    /// A publisher emitting a new value every time the reminders change.
    public var remindersChangesPublisher: AnyPublisher<[ListChange<MessageReminder>], Never> {
        basePublishers.remindersChanges.keepAlive(self)
    }

    /// An internal backing object for all publicly available Combine publishers.
    class BasePublishers {
        /// A backing publisher for `statePublisher`.
        let state: CurrentValueSubject<DataController.State, Never>

        /// A backing publisher for `remindersChangesPublisher`.
        let remindersChanges: PassthroughSubject<[ListChange<MessageReminder>], Never>

        init(controller: MessageReminderListController) {
            state = .init(controller.state)
            remindersChanges = .init()

            controller.multicastDelegate.add(additionalDelegate: self)
        }
    }
}

extension MessageReminderListController.BasePublishers: MessageReminderListControllerDelegate {
    func controller(_ controller: DataController, didChangeState state: DataController.State) {
        self.state.send(state)
    }

    func controller(
        _ controller: MessageReminderListController,
        didChangeReminders changes: [ListChange<MessageReminder>]
    ) {
        remindersChanges.send(changes)
    }
}
