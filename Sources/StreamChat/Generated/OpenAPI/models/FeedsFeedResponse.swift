//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class FeedsFeedResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var activityCount: Int
    var createdAt: Date
    var createdBy: UserResponse
    var custom: [String: RawJSON]?
    var deletedAt: Date?
    var description: String
    var feed: String
    var filterTags: [String]?
    var followerCount: Int
    var followingCount: Int
    var groupId: String
    var id: String
    var location: FeedsActivityLocation?
    var memberCount: Int
    var name: String
    var pinCount: Int
    var updatedAt: Date
    var visibility: String?

    init(activityCount: Int, createdAt: Date, createdBy: UserResponse, custom: [String: RawJSON]? = nil, deletedAt: Date? = nil, description: String, feed: String, filterTags: [String]? = nil, followerCount: Int, followingCount: Int, groupId: String, id: String, location: FeedsActivityLocation? = nil, memberCount: Int, name: String, pinCount: Int, updatedAt: Date, visibility: String? = nil) {
        self.activityCount = activityCount
        self.createdAt = createdAt
        self.createdBy = createdBy
        self.custom = custom
        self.deletedAt = deletedAt
        self.description = description
        self.feed = feed
        self.filterTags = filterTags
        self.followerCount = followerCount
        self.followingCount = followingCount
        self.groupId = groupId
        self.id = id
        self.location = location
        self.memberCount = memberCount
        self.name = name
        self.pinCount = pinCount
        self.updatedAt = updatedAt
        self.visibility = visibility
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case activityCount = "activity_count"
        case createdAt = "created_at"
        case createdBy = "created_by"
        case custom
        case deletedAt = "deleted_at"
        case description
        case feed
        case filterTags = "filter_tags"
        case followerCount = "follower_count"
        case followingCount = "following_count"
        case groupId = "group_id"
        case id
        case location
        case memberCount = "member_count"
        case name
        case pinCount = "pin_count"
        case updatedAt = "updated_at"
        case visibility
    }

    static func == (lhs: FeedsFeedResponse, rhs: FeedsFeedResponse) -> Bool {
        lhs.activityCount == rhs.activityCount &&
            lhs.createdAt == rhs.createdAt &&
            lhs.createdBy == rhs.createdBy &&
            lhs.custom == rhs.custom &&
            lhs.deletedAt == rhs.deletedAt &&
            lhs.description == rhs.description &&
            lhs.feed == rhs.feed &&
            lhs.filterTags == rhs.filterTags &&
            lhs.followerCount == rhs.followerCount &&
            lhs.followingCount == rhs.followingCount &&
            lhs.groupId == rhs.groupId &&
            lhs.id == rhs.id &&
            lhs.location == rhs.location &&
            lhs.memberCount == rhs.memberCount &&
            lhs.name == rhs.name &&
            lhs.pinCount == rhs.pinCount &&
            lhs.updatedAt == rhs.updatedAt &&
            lhs.visibility == rhs.visibility
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(activityCount)
        hasher.combine(createdAt)
        hasher.combine(createdBy)
        hasher.combine(custom)
        hasher.combine(deletedAt)
        hasher.combine(description)
        hasher.combine(feed)
        hasher.combine(filterTags)
        hasher.combine(followerCount)
        hasher.combine(followingCount)
        hasher.combine(groupId)
        hasher.combine(id)
        hasher.combine(location)
        hasher.combine(memberCount)
        hasher.combine(name)
        hasher.combine(pinCount)
        hasher.combine(updatedAt)
        hasher.combine(visibility)
    }
}
