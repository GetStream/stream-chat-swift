//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

extension PollController {
    /// A publisher emitting a new value every time the state of the controller changes.
    public var statePublisher: AnyPublisher<DataController.State, Never> {
        basePublishers.state.keepAlive(self)
    }

    /// A publisher emitting a new value every time the poll changes.
    public var pollChangesPublisher: AnyPublisher<EntityChange<Poll>, Never> {
        basePublishers.pollChanges.keepAlive(self)
    }
    
    public var currentUserVotesChanges: AnyPublisher<[ListChange<PollVote>], Never> {
        basePublishers.currentUserVotesChanges.keepAlive(self)
    }

    /// An internal backing object for all publicly available Combine publishers. We use it to simplify the way we expose
    /// publishers. Instead of creating custom `Publisher` types, we use `CurrentValueSubject` and `PassthroughSubject` internally,
    /// and expose the published values by mapping them to a read-only `AnyPublisher` type.
    class BasePublishers {
        /// The wrapped controller.
        unowned let controller: PollController

        /// A backing subject for `statePublisher`.
        let state: CurrentValueSubject<DataController.State, Never>

        /// A backing subject for `pollChangesPublisher`.
        let pollChanges: PassthroughSubject<EntityChange<Poll>, Never> = .init()
        
        let currentUserVotesChanges: PassthroughSubject<[ListChange<PollVote>], Never> = .init()

        init(controller: PollController) {
            self.controller = controller
            state = .init(controller.state)

            controller.multicastDelegate.add(additionalDelegate: self)
        }
    }
}

extension PollController.BasePublishers: PollControllerDelegate {
    func pollController(_ pollController: PollController, didUpdatePoll poll: EntityChange<Poll>) {
        pollChanges.send(poll)
    }
    
    func pollController(_ pollController: PollController, didUpdateCurrentUserVotes votes: [ListChange<PollVote>]) {
        currentUserVotesChanges.send(votes)
    }
    
    func controller(_ controller: DataController, didChangeState state: DataController.State) {
        self.state.send(state)
    }
}
