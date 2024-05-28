//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

final class PollController_Mock: PollController {
    @Atomic var synchronize_called = false
    @Atomic var castPollVote_called = false
    @Atomic var removePollVote_called = false
    @Atomic var closePoll_called = false
    @Atomic var suggestPollOption_called = false

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
    
    override func castPollVote(
        answerText: String?,
        optionId: String?,
        completion: ((Error?) -> Void)? = nil
    ) {
        castPollVote_called = true
    }
    
    override func removePollVote(
        voteId: String,
        completion: ((Error?) -> Void)? = nil
    ) {
        removePollVote_called = true
    }
    
    override func closePoll(completion: ((Error?) -> Void)? = nil) {
        closePoll_called = true
    }
    
    override func suggestPollOption(
        text: String,
        position: Int? = nil,
        extraData: [String : RawJSON]? = nil,
        completion: ((Error?) -> Void)? = nil
    ) {
        suggestPollOption_called = true
    }
}
