//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// This event is sent when a user's message get deleted. The event contains information about the user whose messages got deleted.
final class UserMessagesDeletedEventDTO: Sendable, Event, Decodable {
    /// Date/time of creation
    let createdAt: Date
    /// Whether Messages were hard deleted
    let hardDelete: Bool?
    /// The type of event: "user.messages.deleted" in this case
    let type: String
    let user: UserPayload

    init(
        createdAt: Date,
        hardDelete: Bool? = nil,
        type: String = "user.messages.deleted",
        user: UserPayload
    ) {
        self.createdAt = createdAt
        self.hardDelete = hardDelete
        self.type = type
        self.user = user
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.hardDelete = try container.decodeIfPresent(Bool.self, forKey: .hardDelete)
        self.type = try container.decode(String.self, forKey: .type)
        self.user = try container.decode(UserPayload.self, forKey: .user)
    }
}
