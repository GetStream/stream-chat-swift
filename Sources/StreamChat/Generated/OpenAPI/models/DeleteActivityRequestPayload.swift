//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class DeleteActivityRequestPayload: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// ID of the activity to delete (alternative to item_id)
    var entityId: String?
    /// Type of the entity (required for delete_activity to distinguish v2 vs v3)
    var entityType: String?
    /// Whether to permanently delete the activity
    var hardDelete: Bool?
    /// Reason for deletion
    var reason: String?

    init(entityId: String? = nil, entityType: String? = nil, hardDelete: Bool? = nil, reason: String? = nil) {
        self.entityId = entityId
        self.entityType = entityType
        self.hardDelete = hardDelete
        self.reason = reason
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case entityId = "entity_id"
        case entityType = "entity_type"
        case hardDelete = "hard_delete"
        case reason
    }

    static func == (lhs: DeleteActivityRequestPayload, rhs: DeleteActivityRequestPayload) -> Bool {
        lhs.entityId == rhs.entityId &&
            lhs.entityType == rhs.entityType &&
            lhs.hardDelete == rhs.hardDelete &&
            lhs.reason == rhs.reason
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(entityId)
        hasher.combine(entityType)
        hasher.combine(hardDelete)
        hasher.combine(reason)
    }
}
