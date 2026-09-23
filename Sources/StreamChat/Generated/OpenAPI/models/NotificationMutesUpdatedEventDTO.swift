//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class NotificationMutesUpdatedEventDTO: Sendable, Event, Decodable {
    /// Date/time of creation
    let createdAt: Date
    let custom: [String: RawJSON]
    let me: OwnUserResponse
    let receivedAt: Date?
    /// The type of event: "notification.mutes_updated" in this case
    let type: String

    init(
        createdAt: Date,
        custom: [String: RawJSON],
        me: OwnUserResponse,
        receivedAt: Date? = nil,
        type: String = "notification.mutes_updated"
    ) {
        self.createdAt = createdAt
        self.custom = custom
        self.me = me
        self.receivedAt = receivedAt
        self.type = type
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        case custom
        case me
        case receivedAt = "received_at"
        case type
    }
}
