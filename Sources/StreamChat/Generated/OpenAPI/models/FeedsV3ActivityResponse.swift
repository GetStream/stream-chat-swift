//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class FeedsV3ActivityResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var attachments: [Attachment]
    var bookmarkCount: Int
    var collections: [String: EnrichedCollection]
    var commentCount: Int
    var comments: [FeedsV3CommentResponse]
    var createdAt: Date
    var custom: [String: RawJSON]
    var deletedAt: Date?
    var editedAt: Date?
    var expiresAt: Date?
    var feeds: [String]
    var filterTags: [String]
    var hidden: Bool
    var id: String
    var interestTags: [String]
    var latestReactions: [RawJSON]
    var mentionedUsers: [UserResponse]
    var metrics: [String: Int]?
    var moderation: ModerationV2Response?
    var moderationAction: String?
    var ownBookmarks: [RawJSON]
    var ownReactions: [RawJSON]
    var popularity: Int
    var preview: Bool
    var reactionCount: Int
    var reactionGroups: [String: FeedsReactionGroup]
    var restrictReplies: String
    var score: Float
    var searchData: [String: RawJSON]
    var shareCount: Int
    var text: String?
    var type: String
    var updatedAt: Date
    var user: UserResponse
    var visibility: String
    var visibilityTag: String?

    init(attachments: [Attachment], bookmarkCount: Int, collections: [String: EnrichedCollection], commentCount: Int, comments: [FeedsV3CommentResponse], createdAt: Date, custom: [String: RawJSON], deletedAt: Date? = nil, editedAt: Date? = nil, expiresAt: Date? = nil, feeds: [String], filterTags: [String], hidden: Bool, id: String, interestTags: [String], latestReactions: [RawJSON], mentionedUsers: [UserResponse], metrics: [String: Int]? = nil, moderation: ModerationV2Response? = nil, moderationAction: String? = nil, ownBookmarks: [RawJSON], ownReactions: [RawJSON], popularity: Int, preview: Bool, reactionCount: Int, reactionGroups: [String: FeedsReactionGroup], restrictReplies: String, score: Float, searchData: [String: RawJSON], shareCount: Int, text: String? = nil, type: String, updatedAt: Date, user: UserResponse, visibility: String, visibilityTag: String? = nil) {
        self.attachments = attachments
        self.bookmarkCount = bookmarkCount
        self.collections = collections
        self.commentCount = commentCount
        self.comments = comments
        self.createdAt = createdAt
        self.custom = custom
        self.deletedAt = deletedAt
        self.editedAt = editedAt
        self.expiresAt = expiresAt
        self.feeds = feeds
        self.filterTags = filterTags
        self.hidden = hidden
        self.id = id
        self.interestTags = interestTags
        self.latestReactions = latestReactions
        self.mentionedUsers = mentionedUsers
        self.metrics = metrics
        self.moderation = moderation
        self.moderationAction = moderationAction
        self.ownBookmarks = ownBookmarks
        self.ownReactions = ownReactions
        self.popularity = popularity
        self.preview = preview
        self.reactionCount = reactionCount
        self.reactionGroups = reactionGroups
        self.restrictReplies = restrictReplies
        self.score = score
        self.searchData = searchData
        self.shareCount = shareCount
        self.text = text
        self.type = type
        self.updatedAt = updatedAt
        self.user = user
        self.visibility = visibility
        self.visibilityTag = visibilityTag
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case attachments
        case bookmarkCount = "bookmark_count"
        case collections
        case commentCount = "comment_count"
        case comments
        case createdAt = "created_at"
        case custom
        case deletedAt = "deleted_at"
        case editedAt = "edited_at"
        case expiresAt = "expires_at"
        case feeds
        case filterTags = "filter_tags"
        case hidden
        case id
        case interestTags = "interest_tags"
        case latestReactions = "latest_reactions"
        case mentionedUsers = "mentioned_users"
        case metrics
        case moderation
        case moderationAction = "moderation_action"
        case ownBookmarks = "own_bookmarks"
        case ownReactions = "own_reactions"
        case popularity
        case preview
        case reactionCount = "reaction_count"
        case reactionGroups = "reaction_groups"
        case restrictReplies = "restrict_replies"
        case score
        case searchData = "search_data"
        case shareCount = "share_count"
        case text
        case type
        case updatedAt = "updated_at"
        case user
        case visibility
        case visibilityTag = "visibility_tag"
    }

    static func == (lhs: FeedsV3ActivityResponse, rhs: FeedsV3ActivityResponse) -> Bool {
        lhs.attachments == rhs.attachments &&
            lhs.bookmarkCount == rhs.bookmarkCount &&
            lhs.collections == rhs.collections &&
            lhs.commentCount == rhs.commentCount &&
            lhs.comments == rhs.comments &&
            lhs.createdAt == rhs.createdAt &&
            lhs.custom == rhs.custom &&
            lhs.deletedAt == rhs.deletedAt &&
            lhs.editedAt == rhs.editedAt &&
            lhs.expiresAt == rhs.expiresAt &&
            lhs.feeds == rhs.feeds &&
            lhs.filterTags == rhs.filterTags &&
            lhs.hidden == rhs.hidden &&
            lhs.id == rhs.id &&
            lhs.interestTags == rhs.interestTags &&
            lhs.latestReactions == rhs.latestReactions &&
            lhs.mentionedUsers == rhs.mentionedUsers &&
            lhs.metrics == rhs.metrics &&
            lhs.moderation == rhs.moderation &&
            lhs.moderationAction == rhs.moderationAction &&
            lhs.ownBookmarks == rhs.ownBookmarks &&
            lhs.ownReactions == rhs.ownReactions &&
            lhs.popularity == rhs.popularity &&
            lhs.preview == rhs.preview &&
            lhs.reactionCount == rhs.reactionCount &&
            lhs.reactionGroups == rhs.reactionGroups &&
            lhs.restrictReplies == rhs.restrictReplies &&
            lhs.score == rhs.score &&
            lhs.searchData == rhs.searchData &&
            lhs.shareCount == rhs.shareCount &&
            lhs.text == rhs.text &&
            lhs.type == rhs.type &&
            lhs.updatedAt == rhs.updatedAt &&
            lhs.user == rhs.user &&
            lhs.visibility == rhs.visibility &&
            lhs.visibilityTag == rhs.visibilityTag
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(attachments)
        hasher.combine(bookmarkCount)
        hasher.combine(collections)
        hasher.combine(commentCount)
        hasher.combine(comments)
        hasher.combine(createdAt)
        hasher.combine(custom)
        hasher.combine(deletedAt)
        hasher.combine(editedAt)
        hasher.combine(expiresAt)
        hasher.combine(feeds)
        hasher.combine(filterTags)
        hasher.combine(hidden)
        hasher.combine(id)
        hasher.combine(interestTags)
        hasher.combine(latestReactions)
        hasher.combine(mentionedUsers)
        hasher.combine(metrics)
        hasher.combine(moderation)
        hasher.combine(moderationAction)
        hasher.combine(ownBookmarks)
        hasher.combine(ownReactions)
        hasher.combine(popularity)
        hasher.combine(preview)
        hasher.combine(reactionCount)
        hasher.combine(reactionGroups)
        hasher.combine(restrictReplies)
        hasher.combine(score)
        hasher.combine(searchData)
        hasher.combine(shareCount)
        hasher.combine(text)
        hasher.combine(type)
        hasher.combine(updatedAt)
        hasher.combine(user)
        hasher.combine(visibility)
        hasher.combine(visibilityTag)
    }
}
