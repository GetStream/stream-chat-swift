//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Combine
import UIKit

@available(iOS 13, *)
extension _ChatMessageController {
    /// A publisher emitting a new value every time the state of the controller changes.
    public var statePublisher: AnyPublisher<DataController.State, Never> {
        basePublishers.state.keepAlive(self)
    }
    
    /// A publisher emitting a new value every time the message changes.
    public var messageChangePublisher: AnyPublisher<EntityChange<_ChatMessage<ExtraData>>, Never> {
        basePublishers.messageChange.keepAlive(self)
    }
    
    /// An internal backing object for all publicly available Combine publishers. We use it to simplify the way we expose
    /// publishers. Instead of creating custom `Publisher` types, we use `CurrentValueSubject` and `PassthroughSubject` internally,
    /// and expose the published values by mapping them to a read-only `AnyPublisher` type.
    class BasePublishers {
        /// The wrapper controller
        unowned let controller: _ChatMessageController
        
        /// A backing subject for `statePublisher`.
        let state: CurrentValueSubject<DataController.State, Never>
        
        /// A backing subject for `messageChangePublisher`.
        let messageChange: PassthroughSubject<EntityChange<_ChatMessage<ExtraData>>, Never> = .init()
        
        init(controller: _ChatMessageController<ExtraData>) {
            self.controller = controller
            state = .init(controller.state)
            
            controller.multicastDelegate.additionalDelegates.append(AnyMessageControllerDelegate(self))
        }
    }
}

@available(iOS 13, *)
extension _ChatMessageController.BasePublishers: _MessageControllerDelegate {
    func controller(_ controller: DataController, didChangeState state: DataController.State) {
        self.state.send(state)
    }
    
    func messageController(
        _ controller: _ChatMessageController<ExtraData>,
        didChangeMessage change: EntityChange<_ChatMessage<ExtraData>>
    ) {
        messageChange.send(change)
    }
}
