//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ModerationFlagResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var createdAt: Date
    var custom: [String: RawJSON]?
    var entityCreatorId: String?
    var entityId: String
    var entityType: String
    var labels: [String]?
    var moderationPayload: ModerationPayloadResponse?
    var reason: String?
    var result: [[String: RawJSON]]
    var reviewQueueItem: ReviewQueueItemResponse?
    var reviewQueueItemId: String?
    var type: String
    var updatedAt: Date
    var user: UserResponse?
    var userId: String

    init(createdAt: Date, custom: [String: RawJSON]? = nil, entityCreatorId: String? = nil, entityId: String, entityType: String, labels: [String]? = nil, moderationPayload: ModerationPayloadResponse? = nil, reason: String? = nil, result: [[String: RawJSON]], reviewQueueItem: ReviewQueueItemResponse? = nil, reviewQueueItemId: String? = nil, type: String, updatedAt: Date, user: UserResponse? = nil, userId: String) {
        self.createdAt = createdAt
        self.custom = custom
        self.entityCreatorId = entityCreatorId
        self.entityId = entityId
        self.entityType = entityType
        self.labels = labels
        self.moderationPayload = moderationPayload
        self.reason = reason
        self.result = result
        self.reviewQueueItem = reviewQueueItem
        self.reviewQueueItemId = reviewQueueItemId
        self.type = type
        self.updatedAt = updatedAt
        self.user = user
        self.userId = userId
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        case custom
        case entityCreatorId = "entity_creator_id"
        case entityId = "entity_id"
        case entityType = "entity_type"
        case labels
        case moderationPayload = "moderation_payload"
        case reason
        case result
        case reviewQueueItem = "review_queue_item"
        case reviewQueueItemId = "review_queue_item_id"
        case type
        case updatedAt = "updated_at"
        case user
        case userId = "user_id"
    }

    static func == (lhs: ModerationFlagResponse, rhs: ModerationFlagResponse) -> Bool {
        lhs.createdAt == rhs.createdAt &&
            lhs.custom == rhs.custom &&
            lhs.entityCreatorId == rhs.entityCreatorId &&
            lhs.entityId == rhs.entityId &&
            lhs.entityType == rhs.entityType &&
            lhs.labels == rhs.labels &&
            lhs.moderationPayload == rhs.moderationPayload &&
            lhs.reason == rhs.reason &&
            lhs.result == rhs.result &&
            lhs.reviewQueueItem == rhs.reviewQueueItem &&
            lhs.reviewQueueItemId == rhs.reviewQueueItemId &&
            lhs.type == rhs.type &&
            lhs.updatedAt == rhs.updatedAt &&
            lhs.user == rhs.user &&
            lhs.userId == rhs.userId
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(createdAt)
        hasher.combine(custom)
        hasher.combine(entityCreatorId)
        hasher.combine(entityId)
        hasher.combine(entityType)
        hasher.combine(labels)
        hasher.combine(moderationPayload)
        hasher.combine(reason)
        hasher.combine(result)
        hasher.combine(reviewQueueItem)
        hasher.combine(reviewQueueItemId)
        hasher.combine(type)
        hasher.combine(updatedAt)
        hasher.combine(user)
        hasher.combine(userId)
    }
}
