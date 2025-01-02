//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension Poll {
    static func mock(
        allowAnswers: Bool = true,
        allowUserSuggestedOptions: Bool = false,
        answersCount: Int = 0,
        createdAt: Date = .unique,
        pollDescription: String? = nil,
        enforceUniqueVote: Bool = false,
        id: String = .unique,
        name: String = .unique,
        updatedAt: Date? = nil,
        voteCount: Int = 0,
        extraData: [String : RawJSON] = [:],
        voteCountsByOption: [String : Int]? = nil,
        isClosed: Bool = false,
        maxVotesAllowed: Int? = nil,
        votingVisibility: VotingVisibility? = nil,
        createdBy: ChatUser? = nil,
        latestAnswers: [PollVote] = [],
        options: [PollOption] = [],
        latestVotesByOption: [PollOption] = [],
        latestVotes: [PollVote] = [],
        ownVotes: [PollVote] = []
    ) -> Poll {
        .init(
            allowAnswers: allowAnswers,
            allowUserSuggestedOptions: allowUserSuggestedOptions,
            answersCount: answersCount,
            createdAt: createdAt,
            pollDescription: pollDescription,
            enforceUniqueVote: enforceUniqueVote,
            id: id,
            name: name,
            updatedAt: updatedAt,
            voteCount: voteCount,
            extraData: extraData,
            voteCountsByOption: voteCountsByOption,
            isClosed: isClosed,
            maxVotesAllowed: maxVotesAllowed,
            votingVisibility: votingVisibility,
            createdBy: createdBy,
            latestAnswers: latestAnswers,
            options: options,
            latestVotesByOption: latestVotesByOption, 
            latestVotes: latestVotes,
            ownVotes: ownVotes
        )
    }
}
extension PollVote {
    static func mock(
        id: String = .unique,
        createdAt: Date = .unique,
        updatedAt: Date = .unique,
        pollId: String = .unique,
        optionId: String? = nil,
        isAnswer: Bool = false,
        answerText: String? = nil,
        user: ChatUser? = nil
    ) -> PollVote {
        .init(
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            pollId: pollId,
            optionId: optionId,
            isAnswer: isAnswer,
            answerText: answerText,
            user: user
        )
    }
}
