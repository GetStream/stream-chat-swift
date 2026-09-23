//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UserUpdatedEventDTO: Sendable, Event, Decodable {
    /// Date/time of creation
    let createdAt: Date
    let custom: [String: RawJSON]
    let receivedAt: Date?
    /// The type of event: "user.updated" in this case
    let type: String
    let user: UserPayload

    init(
        createdAt: Date,
        custom: [String: RawJSON],
        receivedAt: Date? = nil,
        type: String = "user.updated",
        user: UserPayload
    ) {
        self.createdAt = createdAt
        self.custom = custom
        self.receivedAt = receivedAt
        self.type = type
        self.user = user
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        case custom
        case receivedAt = "received_at"
        case type
        case user
    }
}
