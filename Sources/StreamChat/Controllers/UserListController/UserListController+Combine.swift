//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

@available(iOS 13, *)
extension ChatUserListController {
    /// A publisher emitting a new value every time the state of the controller changes.
    public var statePublisher: AnyPublisher<DataController.State, Never> {
        basePublishers.state.keepAlive(self)
    }
    
    /// A publisher emitting a new value every time the list of the users matching the query changes.
    public var usersChangesPublisher: AnyPublisher<[ListChange<ChatUser>], Never> {
        basePublishers.usersChanges.keepAlive(self)
    }

    /// An internal backing object for all publicly available Combine publishers. We use it to simplify the way we expose
    /// publishers. Instead of creating custom `Publisher` types, we use `CurrentValueSubject` and `PassthroughSubject` internally,
    /// and expose the published values by mapping them to a read-only `AnyPublisher` type.
    class BasePublishers {
        /// The wrapper controller
        unowned let controller: ChatUserListController
        
        /// A backing subject for `statePublisher`.
        let state: CurrentValueSubject<DataController.State, Never>
        
        /// A backing subject for `usersChangesPublisher`.
        let usersChanges: PassthroughSubject<[ListChange<ChatUser>], Never> = .init()
                
        init(controller: ChatUserListController) {
            self.controller = controller
            state = .init(controller.state)
            
            controller.multicastDelegate.additionalDelegates.append(self)
        }
    }
}

@available(iOS 13, *)
extension ChatUserListController.BasePublishers: ChatUserListControllerDelegate {
    func controller(_ controller: DataController, didChangeState state: DataController.State) {
        self.state.send(state)
    }
    
    func controller(
        _ controller: ChatUserListController,
        didChangeUsers changes: [ListChange<ChatUser>]
    ) {
        usersChanges.send(changes)
    }
}
