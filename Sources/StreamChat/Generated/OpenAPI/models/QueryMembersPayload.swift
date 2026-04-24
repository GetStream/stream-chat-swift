//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class QueryMembersPayload: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Filter conditions to apply to the query
    var filterConditions: [String: RawJSON]
    var id: String?
    var limit: Int?
    var members: [ChannelMemberRequest]?
    var offset: Int?
    /// [RawJSON] of sort parameters
    var sort: [SortParamRequestModel]?
    var type: String

    init(filterConditions: [String: RawJSON], id: String? = nil, limit: Int? = nil, members: [ChannelMemberRequest]? = nil, offset: Int? = nil, sort: [SortParamRequestModel]? = nil, type: String) {
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

    static func == (lhs: QueryMembersPayload, rhs: QueryMembersPayload) -> Bool {
        lhs.filterConditions == rhs.filterConditions &&
            lhs.id == rhs.id &&
            lhs.limit == rhs.limit &&
            lhs.members == rhs.members &&
            lhs.offset == rhs.offset &&
            lhs.sort == rhs.sort &&
            lhs.type == rhs.type
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(filterConditions)
        hasher.combine(id)
        hasher.combine(limit)
        hasher.combine(members)
        hasher.combine(offset)
        hasher.combine(sort)
        hasher.combine(type)
    }
}
