//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI

extension ChatReactionListController {
    /// A wrapper object that exposes the controller variables in the form of `ObservableObject` to be used in SwiftUI.
    public var observableObject: ObservableObject { .init(controller: self) }

    /// A wrapper object for `ChatReactionListController` type which makes it possible to use the controller
    /// comfortably in SwiftUI.
    public class ObservableObject: SwiftUI.ObservableObject {
        /// The underlying controller. You can still access it and call methods on it.
        public let controller: ChatReactionListController

        /// The message reactions.
        @Published public private(set) var reactions: LazyCachedMapCollection<ChatMessageReaction> = []

        /// The current state of the controller.
        @Published public private(set) var state: DataController.State

        /// Creates a new `ObservableObject` wrapper with the provided controller instance.
        init(controller: ChatReactionListController) {
            self.controller = controller
            state = controller.state

            controller.multicastDelegate.add(additionalDelegate: self)

            reactions = controller.reactions
        }
    }
}

extension ChatReactionListController.ObservableObject: ChatReactionListControllerDelegate {
    public func controller(
        _ controller: ChatReactionListController,
        didChangeReactions changes: [ListChange<ChatMessageReaction>]
    ) {
        reactions = controller.reactions
    }

    public func controller(_ controller: DataController, didChangeState state: DataController.State) {
        self.state = state
    }
}
