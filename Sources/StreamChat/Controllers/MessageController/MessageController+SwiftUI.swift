//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI

@available(iOS 13, *)
extension _ChatMessageController {
    /// A wrapper object that exposes the controller variables in the form of `ObservableObject` to be used in SwiftUI.
    public var observableObject: ObservableObject { .init(controller: self) }
    
    /// A wrapper object for `CurrentUserController` type which makes it possible to use the controller comfortably in SwiftUI.
    public class ObservableObject: SwiftUI.ObservableObject {
        /// The underlying controller. You can still access it and call methods on it.
        public let controller: _ChatMessageController
        
        /// The message that current controller observes.
        @Published public private(set) var message: _ChatMessage<ExtraData>?
        
        /// The replies to the message controller observes.
        @Published public private(set) var replies: LazyCachedMapCollection<_ChatMessage<ExtraData>> = []
        
        /// The current state of the Controller.
        @Published public private(set) var state: DataController.State
        
        /// Creates a new `ObservableObject` wrapper with the provided controller instance.
        init(controller: _ChatMessageController<ExtraData>) {
            self.controller = controller
            state = controller.state
            
            controller.multicastDelegate.additionalDelegates.append(AnyChatMessageControllerDelegate(self))
            
            message = controller.message
            replies = controller.replies
        }
    }
}

@available(iOS 13, *)
extension _ChatMessageController.ObservableObject: _ChatMessageControllerDelegate {
    public func messageController(
        _ controller: _ChatMessageController<ExtraData>,
        didChangeMessage change: EntityChange<_ChatMessage<ExtraData>>
    ) {
        message = controller.message
    }
    
    public func messageController(
        _ controller: _ChatMessageController<ExtraData>,
        didChangeReplies changes: [ListChange<_ChatMessage<ExtraData>>]
    ) {
        replies = controller.replies
    }
    
    public func controller(_ controller: DataController, didChangeState state: DataController.State) {
        self.state = state
    }
}
