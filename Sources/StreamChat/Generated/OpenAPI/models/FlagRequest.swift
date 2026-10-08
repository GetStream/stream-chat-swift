//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class FlagRequest: Sendable, Encodable, JSONEncodable {
    /// Additional metadata about the flag
    let custom: [String: RawJSON]?
    /// Unique identifier of the entity being flagged
    let entityId: String
    /// Type of entity being flagged (e.g., message, user)
    let entityType: String
    /// Optional explanation for why the content is being flagged
    let reason: String?

    init(
        custom: [String: RawJSON]? = nil,
        entityId: String,
        entityType: String,
        reason: String? = nil
    ) {
        self.custom = custom
        self.entityId = entityId
        self.entityType = entityType
        self.reason = reason
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(custom, forKey: .custom)
        try container.encode(entityId, forKey: .entityId)
        try container.encode(entityType, forKey: .entityType)
        try container.encodeIfPresent(reason, forKey: .reason)
    }
}
