//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

@available(iOS 13, *)
extension ChatChannelMemberListController {
    /// A publisher emitting a new value every time the state of the controller changes.
    public var statePublisher: AnyPublisher<DataController.State, Never> {
        basePublishers.state.keepAlive(self)
    }
    
    /// A publisher emitting a new value every time the channel members change.
    public var membersChangesPublisher: AnyPublisher<[ListChange<ChatChannelMember>], Never> {
        basePublishers.membersChanges.keepAlive(self)
    }
    
    /// An internal backing object for all publicly available Combine publishers. We use it to simplify the way we expose
    /// publishers. Instead of creating custom `Publisher` types, we use `CurrentValueSubject` and `PassthroughSubject` internally,
    /// and expose the published values by mapping them to a read-only `AnyPublisher` type.
    class BasePublishers {
        /// The wrapped controller.
        unowned let controller: ChatChannelMemberListController
        
        /// A backing subject for `statePublisher`.
        let state: CurrentValueSubject<DataController.State, Never>
        
        /// A backing subject for `membersChangesPublisher`.
        let membersChanges: PassthroughSubject<[ListChange<ChatChannelMember>], Never> = .init()
        
        init(controller: ChatChannelMemberListController) {
            self.controller = controller
            state = .init(controller.state)
            
            controller.multicastDelegate.add(self)
        }
    }
}

@available(iOS 13, *)
extension ChatChannelMemberListController.BasePublishers: ChatChannelMemberListControllerDelegate {
    func controller(_ controller: DataController, didChangeState state: DataController.State) {
        self.state.send(state)
    }
    
    func memberListController(
        _ controller: ChatChannelMemberListController,
        didChangeMembers changes: [ListChange<ChatChannelMember>]
    ) {
        membersChanges.send(changes)
    }
}
