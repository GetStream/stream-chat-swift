//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

final class PollController_Mock: PollController {
    @Atomic var synchronize_called = false

    var poll_simulated: Poll?
    override var poll: Poll? {
        poll_simulated
    }
    
    var ownVotes_simulated: LazyCachedMapCollection<PollVote> = .init([])
    override var ownVotes: LazyCachedMapCollection<PollVote> {
        ownVotes_simulated
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
