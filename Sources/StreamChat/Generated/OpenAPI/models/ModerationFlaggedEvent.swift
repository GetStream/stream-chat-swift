//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ModerationFlaggedEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    /// The type of content that was flagged
    var contentType: String
    var createdAt: Date
    var custom: [String: RawJSON]
    /// The ID of the flagged content
    var objectId: String
    var receivedAt: Date?
    var type: String = "moderation.flagged"

    init(contentType: String, createdAt: Date, custom: [String: RawJSON], objectId: String, receivedAt: Date? = nil) {
        self.contentType = contentType
        self.createdAt = createdAt
        self.custom = custom
        self.objectId = objectId
        self.receivedAt = receivedAt
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case contentType = "content_type"
        case createdAt = "created_at"
        case custom
        case objectId = "object_id"
        case receivedAt = "received_at"
        case type
    }

    static func == (lhs: ModerationFlaggedEvent, rhs: ModerationFlaggedEvent) -> Bool {
        lhs.contentType == rhs.contentType &&
            lhs.createdAt == rhs.createdAt &&
            lhs.custom == rhs.custom &&
            lhs.objectId == rhs.objectId &&
            lhs.receivedAt == rhs.receivedAt &&
            lhs.type == rhs.type
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(contentType)
        hasher.combine(createdAt)
        hasher.combine(custom)
        hasher.combine(objectId)
        hasher.combine(receivedAt)
        hasher.combine(type)
    }
}
