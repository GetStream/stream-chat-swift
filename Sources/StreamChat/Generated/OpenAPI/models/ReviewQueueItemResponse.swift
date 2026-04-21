//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ReviewQueueItemResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Moderation actions taken
    var actions: [ActionLogResponse]
    var activity: EnrichedActivity?
    /// AI-determined text severity
    var aiTextSeverity: String
    var appeal: AppealItemResponse?
    var assignedTo: UserResponse?
    /// Associated ban records
    var bans: [BanInfoResponse]
    var call: CallResponse?
    /// When the review was completed
    var completedAt: Date?
    var configKey: String?
    /// When the item was created
    var createdAt: Date
    var entityCreator: EntityCreatorResponse?
    /// ID of who created the entity
    var entityCreatorId: String?
    /// ID of the entity being reviewed
    var entityId: String
    /// Type of entity being reviewed
    var entityType: String
    /// Whether the item has been escalated
    var escalated: Bool
    /// When the item was escalated
    var escalatedAt: Date?
    /// ID of the moderator who escalated the item
    var escalatedBy: String?
    var escalationMetadata: EscalationMetadata?
    var feedsV2Activity: EnrichedActivity?
    var feedsV2Reaction: Reaction?
    var feedsV3Activity: FeedsV3ActivityResponse?
    var feedsV3Comment: FeedsV3CommentResponse?
    /// Associated flag records
    var flags: [ModerationFlagResponse]
    var flagsCount: Int
    /// Unique identifier of the review queue item
    var id: String
    /// Detected languages in the content
    var languages: [String]
    var latestModeratorAction: String
    var message: MessageResponse?
    var moderationPayload: ModerationPayloadResponse?
    var reaction: Reaction?
    /// Suggested moderation action
    var recommendedAction: String
    /// When the item was reviewed
    var reviewedAt: Date?
    /// ID of the moderator who reviewed the item
    var reviewedBy: String
    /// Severity level of the content
    var severity: Int
    /// Current status of the review
    var status: String
    /// Teams associated with this item
    var teams: [String]?
    /// When the item was last updated
    var updatedAt: Date

    init(actions: [ActionLogResponse], activity: EnrichedActivity? = nil, aiTextSeverity: String, appeal: AppealItemResponse? = nil, assignedTo: UserResponse? = nil, bans: [BanInfoResponse], call: CallResponse? = nil, completedAt: Date? = nil, configKey: String? = nil, createdAt: Date, entityCreator: EntityCreatorResponse? = nil, entityCreatorId: String? = nil, entityId: String, entityType: String, escalated: Bool, escalatedAt: Date? = nil, escalatedBy: String? = nil, escalationMetadata: EscalationMetadata? = nil, feedsV2Activity: EnrichedActivity? = nil, feedsV2Reaction: Reaction? = nil, feedsV3Activity: FeedsV3ActivityResponse? = nil, feedsV3Comment: FeedsV3CommentResponse? = nil, flags: [ModerationFlagResponse], flagsCount: Int, id: String, languages: [String], latestModeratorAction: String, message: MessageResponse? = nil, moderationPayload: ModerationPayloadResponse? = nil, reaction: Reaction? = nil, recommendedAction: String, reviewedAt: Date? = nil, reviewedBy: String, severity: Int, status: String, teams: [String]? = nil, updatedAt: Date) {
        self.actions = actions
        self.activity = activity
        self.aiTextSeverity = aiTextSeverity
        self.appeal = appeal
        self.assignedTo = assignedTo
        self.bans = bans
        self.call = call
        self.completedAt = completedAt
        self.configKey = configKey
        self.createdAt = createdAt
        self.entityCreator = entityCreator
        self.entityCreatorId = entityCreatorId
        self.entityId = entityId
        self.entityType = entityType
        self.escalated = escalated
        self.escalatedAt = escalatedAt
        self.escalatedBy = escalatedBy
        self.escalationMetadata = escalationMetadata
        self.feedsV2Activity = feedsV2Activity
        self.feedsV2Reaction = feedsV2Reaction
        self.feedsV3Activity = feedsV3Activity
        self.feedsV3Comment = feedsV3Comment
        self.flags = flags
        self.flagsCount = flagsCount
        self.id = id
        self.languages = languages
        self.latestModeratorAction = latestModeratorAction
        self.message = message
        self.moderationPayload = moderationPayload
        self.reaction = reaction
        self.recommendedAction = recommendedAction
        self.reviewedAt = reviewedAt
        self.reviewedBy = reviewedBy
        self.severity = severity
        self.status = status
        self.teams = teams
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case actions
        case activity
        case aiTextSeverity = "ai_text_severity"
        case appeal
        case assignedTo = "assigned_to"
        case bans
        case call
        case completedAt = "completed_at"
        case configKey = "config_key"
        case createdAt = "created_at"
        case entityCreator = "entity_creator"
        case entityCreatorId = "entity_creator_id"
        case entityId = "entity_id"
        case entityType = "entity_type"
        case escalated
        case escalatedAt = "escalated_at"
        case escalatedBy = "escalated_by"
        case escalationMetadata = "escalation_metadata"
        case feedsV2Activity = "feeds_v2_activity"
        case feedsV2Reaction = "feeds_v2_reaction"
        case feedsV3Activity = "feeds_v3_activity"
        case feedsV3Comment = "feeds_v3_comment"
        case flags
        case flagsCount = "flags_count"
        case id
        case languages
        case latestModeratorAction = "latest_moderator_action"
        case message
        case moderationPayload = "moderation_payload"
        case reaction
        case recommendedAction = "recommended_action"
        case reviewedAt = "reviewed_at"
        case reviewedBy = "reviewed_by"
        case severity
        case status
        case teams
        case updatedAt = "updated_at"
    }

    static func == (lhs: ReviewQueueItemResponse, rhs: ReviewQueueItemResponse) -> Bool {
        lhs.actions == rhs.actions &&
            lhs.activity == rhs.activity &&
            lhs.aiTextSeverity == rhs.aiTextSeverity &&
            lhs.appeal == rhs.appeal &&
            lhs.assignedTo == rhs.assignedTo &&
            lhs.bans == rhs.bans &&
            lhs.call == rhs.call &&
            lhs.completedAt == rhs.completedAt &&
            lhs.configKey == rhs.configKey &&
            lhs.createdAt == rhs.createdAt &&
            lhs.entityCreator == rhs.entityCreator &&
            lhs.entityCreatorId == rhs.entityCreatorId &&
            lhs.entityId == rhs.entityId &&
            lhs.entityType == rhs.entityType &&
            lhs.escalated == rhs.escalated &&
            lhs.escalatedAt == rhs.escalatedAt &&
            lhs.escalatedBy == rhs.escalatedBy &&
            lhs.escalationMetadata == rhs.escalationMetadata &&
            lhs.feedsV2Activity == rhs.feedsV2Activity &&
            lhs.feedsV2Reaction == rhs.feedsV2Reaction &&
            lhs.feedsV3Activity == rhs.feedsV3Activity &&
            lhs.feedsV3Comment == rhs.feedsV3Comment &&
            lhs.flags == rhs.flags &&
            lhs.flagsCount == rhs.flagsCount &&
            lhs.id == rhs.id &&
            lhs.languages == rhs.languages &&
            lhs.latestModeratorAction == rhs.latestModeratorAction &&
            lhs.message == rhs.message &&
            lhs.moderationPayload == rhs.moderationPayload &&
            lhs.reaction == rhs.reaction &&
            lhs.recommendedAction == rhs.recommendedAction &&
            lhs.reviewedAt == rhs.reviewedAt &&
            lhs.reviewedBy == rhs.reviewedBy &&
            lhs.severity == rhs.severity &&
            lhs.status == rhs.status &&
            lhs.teams == rhs.teams &&
            lhs.updatedAt == rhs.updatedAt
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(actions)
        hasher.combine(activity)
        hasher.combine(aiTextSeverity)
        hasher.combine(appeal)
        hasher.combine(assignedTo)
        hasher.combine(bans)
        hasher.combine(call)
        hasher.combine(completedAt)
        hasher.combine(configKey)
        hasher.combine(createdAt)
        hasher.combine(entityCreator)
        hasher.combine(entityCreatorId)
        hasher.combine(entityId)
        hasher.combine(entityType)
        hasher.combine(escalated)
        hasher.combine(escalatedAt)
        hasher.combine(escalatedBy)
        hasher.combine(escalationMetadata)
        hasher.combine(feedsV2Activity)
        hasher.combine(feedsV2Reaction)
        hasher.combine(feedsV3Activity)
        hasher.combine(feedsV3Comment)
        hasher.combine(flags)
        hasher.combine(flagsCount)
        hasher.combine(id)
        hasher.combine(languages)
        hasher.combine(latestModeratorAction)
        hasher.combine(message)
        hasher.combine(moderationPayload)
        hasher.combine(reaction)
        hasher.combine(recommendedAction)
        hasher.combine(reviewedAt)
        hasher.combine(reviewedBy)
        hasher.combine(severity)
        hasher.combine(status)
        hasher.combine(teams)
        hasher.combine(updatedAt)
    }
}
