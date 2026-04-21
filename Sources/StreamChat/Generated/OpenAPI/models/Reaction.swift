//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class Reaction: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var activityId: String
    var childrenCounts: [String: RawJSON]?
    var createdAt: Date
    var data: [String: RawJSON]?
    var deletedAt: Date?
    var id: String?
    var kind: String
    var latestChildren: [String: [Reaction]]?
    var moderation: [String: RawJSON]?
    var ownChildren: [String: [Reaction]]?
    var parent: String?
    var score: Float?
    var targetFeeds: [String]?
    var targetFeedsExtraData: [String: RawJSON]?
    var updatedAt: Date
    var user: User?
    var userId: String

    init(activityId: String, childrenCounts: [String: RawJSON]? = nil, createdAt: Date, data: [String: RawJSON]? = nil, deletedAt: Date? = nil, id: String? = nil, kind: String, latestChildren: [String: [Reaction]]? = nil, moderation: [String: RawJSON]? = nil, ownChildren: [String: [Reaction]]? = nil, parent: String? = nil, score: Float? = nil, targetFeeds: [String]? = nil, targetFeedsExtraData: [String: RawJSON]? = nil, updatedAt: Date, user: User? = nil, userId: String) {
        self.activityId = activityId
        self.childrenCounts = childrenCounts
        self.createdAt = createdAt
        self.data = data
        self.deletedAt = deletedAt
        self.id = id
        self.kind = kind
        self.latestChildren = latestChildren
        self.moderation = moderation
        self.ownChildren = ownChildren
        self.parent = parent
        self.score = score
        self.targetFeeds = targetFeeds
        self.targetFeedsExtraData = targetFeedsExtraData
        self.updatedAt = updatedAt
        self.user = user
        self.userId = userId
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case activityId = "activity_id"
        case childrenCounts = "children_counts"
        case createdAt = "created_at"
        case data
        case deletedAt = "deleted_at"
        case id
        case kind
        case latestChildren = "latest_children"
        case moderation
        case ownChildren = "own_children"
        case parent
        case score
        case targetFeeds = "target_feeds"
        case targetFeedsExtraData = "target_feeds_extra_data"
        case updatedAt = "updated_at"
        case user
        case userId = "user_id"
    }

    static func == (lhs: Reaction, rhs: Reaction) -> Bool {
        lhs.activityId == rhs.activityId &&
            lhs.childrenCounts == rhs.childrenCounts &&
            lhs.createdAt == rhs.createdAt &&
            lhs.data == rhs.data &&
            lhs.deletedAt == rhs.deletedAt &&
            lhs.id == rhs.id &&
            lhs.kind == rhs.kind &&
            lhs.latestChildren == rhs.latestChildren &&
            lhs.moderation == rhs.moderation &&
            lhs.ownChildren == rhs.ownChildren &&
            lhs.parent == rhs.parent &&
            lhs.score == rhs.score &&
            lhs.targetFeeds == rhs.targetFeeds &&
            lhs.targetFeedsExtraData == rhs.targetFeedsExtraData &&
            lhs.updatedAt == rhs.updatedAt &&
            lhs.user == rhs.user &&
            lhs.userId == rhs.userId
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(activityId)
        hasher.combine(childrenCounts)
        hasher.combine(createdAt)
        hasher.combine(data)
        hasher.combine(deletedAt)
        hasher.combine(id)
        hasher.combine(kind)
        hasher.combine(latestChildren)
        hasher.combine(moderation)
        hasher.combine(ownChildren)
        hasher.combine(parent)
        hasher.combine(score)
        hasher.combine(targetFeeds)
        hasher.combine(targetFeedsExtraData)
        hasher.combine(updatedAt)
        hasher.combine(user)
        hasher.combine(userId)
    }
}
