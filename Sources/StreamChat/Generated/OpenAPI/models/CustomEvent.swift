//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class CustomEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    var createdAt: Date
    var custom: [String: RawJSON]
    var receivedAt: Date?
    var type: String = "*"

    init(createdAt: Date, custom: [String: RawJSON], receivedAt: Date? = nil) {
        self.createdAt = createdAt
        self.custom = custom
        self.receivedAt = receivedAt
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        case custom
        case receivedAt = "received_at"
        case type
    }

    static func == (lhs: CustomEvent, rhs: CustomEvent) -> Bool {
        lhs.createdAt == rhs.createdAt &&
            lhs.custom == rhs.custom &&
            lhs.receivedAt == rhs.receivedAt &&
            lhs.type == rhs.type
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(createdAt)
        hasher.combine(custom)
        hasher.combine(receivedAt)
        hasher.combine(type)
    }
}
