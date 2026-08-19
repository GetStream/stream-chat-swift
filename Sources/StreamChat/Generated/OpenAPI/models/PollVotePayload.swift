//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class PollVotePayload: Sendable, Codable, JSONEncodable {
    let answerText: String?
    let createdAt: Date
    let id: String
    let isAnswer: Bool?
    let optionId: String?
    let pollId: String
    let updatedAt: Date
    /// User response object
    let user: UserPayload?
    let userId: String?

    init(
        answerText: String? = nil,
        createdAt: Date,
        id: String,
        isAnswer: Bool? = nil,
        optionId: String? = nil,
        pollId: String,
        updatedAt: Date,
        user: UserPayload? = nil,
        userId: String? = nil
    ) {
        self.answerText = answerText
        self.createdAt = createdAt
        self.id = id
        self.isAnswer = isAnswer
        self.optionId = optionId
        self.pollId = pollId
        self.updatedAt = updatedAt
        self.user = user
        self.userId = userId
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case answerText = "answer_text"
        case createdAt = "created_at"
        case id
        case isAnswer = "is_answer"
        case optionId = "option_id"
        case pollId = "poll_id"
        case updatedAt = "updated_at"
        case user
        case userId = "user_id"
    }
}
