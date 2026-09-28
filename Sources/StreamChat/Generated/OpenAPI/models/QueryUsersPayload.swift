//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class QueryUsersPayload: Sendable, Encodable, JSONEncodable {
    /// Filter conditions to apply to the query
    let filterConditions: any Encodable & Sendable
    let includeDeactivatedUsers: Bool?
    let limit: Int?
    let offset: Int?
    let presence: Bool?
    /// Array of sort parameters
    let sort: [SortParamRequest]?

    init(
        filterConditions: any Encodable & Sendable,
        includeDeactivatedUsers: Bool? = nil,
        limit: Int? = nil,
        offset: Int? = nil,
        presence: Bool? = nil,
        sort: [SortParamRequest]? = nil
    ) {
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

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(filterConditions, forKey: .filterConditions)
        try container.encodeIfPresent(includeDeactivatedUsers, forKey: .includeDeactivatedUsers)
        try container.encodeIfPresent(limit, forKey: .limit)
        try container.encodeIfPresent(offset, forKey: .offset)
        try container.encodeIfPresent(presence, forKey: .presence)
        try container.encodeIfPresent(sort, forKey: .sort)
    }
}
