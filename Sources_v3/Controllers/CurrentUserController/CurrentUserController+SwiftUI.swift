//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI

@available(iOS 13, *)
extension CurrentUserControllerGeneric {
    /// A wrapper object that exposes the controller variables in the form of `ObservableObject` to be used in SwiftUI.
    public var observableObject: ObservableObject { .init(controller: self) }
    
    /// A wrapper object for `CurrentUserController` type which makes it possible to use the controller comfortably in SwiftUI.
    public class ObservableObject: SwiftUI.ObservableObject {
        /// The underlying controller. You can still access it and call methods on it.
        public let controller: CurrentUserControllerGeneric
        
        /// The currently logged-in user.
        @Published public private(set) var currentUser: CurrentUserModel<ExtraData.User>?
        
        /// The unread messages and channels count for the current user.
        @Published public private(set) var unreadCount: UnreadCount = .noUnread
        
        /// The current state of the Controller.
        @Published public private(set) var state: Controller.State
        
        /// Creates a new `ObservableObject` wrapper with the provided controller instance.
        init(controller: CurrentUserControllerGeneric<ExtraData>) {
            self.controller = controller
            state = controller.state
            
            controller.multicastDelegate.additionalDelegates.append(AnyCurrentUserControllerDelegate(self))
            
            if controller.state == .inactive {
                // Start updating and load the current data
                controller.startUpdating()
            }
            
            currentUser = controller.currentUser
            unreadCount = controller.unreadCount
        }
    }
}

@available(iOS 13, *)
extension CurrentUserControllerGeneric.ObservableObject: CurrentUserControllerDelegateGeneric {
    public func currentUserController(
        _ controller: CurrentUserControllerGeneric<ExtraData>,
        didChangeCurrentUserUnreadCount unreadCount: UnreadCount
    ) {
        self.unreadCount = controller.unreadCount
    }
    
    public func currentUserController(
        _ controller: CurrentUserControllerGeneric<ExtraData>,
        didChangeCurrentUser currentUser: EntityChange<CurrentUserModel<ExtraData.User>>
    ) {
        self.currentUser = controller.currentUser
    }
    
    public func controller(_ controller: Controller, didChangeState state: Controller.State) {
        self.state = state
    }
}
