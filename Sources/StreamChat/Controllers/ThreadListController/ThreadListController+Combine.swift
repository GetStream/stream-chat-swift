//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

extension ChatThreadListController {
    /// A publisher emitting a new value every time the state of the controller changes.
    internal var statePublisher: AnyPublisher<DataController.State, Never> {
        basePublishers.state.keepAlive(self)
    }

    /// A publisher emitting a new value every time the reactions change.
    internal var threadsChangesPublisher: AnyPublisher<[ListChange<ChatThread>], Never> {
        basePublishers.threadsChanges.keepAlive(self)
    }

    /// An internal backing object for all publicly available Combine publishers. We use it to simplify the way we expose
    /// publishers. Instead of creating custom `Publisher` types, we use `CurrentValueSubject` and `PassthroughSubject` internally,
    /// and expose the published values by mapping them to a read-only `AnyPublisher` type.
    class BasePublishers {
        /// The wrapped controller.
        unowned let controller: ChatThreadListController

        /// A backing subject for `statePublisher`.
        let state: CurrentValueSubject<DataController.State, Never>

        /// A backing subject for `threadsChangesPublisher`.
        let threadsChanges: PassthroughSubject<[ListChange<ChatThread>], Never> = .init()

        init(controller: ChatThreadListController) {
            self.controller = controller
            state = .init(controller.state)

            controller.multicastDelegate.add(additionalDelegate: self)
        }
    }
}

extension ChatThreadListController.BasePublishers: ChatThreadListControllerDelegate {
    func controller(_ controller: DataController, didChangeState state: DataController.State) {
        self.state.send(state)
    }

    func controller(_ controller: ChatThreadListController, didChangeThreads changes: [ListChange<ChatThread>]) {
        threadsChanges.send(changes)
    }
}
