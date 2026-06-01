//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class AppealItemResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Reason Text of the Appeal Item
    var appealReason: String
    /// Attachments(e.g. Images) of the Appeal Item
    var attachments: [String]?
    /// CID of the channel the entity belongs to, if applicable
    var channelCid: String?
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
    var id: String
    var moderationAction: ActionLogResponse?
    /// Action recommended by the automated moderation system (e.g. flag, remove, shadow)
    var recommendedAction: String?
    /// Status of the Appeal Item
    var status: String
    /// When the flag was last updated
    var updatedAt: Date
    var user: UserResponse?

    init(appealReason: String, attachments: [String]? = nil, channelCid: String? = nil, createdAt: Date, decisionReason: String? = nil, entityContent: ModerationPayload? = nil, entityId: String, entityType: String, flagLabels: [String]? = nil, flagTypes: [String]? = nil, id: String, moderationAction: ActionLogResponse? = nil, recommendedAction: String? = nil, status: String, updatedAt: Date, user: UserResponse? = nil) {
        self.appealReason = appealReason
        self.attachments = attachments
        self.channelCid = channelCid
        self.createdAt = createdAt
        self.decisionReason = decisionReason
        self.entityContent = entityContent
        self.entityId = entityId
        self.entityType = entityType
        self.flagLabels = flagLabels
        self.flagTypes = flagTypes
        self.id = id
        self.moderationAction = moderationAction
        self.recommendedAction = recommendedAction
        self.status = status
        self.updatedAt = updatedAt
        self.user = user
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case appealReason = "appeal_reason"
        case attachments
        case channelCid = "channel_cid"
        case createdAt = "created_at"
        case decisionReason = "decision_reason"
        case entityContent = "entity_content"
        case entityId = "entity_id"
        case entityType = "entity_type"
        case flagLabels = "flag_labels"
        case flagTypes = "flag_types"
        case id
        case moderationAction = "moderation_action"
        case recommendedAction = "recommended_action"
        case status
        case updatedAt = "updated_at"
        case user
    }

    static func == (lhs: AppealItemResponse, rhs: AppealItemResponse) -> Bool {
        lhs.appealReason == rhs.appealReason &&
            lhs.attachments == rhs.attachments &&
            lhs.channelCid == rhs.channelCid &&
            lhs.createdAt == rhs.createdAt &&
            lhs.decisionReason == rhs.decisionReason &&
            lhs.entityContent == rhs.entityContent &&
            lhs.entityId == rhs.entityId &&
            lhs.entityType == rhs.entityType &&
            lhs.flagLabels == rhs.flagLabels &&
            lhs.flagTypes == rhs.flagTypes &&
            lhs.id == rhs.id &&
            lhs.moderationAction == rhs.moderationAction &&
            lhs.recommendedAction == rhs.recommendedAction &&
            lhs.status == rhs.status &&
            lhs.updatedAt == rhs.updatedAt &&
            lhs.user == rhs.user
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(appealReason)
        hasher.combine(attachments)
        hasher.combine(channelCid)
        hasher.combine(createdAt)
        hasher.combine(decisionReason)
        hasher.combine(entityContent)
        hasher.combine(entityId)
        hasher.combine(entityType)
        hasher.combine(flagLabels)
        hasher.combine(flagTypes)
        hasher.combine(id)
        hasher.combine(moderationAction)
        hasher.combine(recommendedAction)
        hasher.combine(status)
        hasher.combine(updatedAt)
        hasher.combine(user)
    }
}
