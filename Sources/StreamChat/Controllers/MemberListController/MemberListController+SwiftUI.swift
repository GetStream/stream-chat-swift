//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI

@available(iOS 13, *)
extension _ChatChannelMemberListController {
    /// A wrapper object that exposes the controller variables in the form of `ObservableObject` to be used in SwiftUI.
    public var observableObject: ObservableObject { .init(controller: self) }
    
    /// A wrapper object for `_ChatChannelMemberListController` type which makes it possible to use the controller
    /// comfortably in SwiftUI.
    public class ObservableObject: SwiftUI.ObservableObject {
        /// The underlying controller. You can still access it and call methods on it.
        public let controller: _ChatChannelMemberListController
        
        /// The channel members.
        @Published public private(set) var members: LazyCachedMapCollection<_ChatChannelMember<ExtraData.User>> = []
        
        /// The current state of the controller.
        @Published public private(set) var state: DataController.State
        
        /// Creates a new `ObservableObject` wrapper with the provided controller instance.
        init(controller: _ChatChannelMemberListController<ExtraData>) {
            self.controller = controller
            state = controller.state
            
            controller.multicastDelegate.additionalDelegates.append(AnyChatChannelMemberListControllerDelegate(self))
            
            members = controller.members
        }
    }
}

@available(iOS 13, *)
extension _ChatChannelMemberListController.ObservableObject: _ChatChannelMemberListControllerDelegate {
    public func memberListController(
        _ controller: _ChatChannelMemberListController<ExtraData>,
        didChangeMembers changes: [ListChange<_ChatChannelMember<ExtraData.User>>]
    ) {
        members = controller.members
    }
    
    public func controller(_ controller: DataController, didChangeState state: DataController.State) {
        self.state = state
    }
}
