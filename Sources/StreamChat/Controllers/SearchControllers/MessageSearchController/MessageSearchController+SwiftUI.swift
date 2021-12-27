//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI

@available(iOS 13, *)
extension ChatMessageSearchController {
    /// A wrapper object that exposes the controller variables in the form of `ObservableObject` to be used in SwiftUI.
    public var observableObject: ObservableObject { .init(controller: self) }

    /// A wrapper object for `CurrentUserController` type which makes it possible to use the controller comfortably in SwiftUI.
    public class ObservableObject: SwiftUI.ObservableObject {
        /// The underlying controller. You can still access it and call methods on it.
        public let controller: ChatMessageSearchController

        /// The current result of messages.
        @Published public private(set) var messages: LazyCachedMapCollection<ChatMessage> = []
        
        /// The current result of messages.
        @Published public private(set) var messageArray: [ChatMessage] = [] {
            didSet {
                messages = .init(source: messageArray, map: { $0 })
            }
        }
        
        /// The current state of the controller.
        @Published public private(set) var state: DataController.State

        /// Creates a new `ObservableObject` wrapper with the provided controller instance.
        init(controller: ChatMessageSearchController) {
            self.controller = controller
            state = self.controller.state

            controller.multicastDelegate.add(additionalDelegate: self)

            messageArray = controller.messageArray
        }
    }
}

@available(iOS 13, *)
extension ChatMessageSearchController.ObservableObject: ChatMessageSearchControllerDelegate {
    public func controller(_ controller: ChatMessageSearchController, didChangeMessages changes: [ListChange<ChatMessage>]) {
        messageArray = controller.messageArray
    }

    public func controller(_ controller: DataController, didChangeState state: DataController.State) {
        self.state = state
    }
}
