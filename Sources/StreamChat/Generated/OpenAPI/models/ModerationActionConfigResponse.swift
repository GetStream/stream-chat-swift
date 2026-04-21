//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ModerationActionConfigResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// The action to take
    var action: String
    /// Custom data for the action
    var custom: [String: RawJSON]?
    /// Description of what this action does
    var description: String
    /// Type of entity this action applies to
    var entityType: String
    /// Icon for the dashboard
    var icon: String
    /// Display order (lower numbers shown first)
    var order: Int
    /// Queue type this action config belongs to
    var queueType: String?

    init(action: String, custom: [String: RawJSON]? = nil, description: String, entityType: String, icon: String, order: Int, queueType: String? = nil) {
        self.action = action
        self.custom = custom
        self.description = description
        self.entityType = entityType
        self.icon = icon
        self.order = order
        self.queueType = queueType
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case action
        case custom
        case description
        case entityType = "entity_type"
        case icon
        case order
        case queueType = "queue_type"
    }

    static func == (lhs: ModerationActionConfigResponse, rhs: ModerationActionConfigResponse) -> Bool {
        lhs.action == rhs.action &&
            lhs.custom == rhs.custom &&
            lhs.description == rhs.description &&
            lhs.entityType == rhs.entityType &&
            lhs.icon == rhs.icon &&
            lhs.order == rhs.order &&
            lhs.queueType == rhs.queueType
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(action)
        hasher.combine(custom)
        hasher.combine(description)
        hasher.combine(entityType)
        hasher.combine(icon)
        hasher.combine(order)
        hasher.combine(queueType)
    }
}
