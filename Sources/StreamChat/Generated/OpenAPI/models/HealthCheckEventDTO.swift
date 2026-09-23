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

    enum CodingKeys: String, CodingKey, CaseIterable {
        case connectionId = "connection_id"
        case createdAt = "created_at"
        case me
        case type
    }
}
