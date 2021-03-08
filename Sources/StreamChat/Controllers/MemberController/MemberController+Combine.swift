//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Combine
import UIKit

@available(iOS 13, *)
extension _ChatChannelMemberController {
    /// A publisher emitting a new value every time the state of the controller changes.
    public var statePublisher: AnyPublisher<DataController.State, Never> {
        basePublishers.state.keepAlive(self)
    }
    
    /// A publisher emitting a new value every time the member changes.
    public var memberChangePublisher: AnyPublisher<EntityChange<_ChatChannelMember<ExtraData.User>>, Never> {
        basePublishers.memberChange.keepAlive(self)
    }
    
    /// An internal backing object for all publicly available Combine publishers. We use it to simplify the way we expose
    /// publishers. Instead of creating custom `Publisher` types, we use `CurrentValueSubject` and `PassthroughSubject` internally,
    /// and expose the published values by mapping them to a read-only `AnyPublisher` type.
    class BasePublishers {
        /// The wrapped controller.
        unowned let controller: _ChatChannelMemberController
        
        /// A backing subject for `statePublisher`.
        let state: CurrentValueSubject<DataController.State, Never>
        
        /// A backing subject for `memberChangePublisher`.
        let memberChange: PassthroughSubject<EntityChange<_ChatChannelMember<ExtraData.User>>, Never> = .init()
        
        init(controller: _ChatChannelMemberController<ExtraData>) {
            self.controller = controller
            state = .init(controller.state)
            
            controller.multicastDelegate.additionalDelegates.append(AnyChatChannelMemberControllerDelegate(self))
        }
    }
}

@available(iOS 13, *)
extension _ChatChannelMemberController.BasePublishers: _ChatChannelMemberControllerDelegate {
    func controller(_ controller: DataController, didChangeState state: DataController.State) {
        self.state.send(state)
    }
    
    func memberController(
        _ controller: _ChatChannelMemberController<ExtraData>,
        didUpdateMember change: EntityChange<_ChatChannelMember<ExtraData.User>>
    ) {
        memberChange.send(change)
    }
}
