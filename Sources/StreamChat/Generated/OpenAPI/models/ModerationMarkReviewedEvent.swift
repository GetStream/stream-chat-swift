//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ModerationMarkReviewedEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    var createdAt: Date
    var custom: [String: RawJSON]
    var item: ReviewQueueItemResponse
    var message: MessageResponse?
    var receivedAt: Date?
    var type: String = "moderation.mark_reviewed"

    init(createdAt: Date, custom: [String: RawJSON], item: ReviewQueueItemResponse, message: MessageResponse? = nil, receivedAt: Date? = nil) {
        self.createdAt = createdAt
        self.custom = custom
        self.item = item
        self.message = message
        self.receivedAt = receivedAt
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        case custom
        case item
        case message
        case receivedAt = "received_at"
        case type
    }

    static func == (lhs: ModerationMarkReviewedEvent, rhs: ModerationMarkReviewedEvent) -> Bool {
        lhs.createdAt == rhs.createdAt &&
            lhs.custom == rhs.custom &&
            lhs.item == rhs.item &&
            lhs.message == rhs.message &&
            lhs.receivedAt == rhs.receivedAt &&
            lhs.type == rhs.type
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(createdAt)
        hasher.combine(custom)
        hasher.combine(item)
        hasher.combine(message)
        hasher.combine(receivedAt)
        hasher.combine(type)
    }
}
