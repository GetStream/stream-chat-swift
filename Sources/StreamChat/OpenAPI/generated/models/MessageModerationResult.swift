//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct MessageModerationResult: Codable, Hashable {
    public var action: String
    public var createdAt: Date
    public var messageId: String
    public var updatedAt: Date
    public var userBadKarma: Bool
    public var userKarma: Double
    public var blockedWord: String? = nil
    public var blocklistName: String? = nil
    public var moderatedBy: String? = nil
    public var aiModerationResponse: ModerationResponse? = nil
    public var moderationThresholds: Thresholds? = nil

    public init(action: String, createdAt: Date, messageId: String, updatedAt: Date, userBadKarma: Bool, userKarma: Double, blockedWord: String? = nil, blocklistName: String? = nil, moderatedBy: String? = nil, aiModerationResponse: ModerationResponse? = nil, moderationThresholds: Thresholds? = nil) {
        self.action = action
        self.createdAt = createdAt
        self.messageId = messageId
        self.updatedAt = updatedAt
        self.userBadKarma = userBadKarma
        self.userKarma = userKarma
        self.blockedWord = blockedWord
        self.blocklistName = blocklistName
        self.moderatedBy = moderatedBy
        self.aiModerationResponse = aiModerationResponse
        self.moderationThresholds = moderationThresholds
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case action
        case createdAt = "created_at"
        case messageId = "message_id"
        case updatedAt = "updated_at"
        case userBadKarma = "user_bad_karma"
        case userKarma = "user_karma"
        case blockedWord = "blocked_word"
        case blocklistName = "blocklist_name"
        case moderatedBy = "moderated_by"
        case aiModerationResponse = "ai_moderation_response"
        case moderationThresholds = "moderation_thresholds"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(action, forKey: .action)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(messageId, forKey: .messageId)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(userBadKarma, forKey: .userBadKarma)
        try container.encode(userKarma, forKey: .userKarma)
        try container.encode(blockedWord, forKey: .blockedWord)
        try container.encode(blocklistName, forKey: .blocklistName)
        try container.encode(moderatedBy, forKey: .moderatedBy)
        try container.encode(aiModerationResponse, forKey: .aiModerationResponse)
        try container.encode(moderationThresholds, forKey: .moderationThresholds)
    }
}
