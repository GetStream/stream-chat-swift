//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI

@available(iOS 13, *)
extension ChatMessageController {
    /// A wrapper object that exposes the controller variables in the form of `ObservableObject` to be used in SwiftUI.
    @available(*, deprecated, message: "This is now deprecated, please refer to the SwiftUI SDK at https://github.com/GetStream/stream-chat-swiftui")
    public var observableObject: ObservableObject { .init(controller: self) }
    
    /// A wrapper object for `CurrentUserController` type which makes it possible to use the controller comfortably in SwiftUI.
    public class ObservableObject: SwiftUI.ObservableObject {
        /// The underlying controller. You can still access it and call methods on it.
        public let controller: ChatMessageController
        
        /// The message that current controller observes.
        @Published public private(set) var message: ChatMessage?
        
        /// The replies the message controller observes.
        @Published public private(set) var replies: LazyCachedMapCollection<ChatMessage> = []

        /// The reactions the message controller observes.
        @Published public private(set) var reactions: [ChatMessageReaction] = []
        
        /// The current state of the Controller.
        @Published public private(set) var state: DataController.State
        
        /// Creates a new `ObservableObject` wrapper with the provided controller instance.
        @available(*, deprecated, message: "This is now deprecated, please refer to the SwiftUI SDK at https://github.com/GetStream/stream-chat-swiftui")
        init(controller: ChatMessageController) {
            self.controller = controller
            state = controller.state
            
            controller.multicastDelegate.add(additionalDelegate: self)
            
            message = controller.message
            replies = controller.replies
            reactions = controller.reactions
        }
    }
}

@available(iOS 13, *)
extension ChatMessageController.ObservableObject: ChatMessageControllerDelegate {
    public func messageController(
        _ controller: ChatMessageController,
        didChangeMessage change: EntityChange<ChatMessage>
    ) {
        message = controller.message
    }
    
    public func messageController(
        _ controller: ChatMessageController,
        didChangeReplies changes: [ListChange<ChatMessage>]
    ) {
        replies = controller.replies
    }
    
    public func controller(_ controller: DataController, didChangeState state: DataController.State) {
        self.state = state
    }

    public func messageController(
        _ controller: ChatMessageController,
        didChangeReactions reactions: [ChatMessageReaction]
    ) {
        self.reactions = controller.reactions
    }
}
