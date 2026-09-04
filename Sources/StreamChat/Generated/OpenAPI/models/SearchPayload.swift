//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class SearchPayload: Sendable, Encodable, JSONEncodable {
    /// Channel filter conditions
    let filterConditions: any Encodable & Sendable
    /// Number of messages to return
    let limit: Int?
    /// Message filter conditions
    let messageFilterConditions: (any Encodable & Sendable)?
    /// Pagination parameter. Cannot be used with non-zero offset.
    let next: String?
    /// Pagination offset. Cannot be used with sort or next.
    let offset: Int?
    /// Search phrase
    let query: String?
    /// Sort parameters. Cannot be used with non-zero offset
    let sort: [SortParamRequest]?

    init(
        filterConditions: any Encodable & Sendable,
        limit: Int? = nil,
        messageFilterConditions: (any Encodable & Sendable)? = nil,
        next: String? = nil,
        offset: Int? = nil,
        query: String? = nil,
        sort: [SortParamRequest]? = nil
    ) {
        self.filterConditions = filterConditions
        self.limit = limit
        self.messageFilterConditions = messageFilterConditions
        self.next = next
        self.offset = offset
        self.query = query
        self.sort = sort
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case filterConditions = "filter_conditions"
        case limit
        case messageFilterConditions = "message_filter_conditions"
        case next
        case offset
        case query
        case sort
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(filterConditions, forKey: .filterConditions)
        try container.encodeIfPresent(limit, forKey: .limit)
        if let messageFilterConditions {
            try container.encode(messageFilterConditions, forKey: .messageFilterConditions)
        }
        try container.encodeIfPresent(next, forKey: .next)
        try container.encodeIfPresent(offset, forKey: .offset)
        try container.encodeIfPresent(query, forKey: .query)
        try container.encodeIfPresent(sort, forKey: .sort)
    }
}
