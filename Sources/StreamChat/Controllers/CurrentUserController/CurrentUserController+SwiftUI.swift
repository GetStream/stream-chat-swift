//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI

@available(iOS 13, *)
extension _CurrentChatUserController {
    /// A wrapper object that exposes the controller variables in the form of `ObservableObject` to be used in SwiftUI.
    public var observableObject: ObservableObject { .init(controller: self) }
    
    /// A wrapper object for `CurrentUserController` type which makes it possible to use the controller comfortably in SwiftUI.
    public class ObservableObject: SwiftUI.ObservableObject {
        /// The underlying controller. You can still access it and call methods on it.
        public let controller: _CurrentChatUserController
        
        /// The currently logged-in user.
        @Published public private(set) var currentUser: CurrentChatUser?
        
        /// The unread messages and channels count for the current user.
        @Published public private(set) var unreadCount: UnreadCount = .noUnread
        
        /// Creates a new `ObservableObject` wrapper with the provided controller instance.
        init(controller: _CurrentChatUserController<ExtraData>) {
            self.controller = controller
            
            controller.multicastDelegate.additionalDelegates.append(AnyCurrentUserControllerDelegate(self))
            
            currentUser = controller.currentUser
            unreadCount = controller.unreadCount
        }
    }
}

@available(iOS 13, *)
extension _CurrentChatUserController.ObservableObject: _CurrentChatUserControllerDelegate {
    public func currentUserController(
        _ controller: _CurrentChatUserController<ExtraData>,
        didChangeCurrentUserUnreadCount unreadCount: UnreadCount
    ) {
        self.unreadCount = controller.unreadCount
    }
    
    public func currentUserController(
        _ controller: _CurrentChatUserController<ExtraData>,
        didChangeCurrentUser currentUser: EntityChange<CurrentChatUser>
    ) {
        self.currentUser = controller.currentUser
    }
}
