//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class QueryReviewQueueResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Configuration for moderation actions
    var actionConfig: [String: [ModerationActionConfigResponse]]
    var defaultActionConfig: [String: [ModerationActionConfigResponse]]?
    var duration: String
    var filterConfig: FilterConfigResponse?
    /// List of review queue items
    var items: [ReviewQueueItemResponse]
    var next: String?
    var prev: String?
    /// Statistics about the review queue
    var stats: [String: RawJSON]

    init(actionConfig: [String: [ModerationActionConfigResponse]], defaultActionConfig: [String: [ModerationActionConfigResponse]]? = nil, duration: String, filterConfig: FilterConfigResponse? = nil, items: [ReviewQueueItemResponse], next: String? = nil, prev: String? = nil, stats: [String: RawJSON]) {
        self.actionConfig = actionConfig
        self.defaultActionConfig = defaultActionConfig
        self.duration = duration
        self.filterConfig = filterConfig
        self.items = items
        self.next = next
        self.prev = prev
        self.stats = stats
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case actionConfig = "action_config"
        case defaultActionConfig = "default_action_config"
        case duration
        case filterConfig = "filter_config"
        case items
        case next
        case prev
        case stats
    }

    static func == (lhs: QueryReviewQueueResponse, rhs: QueryReviewQueueResponse) -> Bool {
        lhs.actionConfig == rhs.actionConfig &&
            lhs.defaultActionConfig == rhs.defaultActionConfig &&
            lhs.duration == rhs.duration &&
            lhs.filterConfig == rhs.filterConfig &&
            lhs.items == rhs.items &&
            lhs.next == rhs.next &&
            lhs.prev == rhs.prev &&
            lhs.stats == rhs.stats
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(actionConfig)
        hasher.combine(defaultActionConfig)
        hasher.combine(duration)
        hasher.combine(filterConfig)
        hasher.combine(items)
        hasher.combine(next)
        hasher.combine(prev)
        hasher.combine(stats)
    }
}
