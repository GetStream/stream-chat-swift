//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

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

    enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        case type
        case user
    }
}
