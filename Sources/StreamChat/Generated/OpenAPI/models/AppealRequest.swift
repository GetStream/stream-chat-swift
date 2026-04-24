//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class AppealRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Explanation for why the content is being appealed
    var appealReason: String
    /// [RawJSON] of Attachment URLs(e.g., images)
    var attachments: [String]?
    /// Unique identifier of the entity being appealed
    var entityId: String
    /// Type of entity being appealed (e.g., message, user)
    var entityType: String

    init(appealReason: String, attachments: [String]? = nil, entityId: String, entityType: String) {
        self.appealReason = appealReason
        self.attachments = attachments
        self.entityId = entityId
        self.entityType = entityType
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case appealReason = "appeal_reason"
        case attachments
        case entityId = "entity_id"
        case entityType = "entity_type"
    }

    static func == (lhs: AppealRequest, rhs: AppealRequest) -> Bool {
        lhs.appealReason == rhs.appealReason &&
            lhs.attachments == rhs.attachments &&
            lhs.entityId == rhs.entityId &&
            lhs.entityType == rhs.entityType
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(appealReason)
        hasher.combine(attachments)
        hasher.combine(entityId)
        hasher.combine(entityType)
    }
}
