//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class QueryMessageFlagsPayload: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Filter conditions to apply to the query
    var filterConditions: [String: RawJSON]?
    var limit: Int?
    var offset: Int?
    /// Whether to include deleted messages in the results
    var showDeletedMessages: Bool?
    /// [RawJSON] of sort parameters
    var sort: [SortParamRequestModel]?

    init(filterConditions: [String: RawJSON]? = nil, limit: Int? = nil, offset: Int? = nil, showDeletedMessages: Bool? = nil, sort: [SortParamRequestModel]? = nil) {
        self.filterConditions = filterConditions
        self.limit = limit
        self.offset = offset
        self.showDeletedMessages = showDeletedMessages
        self.sort = sort
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case filterConditions = "filter_conditions"
        case limit
        case offset
        case showDeletedMessages = "show_deleted_messages"
        case sort
    }

    static func == (lhs: QueryMessageFlagsPayload, rhs: QueryMessageFlagsPayload) -> Bool {
        lhs.filterConditions == rhs.filterConditions &&
            lhs.limit == rhs.limit &&
            lhs.offset == rhs.offset &&
            lhs.showDeletedMessages == rhs.showDeletedMessages &&
            lhs.sort == rhs.sort
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(filterConditions)
        hasher.combine(limit)
        hasher.combine(offset)
        hasher.combine(showDeletedMessages)
        hasher.combine(sort)
    }
}
