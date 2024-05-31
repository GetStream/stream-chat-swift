//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

struct PollPayloadResponse: Decodable {
    let duration: String
    let poll: PollPayload

    init(duration: String, poll: PollPayload) {
        self.duration = duration
        self.poll = poll
    }
    
    enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case poll
    }
}

struct PollsListPayloadResponse: Decodable {
    let duration: String
    let polls: [PollPayload]
    var next: String?
    var prev: String?

    init(duration: String, polls: [PollPayload], next: String? = nil, prev: String? = nil) {
        self.duration = duration
        self.polls = polls
        self.next = next
        self.prev = prev
    }
    
    enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case polls
        case next
        case prev
    }
}

struct PollOptionResponse: Decodable {
    let duration: String
    let pollOption: PollOptionPayload

    init(duration: String, pollOption: PollOptionPayload) {
        self.duration = duration
        self.pollOption = pollOption
    }
    
    enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case pollOption = "poll_option"
    }
}

struct PollOptionPayload: Decodable {
    let id: String
    let text: String
    let custom: [String: RawJSON]?

    init(id: String, text: String, custom: [String: RawJSON]?) {
        self.id = id
        self.text = text
        self.custom = custom
    }
    
    enum CodingKeys: String, CodingKey, CaseIterable {
        case id
        case text
        case custom
    }
}

struct PollVotePayloadResponse: Decodable {
    var duration: String
    var vote: PollVotePayload?

    init(duration: String, vote: PollVotePayload? = nil) {
        self.duration = duration
        self.vote = vote
    }
    
    enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case vote
    }
}

struct PollVoteListResponse: Decodable {
    let duration: String
    var votes: [PollVotePayload?]
    var next: String?
    var prev: String?

    init(
        duration: String,
        votes: [PollVotePayload?],
        next: String? = nil,
        prev: String? = nil
    ) {
        self.duration = duration
        self.votes = votes
        self.next = next
        self.prev = prev
    }
    
    enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case votes
        case next
        case prev
    }
}

struct PollVotePayload: Decodable {
    let createdAt: Date
    let id: String
    let optionId: String?
    let pollId: String
    let updatedAt: Date
    var answerText: String?
    var isAnswer: Bool?
    var userId: String?
    var user: UserPayload?

    init(
        createdAt: Date,
        id: String,
        optionId: String?,
        pollId: String,
        updatedAt: Date,
        answerText: String? = nil,
        isAnswer: Bool? = nil,
        userId: String? = nil,
        user: UserPayload? = nil
    ) {
        self.createdAt = createdAt
        self.id = id
        self.optionId = optionId
        self.pollId = pollId
        self.updatedAt = updatedAt
        self.answerText = answerText
        self.isAnswer = isAnswer
        self.userId = userId
        self.user = user
    }
    
    enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        case id
        case optionId = "option_id"
        case pollId = "poll_id"
        case updatedAt = "updated_at"
        case answerText = "answer_text"
        case isAnswer = "is_answer"
        case userId = "user_id"
        case user
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
    var latestAnswers: [PollVotePayload?]?
    var options: [PollOptionPayload?]
    var ownVotes: [PollVotePayload?]
    var custom: [String: RawJSON]?
    var latestVotesByOption: [String: [PollVotePayload]]?
    var voteCountsByOption: [String: Int]?
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
        latestAnswers: [PollVotePayload?]?,
        options: [PollOptionPayload?],
        ownVotes: [PollVotePayload?],
        custom: [String: RawJSON],
        latestVotesByOption: [String: [PollVotePayload]]?,
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
