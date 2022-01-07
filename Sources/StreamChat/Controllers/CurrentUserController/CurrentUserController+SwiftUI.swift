//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI

@available(iOS 13, *)
extension CurrentChatUserController {
    /// A wrapper object that exposes the controller variables in the form of `ObservableObject` to be used in SwiftUI.
    public var observableObject: ObservableObject { .init(controller: self) }
    
    /// A wrapper object for `CurrentUserController` type which makes it possible to use the controller comfortably in SwiftUI.
    public class ObservableObject: SwiftUI.ObservableObject {
        /// The underlying controller. You can still access it and call methods on it.
        public let controller: CurrentChatUserController
        
        /// The currently logged-in user.
        @Published public private(set) var currentUser: CurrentChatUser?
        
        /// The unread messages and channels count for the current user.
        @Published public private(set) var unreadCount: UnreadCount = .noUnread
        
        /// Creates a new `ObservableObject` wrapper with the provided controller instance.
        init(controller: CurrentChatUserController) {
            self.controller = controller
            
            controller.multicastDelegate.add(additionalDelegate: self)
            
            currentUser = controller.currentUser
            unreadCount = controller.unreadCount
        }
    }
}

@available(iOS 13, *)
extension CurrentChatUserController.ObservableObject: CurrentChatUserControllerDelegate {
    public func currentUserController(
        _ controller: CurrentChatUserController,
        didChangeCurrentUserUnreadCount unreadCount: UnreadCount
    ) {
        self.unreadCount = controller.unreadCount
    }
    
    public func currentUserController(
        _ controller: CurrentChatUserController,
        didChangeCurrentUser currentUser: EntityChange<CurrentChatUser>
    ) {
        self.currentUser = controller.currentUser
    }
}
