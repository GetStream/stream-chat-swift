//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class HealthCheckEventModel: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    var cid: String?
    var connectionId: String
    var createdAt: Date
    var custom: [String: RawJSON]
    var me: OwnUserResponse?
    var receivedAt: Date?
    var type: String = "health.check"

    init(cid: String? = nil, connectionId: String, createdAt: Date, custom: [String: RawJSON], me: OwnUserResponse? = nil, receivedAt: Date? = nil) {
        self.cid = cid
        self.connectionId = connectionId
        self.createdAt = createdAt
        self.custom = custom
        self.me = me
        self.receivedAt = receivedAt
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

    static func == (lhs: HealthCheckEventModel, rhs: HealthCheckEventModel) -> Bool {
        lhs.cid == rhs.cid &&
            lhs.connectionId == rhs.connectionId &&
            lhs.createdAt == rhs.createdAt &&
            lhs.custom == rhs.custom &&
            lhs.me == rhs.me &&
            lhs.receivedAt == rhs.receivedAt &&
            lhs.type == rhs.type
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(cid)
        hasher.combine(connectionId)
        hasher.combine(createdAt)
        hasher.combine(custom)
        hasher.combine(me)
        hasher.combine(receivedAt)
        hasher.combine(type)
    }
}
