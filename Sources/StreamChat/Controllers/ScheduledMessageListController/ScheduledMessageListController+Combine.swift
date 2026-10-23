//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

extension ScheduledMessageListController {
    /// A publisher emitting a new value every time the state of the controller changes.
    public var statePublisher: AnyPublisher<DataController.State, Never> {
        basePublishers.state.keepAlive(self)
    }

    /// A publisher emitting a new value every time the scheduled messages change.
    public var scheduledMessagesChangesPublisher: AnyPublisher<[ListChange<ScheduledMessage>], Never> {
        basePublishers.scheduledMessagesChanges.keepAlive(self)
    }

    /// An internal backing object for all publicly available Combine publishers.
    class BasePublishers {
        /// A backing publisher for `statePublisher`.
        let state: CurrentValueSubject<DataController.State, Never>

        /// A backing publisher for `scheduledMessagesChangesPublisher`.
        let scheduledMessagesChanges: PassthroughSubject<[ListChange<ScheduledMessage>], Never>

        init(controller: ScheduledMessageListController) {
            state = .init(controller.state)
            scheduledMessagesChanges = .init()

            controller.multicastDelegate.add(additionalDelegate: self)
        }
    }
}

extension ScheduledMessageListController.BasePublishers: ScheduledMessageListControllerDelegate {
    func controller(_ controller: DataController, didChangeState state: DataController.State) {
        self.state.send(state)
    }

    func controller(
        _ controller: ScheduledMessageListController,
        didChangeScheduledMessages changes: [ListChange<ScheduledMessage>]
    ) {
        scheduledMessagesChanges.send(changes)
    }
}
