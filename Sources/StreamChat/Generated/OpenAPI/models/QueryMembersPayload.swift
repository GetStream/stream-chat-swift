//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class QueryMembersPayload: Sendable, Codable, JSONEncodable {
    /// Filter conditions to apply to the query
    let filterConditions: [String: RawJSON]
    let id: String?
    let limit: Int?
    let members: [ChannelMemberRequest]?
    let offset: Int?
    /// Array of sort parameters
    let sort: [SortParamRequest]?
    let type: String

    init(
        filterConditions: [String: RawJSON],
        id: String? = nil,
        limit: Int? = nil,
        members: [ChannelMemberRequest]? = nil,
        offset: Int? = nil,
        sort: [SortParamRequest]? = nil,
        type: String
    ) {
        self.filterConditions = filterConditions
        self.id = id
        self.limit = limit
        self.members = members
        self.offset = offset
        self.sort = sort
        self.type = type
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case filterConditions = "filter_conditions"
        case id
        case limit
        case members
        case offset
        case sort
        case type
    }
}
