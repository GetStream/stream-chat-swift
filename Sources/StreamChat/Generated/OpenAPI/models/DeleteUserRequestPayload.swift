//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class DeleteUserRequestPayload: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Also delete all user conversations
    var deleteConversationChannels: Bool?
    /// Delete flagged feeds content
    var deleteFeedsContent: Bool?
    /// ID of the user to delete (alternative to item_id)
    var entityId: String?
    /// Type of the entity
    var entityType: String?
    /// Whether to permanently delete the user
    var hardDelete: Bool?
    /// Also delete all user messages
    var markMessagesDeleted: Bool?
    /// Reason for deletion
    var reason: String?

    init(deleteConversationChannels: Bool? = nil, deleteFeedsContent: Bool? = nil, entityId: String? = nil, entityType: String? = nil, hardDelete: Bool? = nil, markMessagesDeleted: Bool? = nil, reason: String? = nil) {
        self.deleteConversationChannels = deleteConversationChannels
        self.deleteFeedsContent = deleteFeedsContent
        self.entityId = entityId
        self.entityType = entityType
        self.hardDelete = hardDelete
        self.markMessagesDeleted = markMessagesDeleted
        self.reason = reason
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case deleteConversationChannels = "delete_conversation_channels"
        case deleteFeedsContent = "delete_feeds_content"
        case entityId = "entity_id"
        case entityType = "entity_type"
        case hardDelete = "hard_delete"
        case markMessagesDeleted = "mark_messages_deleted"
        case reason
    }

    static func == (lhs: DeleteUserRequestPayload, rhs: DeleteUserRequestPayload) -> Bool {
        lhs.deleteConversationChannels == rhs.deleteConversationChannels &&
            lhs.deleteFeedsContent == rhs.deleteFeedsContent &&
            lhs.entityId == rhs.entityId &&
            lhs.entityType == rhs.entityType &&
            lhs.hardDelete == rhs.hardDelete &&
            lhs.markMessagesDeleted == rhs.markMessagesDeleted &&
            lhs.reason == rhs.reason
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(deleteConversationChannels)
        hasher.combine(deleteFeedsContent)
        hasher.combine(entityId)
        hasher.combine(entityType)
        hasher.combine(hardDelete)
        hasher.combine(markMessagesDeleted)
        hasher.combine(reason)
    }
}
