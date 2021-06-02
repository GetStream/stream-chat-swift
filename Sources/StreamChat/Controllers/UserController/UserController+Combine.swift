//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

@available(iOS 13, *)
extension _ChatUserController {
    /// A publisher emitting a new value every time the state of the controller changes.
    public var statePublisher: AnyPublisher<DataController.State, Never> {
        basePublishers.state.keepAlive(self)
    }
    
    /// A publisher emitting a new value every time the user changes.
    public var userChangePublisher: AnyPublisher<EntityChange<_ChatUser<ExtraData.User>>, Never> {
        basePublishers.userChange.keepAlive(self)
    }
    
    /// An internal backing object for all publicly available Combine publishers. We use it to simplify the way we expose
    /// publishers. Instead of creating custom `Publisher` types, we use `CurrentValueSubject` and `PassthroughSubject` internally,
    /// and expose the published values by mapping them to a read-only `AnyPublisher` type.
    class BasePublishers {
        /// The wrapped controller.
        unowned let controller: _ChatUserController
        
        /// A backing subject for `statePublisher`.
        let state: CurrentValueSubject<DataController.State, Never>
        
        /// A backing subject for `userChangePublisher`.
        let userChange: PassthroughSubject<EntityChange<_ChatUser<ExtraData.User>>, Never> = .init()
        
        init(controller: _ChatUserController<ExtraData>) {
            self.controller = controller
            state = .init(controller.state)
            
            controller.multicastDelegate.additionalDelegates.append(AnyChatUserControllerDelegate(self))
        }
    }
}

@available(iOS 13, *)
extension _ChatUserController.BasePublishers: _ChatUserControllerDelegate {
    func controller(_ controller: DataController, didChangeState state: DataController.State) {
        self.state.send(state)
    }

    func userController(
        _ controller: _ChatUserController<ExtraData>,
        didUpdateUser change: EntityChange<_ChatUser<ExtraData.User>>
    ) {
        userChange.send(change)
    }
}
