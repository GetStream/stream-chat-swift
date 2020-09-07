//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Combine
import UIKit

@available(iOS 13, *)
extension MessageControllerGeneric {
    /// A publisher emitting a new value every time the state of the controller changes.
    public var statePublisher: AnyPublisher<Controller.State, Never> {
        basePublishers.state.keepAlive(self)
    }
    
    /// A publisher emitting a new value every time the message changes.
    public var messageChangePublisher: AnyPublisher<EntityChange<MessageModel<ExtraData>>, Never> {
        basePublishers.messageChange.keepAlive(self)
    }
    
    /// An internal backing object for all publicly available Combine publishers. We use it to simplify the way we expose
    /// publishers. Instead of creating custom `Publisher` types, we use `CurrentValueSubject` and `PassthroughSubject` internally,
    /// and expose the published values by mapping them to a read-only `AnyPublisher` type.
    class BasePublishers {
        /// The wrapper controller
        unowned let controller: MessageControllerGeneric
        
        /// A backing subject for `statePublisher`.
        let state: CurrentValueSubject<Controller.State, Never>
        
        /// A backing subject for `messageChangePublisher`.
        let messageChange: PassthroughSubject<EntityChange<MessageModel<ExtraData>>, Never> = .init()
        
        init(controller: MessageControllerGeneric<ExtraData>) {
            self.controller = controller
            state = .init(controller.state)
            
            controller.multicastDelegate.additionalDelegates.append(AnyMessageControllerDelegate(self))
            
            if controller.state == .inactive {
                // Start updating and load the current data
                controller.startUpdating()
            }
        }
    }
}

@available(iOS 13, *)
extension MessageControllerGeneric.BasePublishers: MessageControllerDelegateGeneric {
    func controller(_ controller: Controller, didChangeState state: Controller.State) {
        self.state.send(state)
    }
    
    func messageController(
        _ controller: MessageControllerGeneric<ExtraData>,
        didChangeMessage change: EntityChange<MessageModel<ExtraData>>
    ) {
        messageChange.send(change)
    }
}
