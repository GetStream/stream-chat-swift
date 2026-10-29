//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class HealthCheckEventDTO: Sendable, Event, Decodable {
    let connectionId: String
    let createdAt: Date
    let me: OwnUserResponse?
    let type: String

    init(
        connectionId: String,
        createdAt: Date,
        me: OwnUserResponse? = nil,
        type: String = "health.check"
    ) {
        self.connectionId = connectionId
        self.createdAt = createdAt
        self.me = me
        self.type = type
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.connectionId = try container.decode(String.self, forKey: .connectionId)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.me = try container.decodeIfPresent(OwnUserResponse.self, forKey: .me)
        self.type = try container.decode(String.self, forKey: .type)
    }
}
