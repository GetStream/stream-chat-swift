//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class HealthCheckEventDTO: Sendable, Event, Decodable {
    let cid: String?
    let connectionId: String
    let createdAt: Date
    let custom: [String: RawJSON]
    let me: OwnUserResponse?
    let receivedAt: Date?
    let type: String

    init(
        cid: String? = nil,
        connectionId: String,
        createdAt: Date,
        custom: [String: RawJSON],
        me: OwnUserResponse? = nil,
        receivedAt: Date? = nil,
        type: String = "health.check"
    ) {
        self.cid = cid
        self.connectionId = connectionId
        self.createdAt = createdAt
        self.custom = custom
        self.me = me
        self.receivedAt = receivedAt
        self.type = type
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case cid
        case connectionId = "connection_id"
        case createdAt = "created_at"
        case custom
        case me
        case receivedAt = "received_at"
        case type
    }
}
