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

struct QueryPollsPayloadResponse: Decodable {
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
    let optionId: String
    let pollId: String
    let updatedAt: Date
    var answerText: String?
    var isAnswer: Bool?
    var userId: String?
    var user: UserPayload?

    init(
        createdAt: Date,
        id: String,
        optionId: String,
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
