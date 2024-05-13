//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

final class PollsRepository_Mock: PollsRepository, Spy {
    @Atomic var getQueryPollVotes_completion: ((Result<[PollVote], Error>) -> Void)?
    
    var recordedFunctions: [String] = []
    
    override func queryPollVotes(
        query: PollVoteListQuery,
        completion: ((Result<[PollVote], Error>) -> Void)? = nil
    ) {
        getQueryPollVotes_completion = completion
    }
}
