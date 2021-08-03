//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI

@available(iOS 13, *)
extension ChatUserController {
    /// A wrapper object that exposes the controller variables in the form of `ObservableObject` to be used in SwiftUI.
    public var observableObject: ObservableObject { .init(controller: self) }
    
    /// A wrapper object for `ChatUserController` type which makes it possible to use the controller comfortably in SwiftUI.
    public class ObservableObject: SwiftUI.ObservableObject {
        /// The underlying controller. You can still access it and call methods on it.
        public let controller: ChatUserController
        
        /// The user matching the `userId`.
        @Published public private(set) var user: ChatUser?
        
        /// The current state of the controller.
        @Published public private(set) var state: DataController.State
        
        /// Creates a new `ObservableObject` wrapper with the provided controller instance.
        init(controller: ChatUserController) {
            self.controller = controller
            state = controller.state
            
            controller.multicastDelegate.additionalDelegates.append(AnyChatUserControllerDelegate(self))
            
            user = controller.user
        }
    }
}

@available(iOS 13, *)
extension ChatUserController.ObservableObject: ChatUserControllerDelegate {
    public func userController(
        _ controller: ChatUserController,
        didUpdateUser change: EntityChange<ChatUser>
    ) {
        user = change.item
    }
    
    public func controller(_ controller: DataController, didChangeState state: DataController.State) {
        self.state = state
    }
}
