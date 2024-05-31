//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

final class PollsRepository_Mock: PollsRepository, Spy {
    @Atomic var getQueryPollVotes_completion: ((Result<VotePaginationResponse, Error>) -> Void)?
    @Atomic var castPollVote_completion: ((Error?) -> Void)?
    @Atomic var removePollVote_completion: ((Error?) -> Void)?
    @Atomic var closePoll_completion: ((Error?) -> Void)?
    @Atomic var suggestPollOption_completion: ((Error?) -> Void)?
    
    var recordedFunctions: [String] = []
    var spyState: SpyState = .init()

    override func queryPollVotes(
        query: PollVoteListQuery,
        completion: ((Result<VotePaginationResponse, Error>) -> Void)? = nil
    ) {
        getQueryPollVotes_completion = completion
    }
    
    override func castPollVote(
        messageId: MessageId,
        pollId: String,
        answerText: String?,
        optionId: String?,
        currentUserId: String?,
        query: PollVoteListQuery?,
        deleteExistingVotes: [PollVote] = [],
        completion: ((Error?) -> Void)? = nil
    ) {
        castPollVote_completion = completion
    }
    
    override func removePollVote(
        messageId: MessageId,
        pollId: String,
        voteId: String,
        completion: ((Error?) -> Void)? = nil
    ) {
        removePollVote_completion = completion
    }
    
    override func closePoll(pollId: String, completion: ((Error?) -> Void)? = nil) {
        closePoll_completion = completion
    }
    
    override func suggestPollOption(
        pollId: String,
        text: String,
        position: Int? = nil,
        custom: [String : RawJSON]? = nil,
        completion: ((Error?) -> Void)? = nil
    ) {
        suggestPollOption_completion = completion
    }
}
