//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

@available(iOS 13, *)
extension _ChatChannelMemberListController {
    /// A publisher emitting a new value every time the state of the controller changes.
    public var statePublisher: AnyPublisher<DataController.State, Never> {
        basePublishers.state.keepAlive(self)
    }
    
    /// A publisher emitting a new value every time the channel members change.
    public var membersChangesPublisher: AnyPublisher<[ListChange<_ChatChannelMember<ExtraData.User>>], Never> {
        basePublishers.membersChanges.keepAlive(self)
    }
    
    /// An internal backing object for all publicly available Combine publishers. We use it to simplify the way we expose
    /// publishers. Instead of creating custom `Publisher` types, we use `CurrentValueSubject` and `PassthroughSubject` internally,
    /// and expose the published values by mapping them to a read-only `AnyPublisher` type.
    class BasePublishers {
        /// The wrapped controller.
        unowned let controller: _ChatChannelMemberListController
        
        /// A backing subject for `statePublisher`.
        let state: CurrentValueSubject<DataController.State, Never>
        
        /// A backing subject for `membersChangesPublisher`.
        let membersChanges: PassthroughSubject<[ListChange<_ChatChannelMember<ExtraData.User>>], Never> = .init()
        
        init(controller: _ChatChannelMemberListController<ExtraData>) {
            self.controller = controller
            state = .init(controller.state)
            
            controller.multicastDelegate.additionalDelegates.append(AnyChatChannelMemberListControllerDelegate(self))
        }
    }
}

@available(iOS 13, *)
extension _ChatChannelMemberListController.BasePublishers: _ChatChannelMemberListControllerDelegate {
    func controller(_ controller: DataController, didChangeState state: DataController.State) {
        self.state.send(state)
    }
    
    func memberListController(
        _ controller: _ChatChannelMemberListController<ExtraData>,
        didChangeMembers changes: [ListChange<_ChatChannelMember<ExtraData.User>>]
    ) {
        membersChanges.send(changes)
    }
}
