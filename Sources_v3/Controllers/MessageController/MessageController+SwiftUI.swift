//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI

@available(iOS 13, *)
extension MessageControllerGeneric {
    /// A wrapper object that exposes the controller variables in the form of `ObservableObject` to be used in SwiftUI.
    public var observableObject: ObservableObject { .init(controller: self) }
    
    /// A wrapper object for `CurrentUserController` type which makes it possible to use the controller comfortably in SwiftUI.
    public class ObservableObject: SwiftUI.ObservableObject {
        /// The underlying controller. You can still access it and call methods on it.
        public let controller: MessageControllerGeneric
        
        /// The message that current controller observes.
        @Published public private(set) var message: MessageModel<ExtraData>?
        
        /// The current state of the Controller.
        @Published public private(set) var state: Controller.State
        
        /// Creates a new `ObservableObject` wrapper with the provided controller instance.
        init(controller: MessageControllerGeneric<ExtraData>) {
            self.controller = controller
            state = controller.state
            
            controller.multicastDelegate.additionalDelegates.append(AnyMessageControllerDelegate(self))
            
            if controller.state == .inactive {
                // Start updating and load the current data
                controller.startUpdating()
            }
            
            message = controller.message
        }
    }
}

@available(iOS 13, *)
extension MessageControllerGeneric.ObservableObject: MessageControllerDelegateGeneric {
    public func messageController(
        _ controller: MessageControllerGeneric<ExtraData>,
        didChangeMessage change: EntityChange<MessageModel<ExtraData>>
    ) {
        message = controller.message
    }
    
    public func controller(_ controller: Controller, didChangeState state: Controller.State) {
        self.state = state
    }
}
