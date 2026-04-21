//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class AppealItemResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Reason Text of the Appeal Item
    var appealReason: String
    /// Attachments(e.g. Images) of the Appeal Item
    var attachments: [String]?
    /// When the flag was created
    var createdAt: Date
    /// Decision Reason of the Appeal Item
    var decisionReason: String?
    var entityContent: ModerationPayload?
    /// ID of the entity
    var entityId: String
    /// Type of entity
    var entityType: String
    var id: String
    /// Status of the Appeal Item
    var status: String
    /// When the flag was last updated
    var updatedAt: Date
    var user: UserResponse?

    init(appealReason: String, attachments: [String]? = nil, createdAt: Date, decisionReason: String? = nil, entityContent: ModerationPayload? = nil, entityId: String, entityType: String, id: String, status: String, updatedAt: Date, user: UserResponse? = nil) {
        self.appealReason = appealReason
        self.attachments = attachments
        self.createdAt = createdAt
        self.decisionReason = decisionReason
        self.entityContent = entityContent
        self.entityId = entityId
        self.entityType = entityType
        self.id = id
        self.status = status
        self.updatedAt = updatedAt
        self.user = user
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case appealReason = "appeal_reason"
        case attachments
        case createdAt = "created_at"
        case decisionReason = "decision_reason"
        case entityContent = "entity_content"
        case entityId = "entity_id"
        case entityType = "entity_type"
        case id
        case status
        case updatedAt = "updated_at"
        case user
    }

    static func == (lhs: AppealItemResponse, rhs: AppealItemResponse) -> Bool {
        lhs.appealReason == rhs.appealReason &&
            lhs.attachments == rhs.attachments &&
            lhs.createdAt == rhs.createdAt &&
            lhs.decisionReason == rhs.decisionReason &&
            lhs.entityContent == rhs.entityContent &&
            lhs.entityId == rhs.entityId &&
            lhs.entityType == rhs.entityType &&
            lhs.id == rhs.id &&
            lhs.status == rhs.status &&
            lhs.updatedAt == rhs.updatedAt &&
            lhs.user == rhs.user
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(appealReason)
        hasher.combine(attachments)
        hasher.combine(createdAt)
        hasher.combine(decisionReason)
        hasher.combine(entityContent)
        hasher.combine(entityId)
        hasher.combine(entityType)
        hasher.combine(id)
        hasher.combine(status)
        hasher.combine(updatedAt)
        hasher.combine(user)
    }
}
