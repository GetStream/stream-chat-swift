//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UpsertActionConfigRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// The action to perform (e.g. ban, delete_message, custom)
    var action: String
    /// Action-specific parameters passed to the action handler
    var custom: [String: RawJSON]?
    /// Human-readable label for the dashboard button
    var description: String?
    /// Type of entity this action applies to (e.g. stream:chat:v1:message)
    var entityType: String
    /// Icon identifier for the dashboard button
    var icon: String?
    /// UUID of an existing action config to update; omit to create a new record
    var id: String?
    /// Display order in the dashboard (0–100, lower numbers shown first)
    var order: Int
    /// Queue this config belongs to; null means the default queue
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

    static func == (lhs: UpsertActionConfigRequest, rhs: UpsertActionConfigRequest) -> Bool {
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
