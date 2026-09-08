//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class PollResponseDataVotingVisibility: RawRepresentable, Codable, Hashable, Sendable {
    let rawValue: String

    init(rawValue: String) {
        self.rawValue = rawValue
    }

    static let `public` = PollResponseDataVotingVisibility(rawValue: "public")
    static let anonymous = PollResponseDataVotingVisibility(rawValue: "anonymous")
}

final class PollPayload: Sendable, Decodable {
    let allowAnswers: Bool
    let allowUserSuggestedOptions: Bool
    let answersCount: Int
    let createdAt: Date
    /// User response object
    let createdBy: UserPayload?
    let createdById: String
    let custom: [String: RawJSON]?
    let description: String
    let enforceUniqueVote: Bool
    let id: String
    let isClosed: Bool?
    let latestAnswers: [PollVotePayload?]?
    let latestVotesByOption: [String: [PollVotePayload]]?
    let maxVotesAllowed: Int?
    let name: String
    let options: [PollOptionPayload?]
    let ownVotes: [PollVotePayload?]?
    let updatedAt: Date
    let voteCount: Int
    let voteCountsByOption: [String: Int]?
    /// Voting visibility of the poll
    let votingVisibility: PollResponseDataVotingVisibility?

    init(
        allowAnswers: Bool,
        allowUserSuggestedOptions: Bool,
        answersCount: Int,
        createdAt: Date,
        createdBy: UserPayload? = nil,
        createdById: String,
        custom: [String: RawJSON]? = nil,
        description: String,
        enforceUniqueVote: Bool,
        id: String,
        isClosed: Bool? = nil,
        latestAnswers: [PollVotePayload?]? = nil,
        latestVotesByOption: [String: [PollVotePayload]]? = nil,
        maxVotesAllowed: Int? = nil,
        name: String,
        options: [PollOptionPayload?],
        ownVotes: [PollVotePayload?]? = nil,
        updatedAt: Date,
        voteCount: Int,
        voteCountsByOption: [String: Int]? = nil,
        votingVisibility: PollResponseDataVotingVisibility? = nil
    ) {
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
}
