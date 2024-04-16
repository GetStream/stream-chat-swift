//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

struct CastPollVoteRequestBody: Encodable {
    let pollId: String
    var vote: VoteDataRequestBody?

    init(pollId: String, vote: VoteDataRequestBody? = nil) {
        self.pollId = pollId
        self.vote = vote
    }
    
    enum CodingKeys: String, CodingKey, CaseIterable {
        case pollId = "poll_id"
        case vote
    }
}

struct VoteDataRequestBody: Encodable {
    var answerText: String?
    var optionId: String?
    var option: PollOptionRequestBody?

    init(
        answerText: String? = nil,
        optionId: String? = nil,
        option: PollOptionRequestBody? = nil
    ) {
        self.answerText = answerText
        self.optionId = optionId
        self.option = option
    }
    
    enum CodingKeys: String, CodingKey, CaseIterable {
        case answerText = "answer_text"
        case optionId = "option_id"
        case option = "Option"
    }
}

struct PollOptionRequestBody: Encodable {
    let id: String
    var text: String?
    let custom: [String: RawJSON]?

    init(id: String, text: String? = nil, custom: [String: RawJSON]? = nil) {
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
