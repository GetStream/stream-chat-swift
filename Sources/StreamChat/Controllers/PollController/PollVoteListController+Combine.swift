//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

extension PollVoteListController {
    /// A publisher emitting a new value every time the state of the controller changes.
    public var statePublisher: AnyPublisher<DataController.State, Never> {
        basePublishers.state.keepAlive(self)
    }

    /// A publisher emitting a new value every time the votes change.
    public var voteChangesPublisher: AnyPublisher<[ListChange<PollVote>], Never> {
        basePublishers.voteChanges.keepAlive(self)
    }

    /// An internal backing object for all publicly available Combine publishers. We use it to simplify the way we expose
    /// publishers. Instead of creating custom `Publisher` types, we use `CurrentValueSubject` and `PassthroughSubject` internally,
    /// and expose the published values by mapping them to a read-only `AnyPublisher` type.
    class BasePublishers {
        /// The wrapped controller.
        unowned let controller: PollVoteListController

        /// A backing subject for `statePublisher`.
        let state: CurrentValueSubject<DataController.State, Never>

        /// A backing subject for `voteChangesPublisher`.
        let voteChanges: PassthroughSubject<[ListChange<PollVote>], Never> = .init()

        init(controller: PollVoteListController) {
            self.controller = controller
            state = .init(controller.state)

            controller.multicastDelegate.add(additionalDelegate: self)
        }
    }
}

extension PollVoteListController.BasePublishers: PollVoteListControllerDelegate {
    func controller(_ controller: DataController, didChangeState state: DataController.State) {
        self.state.send(state)
    }

    func controller(
        _ controller: PollVoteListController,
        didChangeVotes changes: [ListChange<PollVote>]
    ) {
        voteChanges.send(changes)
    }
}
