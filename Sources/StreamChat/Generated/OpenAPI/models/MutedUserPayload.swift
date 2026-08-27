//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

final class MutedUserPayload: Sendable, Decodable {
    let createdAt: Date
    let expires: Date?
    /// User response object
    let target: UserPayload?
    let updatedAt: Date
    /// User response object
    let user: UserPayload?

    init(
        createdAt: Date,
        expires: Date? = nil,
        target: UserPayload? = nil,
        updatedAt: Date,
        user: UserPayload? = nil
    ) {
        self.createdAt = createdAt
        self.expires = expires
        self.target = target
        self.updatedAt = updatedAt
        self.user = user
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        case expires
        case target
        case updatedAt = "updated_at"
        case user
    }
}
