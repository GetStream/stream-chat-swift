//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

@available(iOS 13, *)
extension ChatMessageController {
    /// A publisher emitting a new value every time the state of the controller changes.
    public var statePublisher: AnyPublisher<DataController.State, Never> {
        basePublishers.state.keepAlive(self)
    }
    
    /// A publisher emitting a new value every time the message changes.
    public var messageChangePublisher: AnyPublisher<EntityChange<ChatMessage>, Never> {
        basePublishers.messageChange.keepAlive(self)
    }
    
    /// A publisher emitting a new value every time the list of the replies of the message has changes.
    public var repliesChangesPublisher: AnyPublisher<[ListChange<ChatMessage>], Never> {
        basePublishers.repliesChanges.keepAlive(self)
    }
    
    /// An internal backing object for all publicly available Combine publishers. We use it to simplify the way we expose
    /// publishers. Instead of creating custom `Publisher` types, we use `CurrentValueSubject` and `PassthroughSubject` internally,
    /// and expose the published values by mapping them to a read-only `AnyPublisher` type.
    class BasePublishers {
        /// The wrapper controller
        unowned let controller: ChatMessageController
        
        /// A backing subject for `statePublisher`.
        let state: CurrentValueSubject<DataController.State, Never>
        
        /// A backing subject for `messageChangePublisher`.
        let messageChange: PassthroughSubject<EntityChange<ChatMessage>, Never> = .init()
        
        /// A backing subject for `repliesChangesPublisher`.
        let repliesChanges: PassthroughSubject<[ListChange<ChatMessage>], Never> = .init()
        
        init(controller: ChatMessageController) {
            self.controller = controller
            state = .init(controller.state)
            controller.multicastDelegate.additionalDelegates.append(self)
        }
    }
}

@available(iOS 13, *)
extension ChatMessageController.BasePublishers: ChatMessageControllerDelegate {
    func controller(_ controller: DataController, didChangeState state: DataController.State) {
        self.state.send(state)
    }
    
    func messageController(
        _ controller: ChatMessageController,
        didChangeMessage change: EntityChange<ChatMessage>
    ) {
        messageChange.send(change)
    }
    
    func messageController(
        _ controller: ChatMessageController,
        didChangeReplies changes: [ListChange<ChatMessage>]
    ) {
        repliesChanges.send(changes)
    }
}
