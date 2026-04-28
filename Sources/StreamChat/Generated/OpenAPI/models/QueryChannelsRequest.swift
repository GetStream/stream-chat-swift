//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class QueryChannelsRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Filter conditions to apply to the query
    var filterConditions: [String: RawJSON]?
    /// Values to interpolate into the predefined filter template
    var filterValues: [String: RawJSON]?
    /// Number of channels to limit
    var limit: Int?
    /// Number of members to limit
    var memberLimit: Int?
    /// Number of messages to limit
    var messageLimit: Int?
    /// Channel pagination offset
    var offset: Int?
    /// ID of a predefined filter to use instead of filter_conditions
    var predefinedFilter: String?
    var presence: Bool?
    /// List of sort parameters
    var sort: [SortParamRequestOpenAPI]?
    var sortValues: [String: RawJSON]?
    /// Whether to update channel state or not
    var state: Bool?
    /// Whether to start watching found channels or not
    var watch: Bool?

    init(filterConditions: [String: RawJSON]? = nil, filterValues: [String: RawJSON]? = nil, limit: Int? = nil, memberLimit: Int? = nil, messageLimit: Int? = nil, offset: Int? = nil, predefinedFilter: String? = nil, presence: Bool? = nil, sort: [SortParamRequestOpenAPI]? = nil, sortValues: [String: RawJSON]? = nil, state: Bool? = nil, watch: Bool? = nil) {
        self.filterConditions = filterConditions
        self.filterValues = filterValues
        self.limit = limit
        self.memberLimit = memberLimit
        self.messageLimit = messageLimit
        self.offset = offset
        self.predefinedFilter = predefinedFilter
        self.presence = presence
        self.sort = sort
        self.sortValues = sortValues
        self.state = state
        self.watch = watch
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case filterConditions = "filter_conditions"
        case filterValues = "filter_values"
        case limit
        case memberLimit = "member_limit"
        case messageLimit = "message_limit"
        case offset
        case predefinedFilter = "predefined_filter"
        case presence
        case sort
        case sortValues = "sort_values"
        case state
        case watch
    }

    static func == (lhs: QueryChannelsRequest, rhs: QueryChannelsRequest) -> Bool {
        lhs.filterConditions == rhs.filterConditions &&
            lhs.filterValues == rhs.filterValues &&
            lhs.limit == rhs.limit &&
            lhs.memberLimit == rhs.memberLimit &&
            lhs.messageLimit == rhs.messageLimit &&
            lhs.offset == rhs.offset &&
            lhs.predefinedFilter == rhs.predefinedFilter &&
            lhs.presence == rhs.presence &&
            lhs.sort == rhs.sort &&
            lhs.sortValues == rhs.sortValues &&
            lhs.state == rhs.state &&
            lhs.watch == rhs.watch
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(filterConditions)
        hasher.combine(filterValues)
        hasher.combine(limit)
        hasher.combine(memberLimit)
        hasher.combine(messageLimit)
        hasher.combine(offset)
        hasher.combine(predefinedFilter)
        hasher.combine(presence)
        hasher.combine(sort)
        hasher.combine(sortValues)
        hasher.combine(state)
        hasher.combine(watch)
    }
}
