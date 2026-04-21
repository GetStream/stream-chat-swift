//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UserDeletedEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    /// Date/time of creation
    var createdAt: Date
    var custom: [String: RawJSON]
    /// The type of deletion that was used for the user's conversations. One of: hard, soft, pruning, (empty string)
    var deleteConversation: String
    /// Whether the user's conversation channels were deleted
    var deleteConversationChannels: Bool
    /// The type of deletion that was used for the user's messages. One of: hard, soft, pruning, (empty string)
    var deleteMessages: String
    /// The type of deletion that was used for the user. One of: hard, soft, pruning, (empty string)
    var deleteUser: String
    /// Whether the user was hard deleted
    var hardDelete: Bool
    /// Whether the user's messages were marked as deleted
    var markMessagesDeleted: Bool
    var receivedAt: Date?
    /// The type of event: "user.deleted" in this case
    var type: String = "user.deleted"
    var user: UserResponseCommonFields

    init(createdAt: Date, custom: [String: RawJSON], deleteConversation: String, deleteConversationChannels: Bool, deleteMessages: String, deleteUser: String, hardDelete: Bool, markMessagesDeleted: Bool, receivedAt: Date? = nil, user: UserResponseCommonFields) {
        self.createdAt = createdAt
        self.custom = custom
        self.deleteConversation = deleteConversation
        self.deleteConversationChannels = deleteConversationChannels
        self.deleteMessages = deleteMessages
        self.deleteUser = deleteUser
        self.hardDelete = hardDelete
        self.markMessagesDeleted = markMessagesDeleted
        self.receivedAt = receivedAt
        self.user = user
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        case custom
        case deleteConversation = "delete_conversation"
        case deleteConversationChannels = "delete_conversation_channels"
        case deleteMessages = "delete_messages"
        case deleteUser = "delete_user"
        case hardDelete = "hard_delete"
        case markMessagesDeleted = "mark_messages_deleted"
        case receivedAt = "received_at"
        case type
        case user
    }

    static func == (lhs: UserDeletedEvent, rhs: UserDeletedEvent) -> Bool {
        lhs.createdAt == rhs.createdAt &&
            lhs.custom == rhs.custom &&
            lhs.deleteConversation == rhs.deleteConversation &&
            lhs.deleteConversationChannels == rhs.deleteConversationChannels &&
            lhs.deleteMessages == rhs.deleteMessages &&
            lhs.deleteUser == rhs.deleteUser &&
            lhs.hardDelete == rhs.hardDelete &&
            lhs.markMessagesDeleted == rhs.markMessagesDeleted &&
            lhs.receivedAt == rhs.receivedAt &&
            lhs.type == rhs.type &&
            lhs.user == rhs.user
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(createdAt)
        hasher.combine(custom)
        hasher.combine(deleteConversation)
        hasher.combine(deleteConversationChannels)
        hasher.combine(deleteMessages)
        hasher.combine(deleteUser)
        hasher.combine(hardDelete)
        hasher.combine(markMessagesDeleted)
        hasher.combine(receivedAt)
        hasher.combine(type)
        hasher.combine(user)
    }
}
