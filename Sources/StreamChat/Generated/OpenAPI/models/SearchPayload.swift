//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class SearchPayload: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Channel filter conditions
    var filterConditions: [String: RawJSON]
    var forceDefaultSearch: Bool?
    var forceSqlV2Backend: Bool?
    /// Number of messages to return
    var limit: Int?
    /// Message filter conditions
    var messageFilterConditions: [String: RawJSON]?
    var messageOptions: MessageOptions?
    /// Pagination parameter. Cannot be used with non-zero offset.
    var next: String?
    /// Pagination offset. Cannot be used with sort or next.
    var offset: Int?
    /// Search phrase
    var query: String?
    /// Sort parameters. Cannot be used with non-zero offset
    var sort: [SortParamRequestOpenAPI]?

    init(filterConditions: [String: RawJSON], forceDefaultSearch: Bool? = nil, forceSqlV2Backend: Bool? = nil, limit: Int? = nil, messageFilterConditions: [String: RawJSON]? = nil, messageOptions: MessageOptions? = nil, next: String? = nil, offset: Int? = nil, query: String? = nil, sort: [SortParamRequestOpenAPI]? = nil) {
        self.filterConditions = filterConditions
        self.forceDefaultSearch = forceDefaultSearch
        self.forceSqlV2Backend = forceSqlV2Backend
        self.limit = limit
        self.messageFilterConditions = messageFilterConditions
        self.messageOptions = messageOptions
        self.next = next
        self.offset = offset
        self.query = query
        self.sort = sort
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case filterConditions = "filter_conditions"
        case forceDefaultSearch = "force_default_search"
        case forceSqlV2Backend = "force_sql_v2_backend"
        case limit
        case messageFilterConditions = "message_filter_conditions"
        case messageOptions = "message_options"
        case next
        case offset
        case query
        case sort
    }

    static func == (lhs: SearchPayload, rhs: SearchPayload) -> Bool {
        lhs.filterConditions == rhs.filterConditions &&
            lhs.forceDefaultSearch == rhs.forceDefaultSearch &&
            lhs.forceSqlV2Backend == rhs.forceSqlV2Backend &&
            lhs.limit == rhs.limit &&
            lhs.messageFilterConditions == rhs.messageFilterConditions &&
            lhs.messageOptions == rhs.messageOptions &&
            lhs.next == rhs.next &&
            lhs.offset == rhs.offset &&
            lhs.query == rhs.query &&
            lhs.sort == rhs.sort
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(filterConditions)
        hasher.combine(forceDefaultSearch)
        hasher.combine(forceSqlV2Backend)
        hasher.combine(limit)
        hasher.combine(messageFilterConditions)
        hasher.combine(messageOptions)
        hasher.combine(next)
        hasher.combine(offset)
        hasher.combine(query)
        hasher.combine(sort)
    }
}
