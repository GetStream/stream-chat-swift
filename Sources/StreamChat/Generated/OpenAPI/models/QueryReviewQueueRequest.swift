//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class QueryReviewQueueRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Filter conditions for review queue items
    var filter: [String: RawJSON]?
    var limit: Int?
    /// Number of items to lock (1-25)
    var lockCount: Int?
    /// Duration for which items should be locked
    var lockDuration: Int?
    /// Whether to lock items for review (true), unlock items (false), or just fetch (nil)
    var lockItems: Bool?
    var next: String?
    var prev: String?
    /// Sorting parameters for the results
    var sort: [SortParamRequestModel]?
    /// Whether to return only statistics
    var statsOnly: Bool?

    init(filter: [String: RawJSON]? = nil, limit: Int? = nil, lockCount: Int? = nil, lockDuration: Int? = nil, lockItems: Bool? = nil, next: String? = nil, prev: String? = nil, sort: [SortParamRequestModel]? = nil, statsOnly: Bool? = nil) {
        self.filter = filter
        self.limit = limit
        self.lockCount = lockCount
        self.lockDuration = lockDuration
        self.lockItems = lockItems
        self.next = next
        self.prev = prev
        self.sort = sort
        self.statsOnly = statsOnly
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case filter
        case limit
        case lockCount = "lock_count"
        case lockDuration = "lock_duration"
        case lockItems = "lock_items"
        case next
        case prev
        case sort
        case statsOnly = "stats_only"
    }

    static func == (lhs: QueryReviewQueueRequest, rhs: QueryReviewQueueRequest) -> Bool {
        lhs.filter == rhs.filter &&
            lhs.limit == rhs.limit &&
            lhs.lockCount == rhs.lockCount &&
            lhs.lockDuration == rhs.lockDuration &&
            lhs.lockItems == rhs.lockItems &&
            lhs.next == rhs.next &&
            lhs.prev == rhs.prev &&
            lhs.sort == rhs.sort &&
            lhs.statsOnly == rhs.statsOnly
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(filter)
        hasher.combine(limit)
        hasher.combine(lockCount)
        hasher.combine(lockDuration)
        hasher.combine(lockItems)
        hasher.combine(next)
        hasher.combine(prev)
        hasher.combine(sort)
        hasher.combine(statsOnly)
    }
}
