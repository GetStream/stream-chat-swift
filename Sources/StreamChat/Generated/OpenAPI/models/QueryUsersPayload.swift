//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class QueryUsersPayload: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Filter conditions to apply to the query
    var filterConditions: [String: RawJSON]
    var includeDeactivatedUsers: Bool?
    var limit: Int?
    var offset: Int?
    var presence: Bool?
    /// [RawJSON] of sort parameters
    var sort: [SortParamRequestOpenAPI]?

    init(filterConditions: [String: RawJSON], includeDeactivatedUsers: Bool? = nil, limit: Int? = nil, offset: Int? = nil, presence: Bool? = nil, sort: [SortParamRequestOpenAPI]? = nil) {
        self.filterConditions = filterConditions
        self.includeDeactivatedUsers = includeDeactivatedUsers
        self.limit = limit
        self.offset = offset
        self.presence = presence
        self.sort = sort
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case filterConditions = "filter_conditions"
        case includeDeactivatedUsers = "include_deactivated_users"
        case limit
        case offset
        case presence
        case sort
    }

    static func == (lhs: QueryUsersPayload, rhs: QueryUsersPayload) -> Bool {
        lhs.filterConditions == rhs.filterConditions &&
            lhs.includeDeactivatedUsers == rhs.includeDeactivatedUsers &&
            lhs.limit == rhs.limit &&
            lhs.offset == rhs.offset &&
            lhs.presence == rhs.presence &&
            lhs.sort == rhs.sort
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(filterConditions)
        hasher.combine(includeDeactivatedUsers)
        hasher.combine(limit)
        hasher.combine(offset)
        hasher.combine(presence)
        hasher.combine(sort)
    }
}
