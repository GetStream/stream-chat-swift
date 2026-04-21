//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ReminderDeletedEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    /// The CID of the Channel for which the reminder was created
    var cid: String
    /// Date/time of creation
    var createdAt: Date
    var custom: [String: RawJSON]
    /// The ID of the message for which the reminder was created
    var messageId: String
    /// The ID of the parent message, if the reminder is for a thread message
    var parentId: String?
    var receivedAt: Date?
    var reminder: ReminderResponseData?
    /// The type of event: "reminder.deleted" in this case
    var type: String = "reminder.deleted"
    /// The ID of the user for whom the reminder was created
    var userId: String

    init(cid: String, createdAt: Date, custom: [String: RawJSON], messageId: String, parentId: String? = nil, receivedAt: Date? = nil, reminder: ReminderResponseData? = nil, userId: String) {
        self.cid = cid
        self.createdAt = createdAt
        self.custom = custom
        self.messageId = messageId
        self.parentId = parentId
        self.receivedAt = receivedAt
        self.reminder = reminder
        self.userId = userId
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case cid
        case createdAt = "created_at"
        case custom
        case messageId = "message_id"
        case parentId = "parent_id"
        case receivedAt = "received_at"
        case reminder
        case type
        case userId = "user_id"
    }

    static func == (lhs: ReminderDeletedEvent, rhs: ReminderDeletedEvent) -> Bool {
        lhs.cid == rhs.cid &&
            lhs.createdAt == rhs.createdAt &&
            lhs.custom == rhs.custom &&
            lhs.messageId == rhs.messageId &&
            lhs.parentId == rhs.parentId &&
            lhs.receivedAt == rhs.receivedAt &&
            lhs.reminder == rhs.reminder &&
            lhs.type == rhs.type &&
            lhs.userId == rhs.userId
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(cid)
        hasher.combine(createdAt)
        hasher.combine(custom)
        hasher.combine(messageId)
        hasher.combine(parentId)
        hasher.combine(receivedAt)
        hasher.combine(reminder)
        hasher.combine(type)
        hasher.combine(userId)
    }
}
