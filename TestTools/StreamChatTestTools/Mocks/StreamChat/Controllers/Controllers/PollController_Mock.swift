//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

final class PollController_Mock: PollController {
    @Atomic var synchronize_called = false
    @Atomic var synchronize_completion_result: Result<Void, Error>?
    @Atomic var castPollVote_called = false
    @Atomic var castPollVote_completion_result: Result<Void, Error>?
    @Atomic var removePollVote_called = false
    @Atomic var removePollVote_completion_result: Result<Void, Error>?
    @Atomic var closePoll_called = false
    @Atomic var closePollVote_completion_result: Result<Void, Error>?
    @Atomic var suggestPollOption_called = false
    @Atomic var suggestPollOption_completion_result: Result<Void, Error>?

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
        synchronize_completion_result?.invoke(with: completion)
    }
    
    override func castPollVote(
        answerText: String?,
        optionId: String?,
        completion: ((Error?) -> Void)? = nil
    ) {
        castPollVote_called = true
        castPollVote_completion_result?.invoke(with: completion)
    }
    
    override func removePollVote(
        voteId: String,
        completion: ((Error?) -> Void)? = nil
    ) {
        removePollVote_called = true
        removePollVote_completion_result?.invoke(with: completion)
    }
    
    override func closePoll(completion: ((Error?) -> Void)? = nil) {
        closePoll_called = true
        closePollVote_completion_result?.invoke(with: completion)
    }
    
    override func suggestPollOption(
        text: String,
        position: Int? = nil,
        extraData: [String : RawJSON]? = nil,
        completion: ((Error?) -> Void)? = nil
    ) {
        suggestPollOption_called = true
        suggestPollOption_completion_result?.invoke(with: completion)
    }
}
