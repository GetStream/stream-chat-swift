//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI

@available(iOS 13, *)
extension _ChatChannelMemberController {
    /// A wrapper object that exposes the controller variables in the form of `ObservableObject` to be used in SwiftUI.
    public var observableObject: ObservableObject { .init(controller: self) }
    
    /// A wrapper object for `_ChatChannelMemberController` type which makes it possible to use the controller
    /// comfortably in SwiftUI.
    public class ObservableObject: SwiftUI.ObservableObject {
        /// The underlying controller. You can still access it and call methods on it.
        public let controller: _ChatChannelMemberController
        
        /// The channel member.
        @Published public private(set) var member: _ChatChannelMember<ExtraData.User>?
        
        /// The current state of the controller.
        @Published public private(set) var state: DataController.State
        
        /// Creates a new `ObservableObject` wrapper with the provided controller instance.
        init(controller: _ChatChannelMemberController<ExtraData>) {
            self.controller = controller
            state = controller.state
            
            controller.multicastDelegate.additionalDelegates.append(AnyChatChannelMemberControllerDelegate(self))
            
            member = controller.member
        }
    }
}

@available(iOS 13, *)
extension _ChatChannelMemberController.ObservableObject: _ChatChannelMemberControllerDelegate {
    public func memberController(
        _ controller: _ChatChannelMemberController<ExtraData>,
        didUpdateMember change: EntityChange<_ChatChannelMember<ExtraData.User>>
    ) {
        member = change.item
    }
    
    public func controller(_ controller: DataController, didChangeState state: DataController.State) {
        self.state = state
    }
}
