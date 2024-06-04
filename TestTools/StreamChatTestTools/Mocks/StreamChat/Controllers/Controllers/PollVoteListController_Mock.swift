//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

final class PollVoteListController_Mock: PollVoteListController {
    @Atomic var synchronize_called = false

    var votes_simulated: LazyCachedMapCollection<PollVote> = .init([])
    override var votes: LazyCachedMapCollection<PollVote> {
        votes_simulated
    }

    var state_simulated: DataController.State?
    override var state: DataController.State {
        get { state_simulated ?? super.state }
        set { super.state = newValue }
    }

    override func synchronize(_ completion: ((Error?) -> Void)? = nil) {
        synchronize_called = true
    }
}
