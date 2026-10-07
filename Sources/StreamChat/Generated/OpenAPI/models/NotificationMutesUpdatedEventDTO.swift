//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// This event is sent when the notification mutes of a user are updated.
final class NotificationMutesUpdatedEventDTO: Sendable, Event, Decodable {
    /// Date/time of creation
    let createdAt: Date
    let me: OwnUserResponse
    /// The type of event: "notification.mutes_updated" in this case
    let type: String

    init(createdAt: Date, me: OwnUserResponse, type: String = "notification.mutes_updated") {
        self.createdAt = createdAt
        self.me = me
        self.type = type
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.me = try container.decode(OwnUserResponse.self, forKey: .me)
        self.type = try container.decode(String.self, forKey: .type)
    }
}
