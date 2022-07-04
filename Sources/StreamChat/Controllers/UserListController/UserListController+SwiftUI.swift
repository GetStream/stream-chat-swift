//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI

@available(iOS 13, *)
extension ChatUserListController {
    /// A wrapper object that exposes the controller variables in the form of `ObservableObject` to be used in SwiftUI.
    public var observableObject: ObservableObject { .init(controller: self) }
    
    /// A wrapper object for `UserListController` type which makes it possible to use the controller comfortably in SwiftUI.
    public class ObservableObject: SwiftUI.ObservableObject {
        /// The underlying controller. You can still access it and call methods on it.
        public let controller: ChatUserListController
        
        /// The users matching the query.
        @Published public private(set) var users: LazyCachedMapCollection<ChatUser> = []
        
        /// The current state of the Controller.
        @Published public private(set) var state: DataController.State
        
        /// Creates a new `ObservableObject` wrapper with the provided controller instance.
        init(controller: ChatUserListController) {
            self.controller = controller
            state = controller.state
            
            controller.multicastDelegate.add(additionalDelegate: self)
            users = controller.users
        }
    }
}

@available(iOS 13, *)
extension ChatUserListController.ObservableObject: ChatUserListControllerDelegate {
    public func controller(
        _ controller: ChatUserListController,
        didChangeUsers changes: [ListChange<ChatUser>]
    ) {
        // We don't care about detailed changes. We just need to update the `users` property and keep SwiftUI
        // deal with the rest.
        users = controller.users
    }
    
    public func controller(_ controller: DataController, didChangeState state: DataController.State) {
        self.state = state
    }
}
