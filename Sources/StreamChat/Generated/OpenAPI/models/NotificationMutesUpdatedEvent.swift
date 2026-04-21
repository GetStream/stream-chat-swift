//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class NotificationMutesUpdatedEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    /// Date/time of creation
    var createdAt: Date
    var custom: [String: RawJSON]
    var me: OwnUserResponse
    var receivedAt: Date?
    /// The type of event: "notification.mutes_updated" in this case
    var type: String = "notification.mutes_updated"

    init(createdAt: Date, custom: [String: RawJSON], me: OwnUserResponse, receivedAt: Date? = nil) {
        self.createdAt = createdAt
        self.custom = custom
        self.me = me
        self.receivedAt = receivedAt
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        case custom
        case me
        case receivedAt = "received_at"
        case type
    }

    static func == (lhs: NotificationMutesUpdatedEvent, rhs: NotificationMutesUpdatedEvent) -> Bool {
        lhs.createdAt == rhs.createdAt &&
            lhs.custom == rhs.custom &&
            lhs.me == rhs.me &&
            lhs.receivedAt == rhs.receivedAt &&
            lhs.type == rhs.type
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(createdAt)
        hasher.combine(custom)
        hasher.combine(me)
        hasher.combine(receivedAt)
        hasher.combine(type)
    }
}
