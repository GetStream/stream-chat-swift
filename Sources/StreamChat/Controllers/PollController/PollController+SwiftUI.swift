//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI

extension PollController {
    /// A wrapper object that exposes the controller variables in the form of `ObservableObject` to be used in SwiftUI.
    public var observableObject: ObservableObject { .init(controller: self) }

    /// A wrapper object for `PollController` type which makes it possible to use the controller
    /// comfortably in SwiftUI.
    public class ObservableObject: SwiftUI.ObservableObject {
        /// The underlying controller. You can still access it and call methods on it.
        public let controller: PollController
        
        @Published public private(set) var poll: Poll?

        /// The current user's votes.
        @Published public private(set) var ownVotes: LazyCachedMapCollection<PollVote> = []

        /// The current state of the controller.
        @Published public private(set) var state: DataController.State

        /// Creates a new `ObservableObject` wrapper with the provided controller instance.
        init(controller: PollController) {
            self.controller = controller
            state = controller.state

            controller.multicastDelegate.add(additionalDelegate: self)

            poll = controller.poll
            ownVotes = controller.ownVotes
        }
    }
}

extension PollController.ObservableObject: PollControllerDelegate {
    public func pollController(_ pollController: PollController, didUpdatePoll poll: EntityChange<Poll>) {
        self.poll = controller.poll
    }
    
    public func pollController(_ pollController: PollController, didUpdateCurrentUserVotes votes: [ListChange<PollVote>]) {
        ownVotes = controller.ownVotes
    }
    
    public func controller(_ controller: DataController, didChangeState state: DataController.State) {
        self.state = state
    }
}
