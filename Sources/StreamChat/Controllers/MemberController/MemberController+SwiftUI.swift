//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI

@available(iOS 13, *)
extension ChatChannelMemberController {
    /// A wrapper object that exposes the controller variables in the form of `ObservableObject` to be used in SwiftUI.
    public var observableObject: ObservableObject { .init(controller: self) }
    
    /// A wrapper object for `ChatChannelMemberController` type which makes it possible to use the controller
    /// comfortably in SwiftUI.
    public class ObservableObject: SwiftUI.ObservableObject {
        /// The underlying controller. You can still access it and call methods on it.
        public let controller: ChatChannelMemberController
        
        /// The channel member.
        @Published public private(set) var member: ChatChannelMember?
        
        /// The current state of the controller.
        @Published public private(set) var state: DataController.State
        
        /// Creates a new `ObservableObject` wrapper with the provided controller instance.
        init(controller: ChatChannelMemberController) {
            self.controller = controller
            state = controller.state
            
            controller.multicastDelegate.add(self)
            
            member = controller.member
        }
    }
}

@available(iOS 13, *)
extension ChatChannelMemberController.ObservableObject: ChatChannelMemberControllerDelegate {
    public func memberController(
        _ controller: ChatChannelMemberController,
        didUpdateMember change: EntityChange<ChatChannelMember>
    ) {
        member = change.item
    }
    
    public func controller(_ controller: DataController, didChangeState state: DataController.State) {
        self.state = state
    }
}
