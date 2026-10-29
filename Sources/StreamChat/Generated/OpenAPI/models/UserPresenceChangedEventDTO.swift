//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// This event is sent when the presence of a user changes. The event contains information about the user whose presence changed.
final class UserPresenceChangedEventDTO: Sendable, Event, Decodable {
    /// Date/time of creation
    let createdAt: Date
    /// The type of event: "user.presence.changed" in this case
    let type: String
    let user: UserPayload

    init(createdAt: Date, type: String = "user.presence.changed", user: UserPayload) {
        self.createdAt = createdAt
        self.type = type
        self.user = user
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.type = try container.decode(String.self, forKey: .type)
        self.user = try container.decode(UserPayload.self, forKey: .user)
    }
}
