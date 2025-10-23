//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI

extension PollVoteListController {
    /// A wrapper object that exposes the controller variables in the form of `ObservableObject` to be used in SwiftUI.
    public var observableObject: ObservableObject { .init(controller: self) }

    /// A wrapper object for `PollVoteListController` type which makes it possible to use the controller
    /// comfortably in SwiftUI.
    public class ObservableObject: SwiftUI.ObservableObject {
        /// The underlying controller. You can still access it and call methods on it.
        public let controller: PollVoteListController

        /// The poll votes.
        @Published public private(set) var votes: [PollVote] = []

        /// The poll which the votes belong to.
        @Published public private(set) var poll: Poll?

        /// The current state of the controller.
        @Published public private(set) var state: DataController.State

        /// Creates a new `ObservableObject` wrapper with the provided controller instance.
        init(controller: PollVoteListController) {
            self.controller = controller
            state = controller.state

            controller.multicastDelegate.add(additionalDelegate: self)

            votes = controller.votes
            poll = controller.poll
        }
    }
}

extension PollVoteListController.ObservableObject: PollVoteListControllerDelegate {
    public func controller(
        _ controller: PollVoteListController,
        didChangeVotes changes: [ListChange<PollVote>]
    ) {
        votes = controller.votes
    }

    public func controller(_ controller: PollVoteListController, didUpdatePoll poll: Poll) {
        self.poll = poll
    }

    public func controller(_ controller: DataController, didChangeState state: DataController.State) {
        self.state = state
    }
}
