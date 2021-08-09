//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI

@available(iOS 13, *)
extension ChatChannelMemberListController {
    /// A wrapper object that exposes the controller variables in the form of `ObservableObject` to be used in SwiftUI.
    public var observableObject: ObservableObject { .init(controller: self) }
    
    /// A wrapper object for `ChatChannelMemberListController` type which makes it possible to use the controller
    /// comfortably in SwiftUI.
    public class ObservableObject: SwiftUI.ObservableObject {
        /// The underlying controller. You can still access it and call methods on it.
        public let controller: ChatChannelMemberListController
        
        /// The channel members.
        @Published public private(set) var members: LazyCachedMapCollection<ChatChannelMember> = []
        
        /// The current state of the controller.
        @Published public private(set) var state: DataController.State
        
        /// Creates a new `ObservableObject` wrapper with the provided controller instance.
        init(controller: ChatChannelMemberListController) {
            self.controller = controller
            state = controller.state
            
            controller.multicastDelegate.additionalDelegates.append(AnyChatChannelMemberListControllerDelegate(self))
            
            members = controller.members
        }
    }
}

@available(iOS 13, *)
extension ChatChannelMemberListController.ObservableObject: ChatChannelMemberListControllerDelegate {
    public func memberListController(
        _ controller: ChatChannelMemberListController,
        didChangeMembers changes: [ListChange<ChatChannelMember>]
    ) {
        members = controller.members
    }
    
    public func controller(_ controller: DataController, didChangeState state: DataController.State) {
        self.state = state
    }
}
