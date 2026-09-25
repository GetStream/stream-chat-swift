//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

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

    enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        case hardDelete = "hard_delete"
        case type
        case user
    }
}
