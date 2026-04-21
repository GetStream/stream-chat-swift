//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class MessageModerationResult: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Action taken by automod
    var action: String
    var aiModerationResponse: ModerationResponse?
    /// Word that was blocked
    var blockedWord: String?
    /// Name of the blocklist
    var blocklistName: String?
    /// Date/time of creation
    var createdAt: Date
    /// ID of the message
    var messageId: String
    /// User who moderated the message
    var moderatedBy: String?
    var moderationThresholds: Thresholds?
    /// Date/time of the last update
    var updatedAt: Date
    /// Whether user has bad karma
    var userBadKarma: Bool
    /// Karma of the user
    var userKarma: Float

    init(action: String, aiModerationResponse: ModerationResponse? = nil, blockedWord: String? = nil, blocklistName: String? = nil, createdAt: Date, messageId: String, moderatedBy: String? = nil, moderationThresholds: Thresholds? = nil, updatedAt: Date, userBadKarma: Bool, userKarma: Float) {
        self.action = action
        self.aiModerationResponse = aiModerationResponse
        self.blockedWord = blockedWord
        self.blocklistName = blocklistName
        self.createdAt = createdAt
        self.messageId = messageId
        self.moderatedBy = moderatedBy
        self.moderationThresholds = moderationThresholds
        self.updatedAt = updatedAt
        self.userBadKarma = userBadKarma
        self.userKarma = userKarma
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case action
        case aiModerationResponse = "ai_moderation_response"
        case blockedWord = "blocked_word"
        case blocklistName = "blocklist_name"
        case createdAt = "created_at"
        case messageId = "message_id"
        case moderatedBy = "moderated_by"
        case moderationThresholds = "moderation_thresholds"
        case updatedAt = "updated_at"
        case userBadKarma = "user_bad_karma"
        case userKarma = "user_karma"
    }

    static func == (lhs: MessageModerationResult, rhs: MessageModerationResult) -> Bool {
        lhs.action == rhs.action &&
            lhs.aiModerationResponse == rhs.aiModerationResponse &&
            lhs.blockedWord == rhs.blockedWord &&
            lhs.blocklistName == rhs.blocklistName &&
            lhs.createdAt == rhs.createdAt &&
            lhs.messageId == rhs.messageId &&
            lhs.moderatedBy == rhs.moderatedBy &&
            lhs.moderationThresholds == rhs.moderationThresholds &&
            lhs.updatedAt == rhs.updatedAt &&
            lhs.userBadKarma == rhs.userBadKarma &&
            lhs.userKarma == rhs.userKarma
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(action)
        hasher.combine(aiModerationResponse)
        hasher.combine(blockedWord)
        hasher.combine(blocklistName)
        hasher.combine(createdAt)
        hasher.combine(messageId)
        hasher.combine(moderatedBy)
        hasher.combine(moderationThresholds)
        hasher.combine(updatedAt)
        hasher.combine(userBadKarma)
        hasher.combine(userKarma)
    }
}
