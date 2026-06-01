//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UpsertActionConfigItem: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var action: String
    var custom: [String: RawJSON]?
    var description: String?
    var entityType: String
    var icon: String?
    var id: String?
    var order: Int
    var queueType: String?

    init(action: String, custom: [String: RawJSON]? = nil, description: String? = nil, entityType: String, icon: String? = nil, id: String? = nil, order: Int, queueType: String? = nil) {
        self.action = action
        self.custom = custom
        self.description = description
        self.entityType = entityType
        self.icon = icon
        self.id = id
        self.order = order
        self.queueType = queueType
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case action
        case custom
        case description
        case entityType = "entity_type"
        case icon
        case id
        case order
        case queueType = "queue_type"
    }

    static func == (lhs: UpsertActionConfigItem, rhs: UpsertActionConfigItem) -> Bool {
        lhs.action == rhs.action &&
            lhs.custom == rhs.custom &&
            lhs.description == rhs.description &&
            lhs.entityType == rhs.entityType &&
            lhs.icon == rhs.icon &&
            lhs.id == rhs.id &&
            lhs.order == rhs.order &&
            lhs.queueType == rhs.queueType
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(action)
        hasher.combine(custom)
        hasher.combine(description)
        hasher.combine(entityType)
        hasher.combine(icon)
        hasher.combine(id)
        hasher.combine(order)
        hasher.combine(queueType)
    }
}
