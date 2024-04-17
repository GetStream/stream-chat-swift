//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

struct PollClosedEventDTO: EventDTO {
    var poll: PollPayload?
    var payload: EventPayload

    init(payload: EventPayload, poll: PollPayload? = nil) {
        self.payload = payload
        self.poll = poll
    }
}

struct PollCreatedEventDTO: EventDTO {
    var poll: PollPayload?
    var payload: EventPayload

    init(payload: EventPayload, poll: PollPayload? = nil) {
        self.payload = payload
        self.poll = poll
    }
}

struct PollDeletedEventDTO: EventDTO {
    var poll: PollPayload?
    var payload: EventPayload

    init(payload: EventPayload, poll: PollPayload? = nil) {
        self.payload = payload
        self.poll = poll
    }
}

struct PollUpdatedEventDTO: EventDTO {
    var poll: PollPayload?
    var payload: EventPayload

    init(payload: EventPayload, poll: PollPayload? = nil) {
        self.payload = payload
        self.poll = poll
    }
}

struct PollVoteCastedEventDTO: EventDTO {
    var vote: PollVotePayload?
    var payload: EventPayload

    init(payload: EventPayload, vote: PollVotePayload? = nil) {
        self.payload = payload
        self.vote = vote
    }
}

struct PollVoteChangedEventDTO: EventDTO {
    var vote: PollVotePayload?
    var payload: EventPayload

    init(payload: EventPayload, vote: PollVotePayload? = nil) {
        self.payload = payload
        self.vote = vote
    }
}

struct PollVoteRemovedEventDTO: EventDTO {
    var vote: PollVotePayload?
    var payload: EventPayload

    init(payload: EventPayload, vote: PollVotePayload? = nil) {
        self.payload = payload
        self.vote = vote
    }
}

struct PollPayload: Decodable {
    var allowAnswers: Bool
    var allowUserSuggestedOptions: Bool
    var answersCount: Int
    var createdAt: Date
    var createdById: String
    var description: String
    var enforceUniqueVote: Bool
    var id: String
    var name: String
    var updatedAt: Date
    var voteCount: Int
    var latestAnswers: [PollVotePayload?]
    var options: [PollOptionPayload?]
    var ownVotes: [PollVotePayload?]
    var custom: [String: RawJSON]?
    var latestVotesByOption: [String: [PollVotePayload?]]
    var voteCountsByOption: [String: Int]
    var isClosed: Bool?
    var maxVotesAllowed: Int?
    var votingVisibility: String?
    var createdBy: UserPayload?

    init(
        allowAnswers: Bool,
        allowUserSuggestedOptions: Bool,
        answersCount: Int,
        createdAt: Date,
        createdById: String,
        description: String,
        enforceUniqueVote: Bool,
        id: String,
        name: String,
        updatedAt: Date,
        voteCount: Int,
        latestAnswers: [PollVotePayload?],
        options: [PollOptionPayload?],
        ownVotes: [PollVotePayload?],
        custom: [String: RawJSON],
        latestVotesByOption: [String: [PollVotePayload?]],
        voteCountsByOption: [String: Int],
        isClosed: Bool? = nil,
        maxVotesAllowed: Int? = nil,
        votingVisibility: String? = nil,
        createdBy: UserPayload? = nil
    ) {
        self.allowAnswers = allowAnswers
        self.allowUserSuggestedOptions = allowUserSuggestedOptions
        self.answersCount = answersCount
        self.createdAt = createdAt
        self.createdById = createdById
        self.description = description
        self.enforceUniqueVote = enforceUniqueVote
        self.id = id
        self.name = name
        self.updatedAt = updatedAt
        self.voteCount = voteCount
        self.latestAnswers = latestAnswers
        self.options = options
        self.ownVotes = ownVotes
        self.custom = custom
        self.latestVotesByOption = latestVotesByOption
        self.voteCountsByOption = voteCountsByOption
        self.isClosed = isClosed
        self.maxVotesAllowed = maxVotesAllowed
        self.votingVisibility = votingVisibility
        self.createdBy = createdBy
    }
    
    enum CodingKeys: String, CodingKey, CaseIterable {
        case allowAnswers = "allow_answers"
        case allowUserSuggestedOptions = "allow_user_suggested_options"
        case answersCount = "answers_count"
        case createdAt = "created_at"
        case createdById = "created_by_id"
        case description
        case enforceUniqueVote = "enforce_unique_vote"
        case id
        case name
        case updatedAt = "updated_at"
        case voteCount = "vote_count"
        case latestAnswers = "latest_answers"
        case options
        case ownVotes = "own_votes"
        case custom
        case latestVotesByOption = "latest_votes_by_option"
        case voteCountsByOption = "vote_counts_by_option"
        case isClosed = "is_closed"
        case maxVotesAllowed = "max_votes_allowed"
        case votingVisibility = "voting_visibility"
        case createdBy = "created_by"
    }
}
