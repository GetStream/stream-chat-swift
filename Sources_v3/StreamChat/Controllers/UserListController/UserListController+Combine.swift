//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Combine
import UIKit

@available(iOS 13, *)
extension _ChatUserListController {
    /// A publisher emitting a new value every time the state of the controller changes.
    public var statePublisher: AnyPublisher<DataController.State, Never> {
        basePublishers.state.keepAlive(self)
    }
    
    /// A publisher emitting a new value every time the list of the users matching the query changes.
    public var usersChangesPublisher: AnyPublisher<[ListChange<_ChatUser<ExtraData.User>>], Never> {
        basePublishers.usersChanges.keepAlive(self)
    }

    /// An internal backing object for all publicly available Combine publishers. We use it to simplify the way we expose
    /// publishers. Instead of creating custom `Publisher` types, we use `CurrentValueSubject` and `PassthroughSubject` internally,
    /// and expose the published values by mapping them to a read-only `AnyPublisher` type.
    class BasePublishers {
        /// The wrapper controller
        unowned let controller: _ChatUserListController
        
        /// A backing subject for `statePublisher`.
        let state: CurrentValueSubject<DataController.State, Never>
        
        /// A backing subject for `usersChangesPublisher`.
        let usersChanges: PassthroughSubject<[ListChange<_ChatUser<ExtraData.User>>], Never> = .init()
                
        init(controller: _ChatUserListController<ExtraData>) {
            self.controller = controller
            state = .init(controller.state)
            
            controller.multicastDelegate.additionalDelegates.append(AnyUserListControllerDelegate(self))
        }
    }
}

@available(iOS 13, *)
extension _ChatUserListController.BasePublishers: _ChatUserListControllerDelegate {
    func controller(_ controller: DataController, didChangeState state: DataController.State) {
        self.state.send(state)
    }
    
    func controller(
        _ controller: _ChatUserListController<ExtraData>,
        didChangeUsers changes: [ListChange<_ChatUser<ExtraData.User>>]
    ) {
        usersChanges.send(changes)
    }
}
