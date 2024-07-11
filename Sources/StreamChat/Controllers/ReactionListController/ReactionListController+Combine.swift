//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

extension ChatReactionListController {
    /// A publisher emitting a new value every time the state of the controller changes.
    public var statePublisher: AnyPublisher<DataController.State, Never> {
        basePublishers.state.keepAlive(self)
    }

    /// A publisher emitting a new value every time the reactions change.
    public var reactionsChangesPublisher: AnyPublisher<[ListChange<ChatMessageReaction>], Never> {
        basePublishers.reactionsChanges.keepAlive(self)
    }

    /// An internal backing object for all publicly available Combine publishers. We use it to simplify the way we expose
    /// publishers. Instead of creating custom `Publisher` types, we use `CurrentValueSubject` and `PassthroughSubject` internally,
    /// and expose the published values by mapping them to a read-only `AnyPublisher` type.
    class BasePublishers {
        /// The wrapped controller.
        unowned let controller: ChatReactionListController

        /// A backing subject for `statePublisher`.
        let state: CurrentValueSubject<DataController.State, Never>

        /// A backing subject for `reactionsChangesPublisher`.
        let reactionsChanges: PassthroughSubject<[ListChange<ChatMessageReaction>], Never> = .init()

        init(controller: ChatReactionListController) {
            self.controller = controller
            state = .init(controller.state)

            controller.multicastDelegate.add(additionalDelegate: self)
        }
    }
}

extension ChatReactionListController.BasePublishers: ChatReactionListControllerDelegate {
    func controller(_ controller: DataController, didChangeState state: DataController.State) {
        self.state.send(state)
    }

    func controller(
        _ controller: ChatReactionListController,
        didChangeReactions changes: [ListChange<ChatMessageReaction>]
    ) {
        reactionsChanges.send(changes)
    }
}
