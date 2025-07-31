//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

final class PollVoteListController_Mock: PollVoteListController, @unchecked Sendable {
    @Atomic var synchronize_called = false
    @Atomic var synchronize_completion_result: Result<Void, Error>?
    @Atomic var loadMoreVotes_limit: Int?
    @Atomic var loadMoreVotes_completion_result: Result<Void, Error>?

    var votes_simulated: LazyCachedMapCollection<PollVote> = .init([])
    override var votes: LazyCachedMapCollection<PollVote> {
        votes_simulated
    }

    var state_simulated: DataController.State?
    override var state: DataController.State {
        get { state_simulated ?? super.state }
        set { super.state = newValue }
    }

    override func synchronize(_ completion: (@MainActor @Sendable(Error?) -> Void)? = nil) {
        synchronize_called = true
        synchronize_completion_result?.invoke(with: completion)
    }
    
    override func loadMoreVotes(limit: Int? = nil, completion: (@MainActor @Sendable(Error?) -> Void)? = nil) {
        loadMoreVotes_limit = limit
        loadMoreVotes_completion_result?.invoke(with: completion)
    }
}
