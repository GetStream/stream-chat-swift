//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class MutedUserPayload: Sendable, Decodable {
    let createdAt: Date
    let expires: Date?
    /// User response object
    let target: UserPayload?
    let updatedAt: Date

    init(createdAt: Date, expires: Date? = nil, target: UserPayload? = nil, updatedAt: Date) {
        self.createdAt = createdAt
        self.expires = expires
        self.target = target
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.expires = try container.decodeIfPresent(Date.self, forKey: .expires)
        self.target = try container.decodeIfPresent(UserPayload.self, forKey: .target)
        self.updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
}
