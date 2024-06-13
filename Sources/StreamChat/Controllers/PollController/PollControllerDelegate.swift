//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public protocol PollControllerDelegate: DataControllerStateDelegate {
    /// Called when there is an update to a poll.
    ///
    /// - Parameters:
    ///   - pollController: The instance of `PollController` that is providing the update.
    ///   - poll: An `EntityChange<Poll>` object representing the changes to the poll.
    ///   This includes information about what kind of change occurred (e.g., insert, update, delete) and the updated poll entity.
    func pollController(
        _ pollController: PollController,
        didUpdatePoll poll: EntityChange<Poll>
    )
    
    /// Called when there is an update to the current user's votes.
    ///
    /// - Parameters:
    ///   - pollController: The instance of `PollController` that is providing the update.
    ///   - votes: An array of `ListChange<PollVote>` objects representing the changes to the user's votes.
    func pollController(
        _ pollController: PollController,
        didUpdateCurrentUserVotes votes: [ListChange<PollVote>]
    )
}
