//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class FlagRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Additional metadata about the flag
    var custom: [String: RawJSON]?
    /// ID of the user who created the flagged entity
    var entityCreatorId: String?
    /// Unique identifier of the entity being flagged
    var entityId: String
    /// Type of entity being flagged (e.g., message, user)
    var entityType: String
    var moderationPayload: ModerationPayload?
    /// Optional explanation for why the content is being flagged
    var reason: String?

    init(custom: [String: RawJSON]? = nil, entityCreatorId: String? = nil, entityId: String, entityType: String, moderationPayload: ModerationPayload? = nil, reason: String? = nil) {
        self.custom = custom
        self.entityCreatorId = entityCreatorId
        self.entityId = entityId
        self.entityType = entityType
        self.moderationPayload = moderationPayload
        self.reason = reason
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case custom
        case entityCreatorId = "entity_creator_id"
        case entityId = "entity_id"
        case entityType = "entity_type"
        case moderationPayload = "moderation_payload"
        case reason
    }

    static func == (lhs: FlagRequest, rhs: FlagRequest) -> Bool {
        lhs.custom == rhs.custom &&
            lhs.entityCreatorId == rhs.entityCreatorId &&
            lhs.entityId == rhs.entityId &&
            lhs.entityType == rhs.entityType &&
            lhs.moderationPayload == rhs.moderationPayload &&
            lhs.reason == rhs.reason
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(custom)
        hasher.combine(entityCreatorId)
        hasher.combine(entityId)
        hasher.combine(entityType)
        hasher.combine(moderationPayload)
        hasher.combine(reason)
    }
}
