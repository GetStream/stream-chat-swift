//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// This event is sent when a user gets updated. The event contains information about the updated user.
final class UserUpdatedEventDTO: Sendable, Event, Decodable {
    /// Date/time of creation
    let createdAt: Date
    /// The type of event: "user.updated" in this case
    let type: String
    let user: UserPayload

    init(createdAt: Date, type: String = "user.updated", user: UserPayload) {
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
