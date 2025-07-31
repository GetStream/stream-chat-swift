//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

final class PollController_Mock: PollController, @unchecked Sendable {
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

    var synchronize_callCount = 0
    var synchronize_completion: (@MainActor @Sendable(Error?) -> Void)?
    override func synchronize(_ completion: (@MainActor @Sendable(Error?) -> Void)? = nil) {
        synchronize_callCount += 1
        synchronize_completion = completion
    }
    
    override func castPollVote(
        answerText: String?,
        optionId: String?,
        completion: (@MainActor @Sendable(Error?) -> Void)? = nil
    ) {
        castPollVote_called = true
        castPollVote_completion_result?.invoke(with: completion)
    }
    
    override func removePollVote(
        voteId: String,
        completion: (@MainActor @Sendable(Error?) -> Void)? = nil
    ) {
        removePollVote_called = true
        removePollVote_completion_result?.invoke(with: completion)
    }
    
    var closePoll_callCount = 0
    var closePoll_completion: (@MainActor @Sendable(Error?) -> Void)?
    override func closePoll(completion: (@MainActor @Sendable(Error?) -> Void)? = nil) {
        closePoll_callCount += 1
        closePoll_completion = completion
    }
    
    override func suggestPollOption(
        text: String,
        position: Int? = nil,
        extraData: [String: RawJSON]? = nil,
        completion: (@MainActor @Sendable(Error?) -> Void)? = nil
    ) {
        suggestPollOption_called = true
        suggestPollOption_completion_result?.invoke(with: completion)
    }
}
