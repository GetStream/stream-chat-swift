//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Represents a user that is participating in a thread.
final class ThreadParticipantPayload: Sendable, Decodable {
    /// Date/time of creation
    let createdAt: Date
    let lastReadAt: Date
    /// User response object
    let user: UserPayload?

    init(createdAt: Date, lastReadAt: Date, user: UserPayload? = nil) {
        self.createdAt = createdAt
        self.lastReadAt = lastReadAt
        self.user = user
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        case lastReadAt = "last_read_at"
        case user
    }
}
