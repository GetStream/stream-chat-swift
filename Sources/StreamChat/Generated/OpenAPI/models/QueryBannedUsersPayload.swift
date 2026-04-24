//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class QueryBannedUsersPayload: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Whether to exclude expired bans or not
    var excludeExpiredBans: Bool?
    /// Filter conditions to apply to the query
    var filterConditions: [String: RawJSON]
    /// Number of records to return
    var limit: Int?
    /// Number of records to offset
    var offset: Int?
    /// [RawJSON] of sort parameters
    var sort: [SortParamRequestModel]?

    init(excludeExpiredBans: Bool? = nil, filterConditions: [String: RawJSON], limit: Int? = nil, offset: Int? = nil, sort: [SortParamRequestModel]? = nil) {
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

    static func == (lhs: QueryBannedUsersPayload, rhs: QueryBannedUsersPayload) -> Bool {
        lhs.excludeExpiredBans == rhs.excludeExpiredBans &&
            lhs.filterConditions == rhs.filterConditions &&
            lhs.limit == rhs.limit &&
            lhs.offset == rhs.offset &&
            lhs.sort == rhs.sort
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(excludeExpiredBans)
        hasher.combine(filterConditions)
        hasher.combine(limit)
        hasher.combine(offset)
        hasher.combine(sort)
    }
}
