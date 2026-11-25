//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class SearchAllRequest: Sendable, Encodable, JSONEncodable {
    /// Which sections to search: any subset of messages, users and channels. Defaults to all three when omitted; must not be empty when provided. EmptyResponse sections always appear in the order messages, users, channels
    let entities: [String]?
    /// Number of results per section, 1-30. Defaults to 10. Applies to every requested section; there is no per-section limit
    let limit: Int?
    /// Opaque pagination cursors from a previous response, keyed by entity. A cursor that fails to decode restarts that section from page 1 with a cursor_rejected warning; the request fails with 400 only when every cursor supplied for a requested entity is invalid. Cursors for entities not in entities are ignored
    let next: [String: String]?
    /// Free-text search phrase, 1-80 characters after trimming whitespace. Required. Matched as a prefix of a user's name or username and of a channel's name, and as full-text against message text
    let query: String?

    init(
        entities: [String]? = nil,
        limit: Int? = nil,
        next: [String: String]? = nil,
        query: String? = nil
    ) {
        self.entities = entities
        self.limit = limit
        self.next = next
        self.query = query
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(entities, forKey: .entities)
        try container.encodeIfPresent(limit, forKey: .limit)
        try container.encodeIfPresent(next, forKey: .next)
        try container.encodeIfPresent(query, forKey: .query)
    }
}
