//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class AppealItemResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Full chronological history of all moderation actions on the review queue item
    var actions: [ActionLogResponse]?
    /// Text severity level assigned by the AI provider
    var aiTextSeverity: String?
    /// Reason Text of the Appeal Item
    var appealReason: String
    /// Attachments(e.g. Images) of the Appeal Item
    var attachments: [String]?
    /// CID of the channel the entity belongs to, if applicable
    var channelCid: String?
    /// Moderation policy key that was applied
    var configKey: String?
    /// When the flag was created
    var createdAt: Date
    /// Decision Reason of the Appeal Item
    var decisionReason: String?
    var entityContent: ModerationPayload?
    /// ID of the entity
    var entityId: String
    /// Type of entity
    var entityType: String
    /// Classification labels from automated and manual review
    var flagLabels: [String]?
    /// Types of flags applied to the entity (e.g. user_report, bodyguard)
    var flagTypes: [String]?
    /// Per-provider flag records explaining why the action was taken
    var flags: [ModerationFlagResponse]?
    var id: String
    var moderationAction: ActionLogResponse?
    var originalModerationAction: ActionLogResponse?
    /// Action recommended by the automated moderation system (e.g. flag, remove, shadow)
    var recommendedAction: String?
    /// ID of the review queue item linked to this appeal, if the appeal was submitted with one
    var reviewQueueItemId: String?
    /// Overall content severity score (1–100)
    var severity: Int?
    /// Status of the Appeal Item
    var status: String
    /// When the flag was last updated
    var updatedAt: Date
    var user: UserResponse?

    init(actions: [ActionLogResponse]? = nil, aiTextSeverity: String? = nil, appealReason: String, attachments: [String]? = nil, channelCid: String? = nil, configKey: String? = nil, createdAt: Date, decisionReason: String? = nil, entityContent: ModerationPayload? = nil, entityId: String, entityType: String, flagLabels: [String]? = nil, flagTypes: [String]? = nil, flags: [ModerationFlagResponse]? = nil, id: String, moderationAction: ActionLogResponse? = nil, originalModerationAction: ActionLogResponse? = nil, recommendedAction: String? = nil, reviewQueueItemId: String? = nil, severity: Int? = nil, status: String, updatedAt: Date, user: UserResponse? = nil) {
        self.actions = actions
        self.aiTextSeverity = aiTextSeverity
        self.appealReason = appealReason
        self.attachments = attachments
        self.channelCid = channelCid
        self.configKey = configKey
        self.createdAt = createdAt
        self.decisionReason = decisionReason
        self.entityContent = entityContent
        self.entityId = entityId
        self.entityType = entityType
        self.flagLabels = flagLabels
        self.flagTypes = flagTypes
        self.flags = flags
        self.id = id
        self.moderationAction = moderationAction
        self.originalModerationAction = originalModerationAction
        self.recommendedAction = recommendedAction
        self.reviewQueueItemId = reviewQueueItemId
        self.severity = severity
        self.status = status
        self.updatedAt = updatedAt
        self.user = user
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case actions
        case aiTextSeverity = "ai_text_severity"
        case appealReason = "appeal_reason"
        case attachments
        case channelCid = "channel_cid"
        case configKey = "config_key"
        case createdAt = "created_at"
        case decisionReason = "decision_reason"
        case entityContent = "entity_content"
        case entityId = "entity_id"
        case entityType = "entity_type"
        case flagLabels = "flag_labels"
        case flagTypes = "flag_types"
        case flags
        case id
        case moderationAction = "moderation_action"
        case originalModerationAction = "original_moderation_action"
        case recommendedAction = "recommended_action"
        case reviewQueueItemId = "review_queue_item_id"
        case severity
        case status
        case updatedAt = "updated_at"
        case user
    }

    static func == (lhs: AppealItemResponse, rhs: AppealItemResponse) -> Bool {
        lhs.actions == rhs.actions &&
            lhs.aiTextSeverity == rhs.aiTextSeverity &&
            lhs.appealReason == rhs.appealReason &&
            lhs.attachments == rhs.attachments &&
            lhs.channelCid == rhs.channelCid &&
            lhs.configKey == rhs.configKey &&
            lhs.createdAt == rhs.createdAt &&
            lhs.decisionReason == rhs.decisionReason &&
            lhs.entityContent == rhs.entityContent &&
            lhs.entityId == rhs.entityId &&
            lhs.entityType == rhs.entityType &&
            lhs.flagLabels == rhs.flagLabels &&
            lhs.flagTypes == rhs.flagTypes &&
            lhs.flags == rhs.flags &&
            lhs.id == rhs.id &&
            lhs.moderationAction == rhs.moderationAction &&
            lhs.originalModerationAction == rhs.originalModerationAction &&
            lhs.recommendedAction == rhs.recommendedAction &&
            lhs.reviewQueueItemId == rhs.reviewQueueItemId &&
            lhs.severity == rhs.severity &&
            lhs.status == rhs.status &&
            lhs.updatedAt == rhs.updatedAt &&
            lhs.user == rhs.user
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(actions)
        hasher.combine(aiTextSeverity)
        hasher.combine(appealReason)
        hasher.combine(attachments)
        hasher.combine(channelCid)
        hasher.combine(configKey)
        hasher.combine(createdAt)
        hasher.combine(decisionReason)
        hasher.combine(entityContent)
        hasher.combine(entityId)
        hasher.combine(entityType)
        hasher.combine(flagLabels)
        hasher.combine(flagTypes)
        hasher.combine(flags)
        hasher.combine(id)
        hasher.combine(moderationAction)
        hasher.combine(originalModerationAction)
        hasher.combine(recommendedAction)
        hasher.combine(reviewQueueItemId)
        hasher.combine(severity)
        hasher.combine(status)
        hasher.combine(updatedAt)
        hasher.combine(user)
    }
}
