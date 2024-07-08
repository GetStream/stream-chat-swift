//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI

extension ChatThreadListController {
    /// A wrapper object that exposes the controller variables in the form of `ObservableObject` to be used in SwiftUI.
    internal var observableObject: ObservableObject { .init(controller: self) }

    /// A wrapper object which makes it possible to use the controller comfortably in SwiftUI.
    internal class ObservableObject: SwiftUI.ObservableObject {
        /// The underlying controller. You can still access it and call methods on it.
        internal let controller: ChatThreadListController

        /// The threads.
        @Published internal private(set) var threads: LazyCachedMapCollection<ChatThread> = []

        /// The current state of the controller.
        @Published internal private(set) var state: DataController.State

        /// Creates a new `ObservableObject` wrapper with the provided controller instance.
        init(controller: ChatThreadListController) {
            self.controller = controller
            state = controller.state

            controller.multicastDelegate.add(additionalDelegate: self)

            threads = controller.threads
        }
    }
}

extension ChatThreadListController.ObservableObject: ChatThreadListControllerDelegate {
    internal func controller(_ controller: ChatThreadListController, didChangeThreads changes: [ListChange<ChatThread>]) {
        threads = controller.threads
    }

    internal func controller(_ controller: DataController, didChangeState state: DataController.State) {
        self.state = state
    }
}
