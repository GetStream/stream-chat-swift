//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class QueryMembersPayload: Sendable, Encodable, JSONEncodable {
    /// Filter conditions to apply to the query
    let filterConditions: (any Encodable & Sendable)?
    let id: String?
    let limit: Int?
    let members: [ChannelMemberRequest]?
    let offset: Int?
    /// Array of sort parameters
    let sort: [SortParamRequest]?
    let type: String

    init(
        filterConditions: (any Encodable & Sendable)? = nil,
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

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let filterConditions {
            try container.encode(filterConditions, forKey: .filterConditions)
        }
        try container.encodeIfPresent(id, forKey: .id)
        try container.encodeIfPresent(limit, forKey: .limit)
        try container.encodeIfPresent(members, forKey: .members)
        try container.encodeIfPresent(offset, forKey: .offset)
        try container.encodeIfPresent(sort, forKey: .sort)
        try container.encode(type, forKey: .type)
    }
}
