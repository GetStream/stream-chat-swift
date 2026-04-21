//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class EnrichedReaction: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var activityId: String
    var childrenCounts: [String: Int]?
    var data: [String: RawJSON]?
    var id: String?
    var kind: String
    var latestChildren: [String: [EnrichedReaction]]?
    var ownChildren: [String: [EnrichedReaction]]?
    var parent: String?
    var targetFeeds: [String]?
    var user: StreamData?
    var userId: String

    init(activityId: String, childrenCounts: [String: Int]? = nil, data: [String: RawJSON]? = nil, id: String? = nil, kind: String, latestChildren: [String: [EnrichedReaction]]? = nil, ownChildren: [String: [EnrichedReaction]]? = nil, parent: String? = nil, targetFeeds: [String]? = nil, user: StreamData? = nil, userId: String) {
        self.activityId = activityId
        self.childrenCounts = childrenCounts
        self.data = data
        self.id = id
        self.kind = kind
        self.latestChildren = latestChildren
        self.ownChildren = ownChildren
        self.parent = parent
        self.targetFeeds = targetFeeds
        self.user = user
        self.userId = userId
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case activityId = "activity_id"
        case childrenCounts = "children_counts"
        case data
        case id
        case kind
        case latestChildren = "latest_children"
        case ownChildren = "own_children"
        case parent
        case targetFeeds = "target_feeds"
        case user
        case userId = "user_id"
    }

    static func == (lhs: EnrichedReaction, rhs: EnrichedReaction) -> Bool {
        lhs.activityId == rhs.activityId &&
            lhs.childrenCounts == rhs.childrenCounts &&
            lhs.data == rhs.data &&
            lhs.id == rhs.id &&
            lhs.kind == rhs.kind &&
            lhs.latestChildren == rhs.latestChildren &&
            lhs.ownChildren == rhs.ownChildren &&
            lhs.parent == rhs.parent &&
            lhs.targetFeeds == rhs.targetFeeds &&
            lhs.user == rhs.user &&
            lhs.userId == rhs.userId
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(activityId)
        hasher.combine(childrenCounts)
        hasher.combine(data)
        hasher.combine(id)
        hasher.combine(kind)
        hasher.combine(latestChildren)
        hasher.combine(ownChildren)
        hasher.combine(parent)
        hasher.combine(targetFeeds)
        hasher.combine(user)
        hasher.combine(userId)
    }
}
