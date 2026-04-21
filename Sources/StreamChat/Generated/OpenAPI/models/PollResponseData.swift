//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class PollResponseData: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var allowAnswers: Bool
    var allowUserSuggestedOptions: Bool
    var answersCount: Int
    var createdAt: Date
    var createdBy: UserResponse?
    var createdById: String
    var custom: [String: RawJSON]
    var description: String
    var enforceUniqueVote: Bool
    var id: String
    var isClosed: Bool?
    var latestAnswers: [PollVoteResponseData]
    var latestVotesByOption: [String: [PollVoteResponseData]]
    var maxVotesAllowed: Int?
    var name: String
    var options: [PollOptionResponseData]
    var ownVotes: [PollVoteResponseData]
    var updatedAt: Date
    var voteCount: Int
    var voteCountsByOption: [String: Int]
    var votingVisibility: String

    init(allowAnswers: Bool, allowUserSuggestedOptions: Bool, answersCount: Int, createdAt: Date, createdBy: UserResponse? = nil, createdById: String, custom: [String: RawJSON], description: String, enforceUniqueVote: Bool, id: String, isClosed: Bool? = nil, latestAnswers: [PollVoteResponseData], latestVotesByOption: [String: [PollVoteResponseData]], maxVotesAllowed: Int? = nil, name: String, options: [PollOptionResponseData], ownVotes: [PollVoteResponseData], updatedAt: Date, voteCount: Int, voteCountsByOption: [String: Int], votingVisibility: String) {
        self.allowAnswers = allowAnswers
        self.allowUserSuggestedOptions = allowUserSuggestedOptions
        self.answersCount = answersCount
        self.createdAt = createdAt
        self.createdBy = createdBy
        self.createdById = createdById
        self.custom = custom
        self.description = description
        self.enforceUniqueVote = enforceUniqueVote
        self.id = id
        self.isClosed = isClosed
        self.latestAnswers = latestAnswers
        self.latestVotesByOption = latestVotesByOption
        self.maxVotesAllowed = maxVotesAllowed
        self.name = name
        self.options = options
        self.ownVotes = ownVotes
        self.updatedAt = updatedAt
        self.voteCount = voteCount
        self.voteCountsByOption = voteCountsByOption
        self.votingVisibility = votingVisibility
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case allowAnswers = "allow_answers"
        case allowUserSuggestedOptions = "allow_user_suggested_options"
        case answersCount = "answers_count"
        case createdAt = "created_at"
        case createdBy = "created_by"
        case createdById = "created_by_id"
        case custom
        case description
        case enforceUniqueVote = "enforce_unique_vote"
        case id
        case isClosed = "is_closed"
        case latestAnswers = "latest_answers"
        case latestVotesByOption = "latest_votes_by_option"
        case maxVotesAllowed = "max_votes_allowed"
        case name
        case options
        case ownVotes = "own_votes"
        case updatedAt = "updated_at"
        case voteCount = "vote_count"
        case voteCountsByOption = "vote_counts_by_option"
        case votingVisibility = "voting_visibility"
    }

    static func == (lhs: PollResponseData, rhs: PollResponseData) -> Bool {
        lhs.allowAnswers == rhs.allowAnswers &&
            lhs.allowUserSuggestedOptions == rhs.allowUserSuggestedOptions &&
            lhs.answersCount == rhs.answersCount &&
            lhs.createdAt == rhs.createdAt &&
            lhs.createdBy == rhs.createdBy &&
            lhs.createdById == rhs.createdById &&
            lhs.custom == rhs.custom &&
            lhs.description == rhs.description &&
            lhs.enforceUniqueVote == rhs.enforceUniqueVote &&
            lhs.id == rhs.id &&
            lhs.isClosed == rhs.isClosed &&
            lhs.latestAnswers == rhs.latestAnswers &&
            lhs.latestVotesByOption == rhs.latestVotesByOption &&
            lhs.maxVotesAllowed == rhs.maxVotesAllowed &&
            lhs.name == rhs.name &&
            lhs.options == rhs.options &&
            lhs.ownVotes == rhs.ownVotes &&
            lhs.updatedAt == rhs.updatedAt &&
            lhs.voteCount == rhs.voteCount &&
            lhs.voteCountsByOption == rhs.voteCountsByOption &&
            lhs.votingVisibility == rhs.votingVisibility
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(allowAnswers)
        hasher.combine(allowUserSuggestedOptions)
        hasher.combine(answersCount)
        hasher.combine(createdAt)
        hasher.combine(createdBy)
        hasher.combine(createdById)
        hasher.combine(custom)
        hasher.combine(description)
        hasher.combine(enforceUniqueVote)
        hasher.combine(id)
        hasher.combine(isClosed)
        hasher.combine(latestAnswers)
        hasher.combine(latestVotesByOption)
        hasher.combine(maxVotesAllowed)
        hasher.combine(name)
        hasher.combine(options)
        hasher.combine(ownVotes)
        hasher.combine(updatedAt)
        hasher.combine(voteCount)
        hasher.combine(voteCountsByOption)
        hasher.combine(votingVisibility)
    }
}
