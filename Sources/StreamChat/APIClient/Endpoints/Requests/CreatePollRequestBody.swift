//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

struct CreatePollRequestBody: Encodable {
    let name: String
    var allowAnswers: Bool?
    var allowUserSuggestedOptions: Bool?
    var description: String?
    var enforceUniqueVote: Bool?
    var id: String?
    var isClosed: Bool?
    var maxVotesAllowed: Int?
    var votingVisibility: String?
    var options: [PollOptionRequestBody?]?
    var custom: [String: RawJSON]?

    init(
        name: String,
        allowAnswers: Bool? = nil,
        allowUserSuggestedOptions: Bool? = nil,
        description: String? = nil,
        enforceUniqueVote: Bool? = nil,
        id: String? = nil,
        isClosed: Bool? = nil,
        maxVotesAllowed: Int? = nil,
        votingVisibility: String? = nil,
        options: [PollOptionRequestBody?]? = nil,
        custom: [String: RawJSON]? = nil
    ) {
        self.name = name
        self.allowAnswers = allowAnswers
        self.allowUserSuggestedOptions = allowUserSuggestedOptions
        self.description = description
        self.enforceUniqueVote = enforceUniqueVote
        self.id = id
        self.isClosed = isClosed
        self.maxVotesAllowed = maxVotesAllowed
        self.votingVisibility = votingVisibility
        self.options = options
        self.custom = custom
    }
    
    enum CodingKeys: String, CodingKey, CaseIterable {
        case name
        case allowAnswers = "allow_answers"
        case allowUserSuggestedOptions = "allow_user_suggested_options"
        case description
        case enforceUniqueVote = "enforce_unique_vote"
        case id
        case isClosed = "is_closed"
        case maxVotesAllowed = "max_votes_allowed"
        case votingVisibility = "voting_visibility"
        case options
        case custom
    }
}

struct PollOptionRequestBody: Encodable {
    var text: String?
    var custom: [String: RawJSON]?

    init(
        text: String? = nil,
        custom: [String: RawJSON]? = nil
    ) {
        self.text = text
        self.custom = custom
    }
    
    enum CodingKeys: String, CodingKey, CaseIterable {
        case text
        case custom
    }
}
