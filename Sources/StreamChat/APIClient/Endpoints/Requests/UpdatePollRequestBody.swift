//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

struct UpdatePollRequestBody: Encodable {
    let id: String
    let name: String
    var allowAnswers: Bool?
    var allowUserSuggestedOptions: Bool?
    var description: String?
    var enforceUniqueVote: Bool?
    var isClosed: Bool?
    var maxVotesAllowed: Int?
    var votingVisibility: String?
    var options: [PollVoteOptionRequestBody?]?
    var custom: [String: RawJSON]?

    init(
        id: String,
        name: String,
        allowAnswers: Bool? = nil,
        allowUserSuggestedOptions: Bool? = nil,
        description: String? = nil,
        enforceUniqueVote: Bool? = nil,
        isClosed: Bool? = nil,
        maxVotesAllowed: Int? = nil,
        votingVisibility: String? = nil,
        options: [PollVoteOptionRequestBody?]? = nil,
        custom: [String: RawJSON]? = nil
    ) {
        self.id = id
        self.name = name
        self.allowAnswers = allowAnswers
        self.allowUserSuggestedOptions = allowUserSuggestedOptions
        self.description = description
        self.enforceUniqueVote = enforceUniqueVote
        self.isClosed = isClosed
        self.maxVotesAllowed = maxVotesAllowed
        self.votingVisibility = votingVisibility
        self.options = options
        self.custom = custom
    }
    
    enum CodingKeys: String, CodingKey, CaseIterable {
        case id
        case name
        case allowAnswers = "allow_answers"
        case allowUserSuggestedOptions = "allow_user_suggested_options"
        case description
        case enforceUniqueVote = "enforce_unique_vote"
        case isClosed = "is_closed"
        case maxVotesAllowed = "max_votes_allowed"
        case votingVisibility = "voting_visibility"
        case options
        case custom
    }
}
