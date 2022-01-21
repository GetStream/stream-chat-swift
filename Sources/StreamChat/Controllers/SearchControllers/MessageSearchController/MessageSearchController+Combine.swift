//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Combine

@available(iOS 13, *)
extension ChatMessageSearchController {
    /// A publisher emitting a new value every time the state of the controller changes.
    public var statePublisher: AnyPublisher<DataController.State, Never> {
        basePublishers.state.keepAlive(self)
    }

    /// A publisher emitting a new value every time the messages changes.
    public var messagesChangePublisher: AnyPublisher<[ListChange<ChatMessage>], Never> {
        basePublishers.messagesChange.keepAlive(self)
    }

    /// An internal backing object for all publicly available Combine publishers. We use it to simplify the way we expose
    /// publishers. Instead of creating custom `Publisher` types, we use `CurrentValueSubject` and `PassthroughSubject` internally,
    /// and expose the published values by mapping them to a read-only `AnyPublisher` type.
    class BasePublishers {
        /// The wrapped controller.
        unowned let controller: ChatMessageSearchController

        /// A backing subject for `statePublisher`.
        let state: CurrentValueSubject<DataController.State, Never>

        /// A backing subject for `messagesChangePublisher`.
        let messagesChange: PassthroughSubject<[ListChange<ChatMessage>], Never> = .init()

        init(controller: ChatMessageSearchController) {
            self.controller = controller
            state = .init(controller.state)

            controller.multicastDelegate.add(additionalDelegate: self)
        }
    }
}

@available(iOS 13, *)
extension ChatMessageSearchController.BasePublishers: ChatMessageSearchControllerDelegate {
    func controller(_ controller: DataController, didChangeState state: DataController.State) {
        self.state.send(state)
    }

    func controller(
        _ controller: ChatMessageSearchController,
        didChangeMessages changes: [ListChange<ChatMessage>]
    ) {
        messagesChange.send(changes)
    }
}
