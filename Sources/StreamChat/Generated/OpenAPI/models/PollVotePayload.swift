//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class PollVotePayload: Sendable, Decodable {
    let answerText: String?
    let createdAt: Date
    let id: String
    let isAnswer: Bool?
    let optionId: String
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
        optionId: String,
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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.answerText = try container.decodeIfPresent(String.self, forKey: .answerText)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.id = try container.decode(String.self, forKey: .id)
        self.isAnswer = try container.decodeIfPresent(Bool.self, forKey: .isAnswer)
        self.optionId = try container.decode(String.self, forKey: .optionId)
        self.pollId = try container.decode(String.self, forKey: .pollId)
        self.updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        self.user = try container.decodeIfPresent(UserPayload.self, forKey: .user)
        self.userId = try container.decodeIfPresent(String.self, forKey: .userId)
    }
}
