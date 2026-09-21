//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class QueryBannedUsersPayload: Sendable, Encodable, JSONEncodable {
    /// Whether to exclude expired bans or not
    let excludeExpiredBans: Bool?
    /// Filter conditions to apply to the query
    let filterConditions: any Encodable & Sendable
    /// Number of records to return
    let limit: Int?
    /// Number of records to offset
    let offset: Int?
    /// Array of sort parameters
    let sort: [SortParamRequest]?

    init(
        excludeExpiredBans: Bool? = nil,
        filterConditions: any Encodable & Sendable,
        limit: Int? = nil,
        offset: Int? = nil,
        sort: [SortParamRequest]? = nil
    ) {
        self.excludeExpiredBans = excludeExpiredBans
        self.filterConditions = filterConditions
        self.limit = limit
        self.offset = offset
        self.sort = sort
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case excludeExpiredBans = "exclude_expired_bans"
        case filterConditions = "filter_conditions"
        case limit
        case offset
        case sort
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(
            excludeExpiredBans,
            forKey: .excludeExpiredBans
        )
        try container.encode(
            filterConditions,
            forKey: .filterConditions
        )
        try container.encodeIfPresent(
            limit,
            forKey: .limit
        )
        try container.encodeIfPresent(
            offset,
            forKey: .offset
        )
        try container.encodeIfPresent(
            sort,
            forKey: .sort
        )
    }
}
