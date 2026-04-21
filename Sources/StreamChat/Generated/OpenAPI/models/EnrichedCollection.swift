//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class EnrichedCollection: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var createdAt: Date
    var custom: [String: RawJSON]
    var id: String
    var name: String
    var status: String
    var updatedAt: Date
    var userId: String

    init(createdAt: Date, custom: [String: RawJSON], id: String, name: String, status: String, updatedAt: Date, userId: String) {
        self.createdAt = createdAt
        self.custom = custom
        self.id = id
        self.name = name
        self.status = status
        self.updatedAt = updatedAt
        self.userId = userId
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        case custom
        case id
        case name
        case status
        case updatedAt = "updated_at"
        case userId = "user_id"
    }

    static func == (lhs: EnrichedCollection, rhs: EnrichedCollection) -> Bool {
        lhs.createdAt == rhs.createdAt &&
            lhs.custom == rhs.custom &&
            lhs.id == rhs.id &&
            lhs.name == rhs.name &&
            lhs.status == rhs.status &&
            lhs.updatedAt == rhs.updatedAt &&
            lhs.userId == rhs.userId
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(createdAt)
        hasher.combine(custom)
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(status)
        hasher.combine(updatedAt)
        hasher.combine(userId)
    }
}
