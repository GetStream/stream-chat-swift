//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class FeedsV3ActivityResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var attachments: [Attachment]
    var bookmarkCount: Int
    var collections: [String: FeedsEnrichedCollectionResponse]
    var commentCount: Int
    var comments: [FeedsV3CommentResponse]
    var createdAt: Date
    var currentFeed: FeedsFeedResponse?
    var custom: [String: RawJSON]
    var deletedAt: Date?
    var editedAt: Date?
    var expiresAt: Date?
    var feeds: [String]
    var filterTags: [String]
    var friendReactionCount: Int?
    var friendReactions: [FeedsReactionResponse]?
    var hidden: Bool
    var id: String
    var interestTags: [String]
    var isRead: Bool?
    var isSeen: Bool?
    var isWatched: Bool?
    var latestReactions: [FeedsReactionResponse]
    var location: FeedsActivityLocation?
    var mentionedUsers: [UserResponse]
    var metrics: [String: Int]?
    var moderation: ModerationV2Response?
    var moderationAction: String?
    var notificationContext: FeedsNotificationContext?
    var ownBookmarks: [FeedsBookmarkResponse]
    var ownReactions: [FeedsReactionResponse]
    var parent: FeedsV3ActivityResponse?
    var poll: PollResponseData?
    var popularity: Int
    var preview: Bool
    var reactionCount: Int
    var reactionGroups: [String: FeedsReactionGroupResponse]
    var restrictReplies: String
    var score: Float
    var scoreVars: [String: RawJSON]?
    var searchData: [String: RawJSON]
    var selectorSource: String?
    var shareCount: Int
    var text: String?
    var type: String
    var updatedAt: Date
    var user: UserResponse
    var visibility: String
    var visibilityTag: String?

    init(attachments: [Attachment], bookmarkCount: Int, collections: [String: FeedsEnrichedCollectionResponse], commentCount: Int, comments: [FeedsV3CommentResponse], createdAt: Date, currentFeed: FeedsFeedResponse? = nil, custom: [String: RawJSON], deletedAt: Date? = nil, editedAt: Date? = nil, expiresAt: Date? = nil, feeds: [String], filterTags: [String], friendReactionCount: Int? = nil, friendReactions: [FeedsReactionResponse]? = nil, hidden: Bool, id: String, interestTags: [String], isRead: Bool? = nil, isSeen: Bool? = nil, isWatched: Bool? = nil, latestReactions: [FeedsReactionResponse], location: FeedsActivityLocation? = nil, mentionedUsers: [UserResponse], metrics: [String: Int]? = nil, moderation: ModerationV2Response? = nil, moderationAction: String? = nil, notificationContext: FeedsNotificationContext? = nil, ownBookmarks: [FeedsBookmarkResponse], ownReactions: [FeedsReactionResponse], parent: FeedsV3ActivityResponse? = nil, poll: PollResponseData? = nil, popularity: Int, preview: Bool, reactionCount: Int, reactionGroups: [String: FeedsReactionGroupResponse], restrictReplies: String, score: Float, scoreVars: [String: RawJSON]? = nil, searchData: [String: RawJSON], selectorSource: String? = nil, shareCount: Int, text: String? = nil, type: String, updatedAt: Date, user: UserResponse, visibility: String, visibilityTag: String? = nil) {
        self.attachments = attachments
        self.bookmarkCount = bookmarkCount
        self.collections = collections
        self.commentCount = commentCount
        self.comments = comments
        self.createdAt = createdAt
        self.currentFeed = currentFeed
        self.custom = custom
        self.deletedAt = deletedAt
        self.editedAt = editedAt
        self.expiresAt = expiresAt
        self.feeds = feeds
        self.filterTags = filterTags
        self.friendReactionCount = friendReactionCount
        self.friendReactions = friendReactions
        self.hidden = hidden
        self.id = id
        self.interestTags = interestTags
        self.isRead = isRead
        self.isSeen = isSeen
        self.isWatched = isWatched
        self.latestReactions = latestReactions
        self.location = location
        self.mentionedUsers = mentionedUsers
        self.metrics = metrics
        self.moderation = moderation
        self.moderationAction = moderationAction
        self.notificationContext = notificationContext
        self.ownBookmarks = ownBookmarks
        self.ownReactions = ownReactions
        self.parent = parent
        self.poll = poll
        self.popularity = popularity
        self.preview = preview
        self.reactionCount = reactionCount
        self.reactionGroups = reactionGroups
        self.restrictReplies = restrictReplies
        self.score = score
        self.scoreVars = scoreVars
        self.searchData = searchData
        self.selectorSource = selectorSource
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
        case currentFeed = "current_feed"
        case custom
        case deletedAt = "deleted_at"
        case editedAt = "edited_at"
        case expiresAt = "expires_at"
        case feeds
        case filterTags = "filter_tags"
        case friendReactionCount = "friend_reaction_count"
        case friendReactions = "friend_reactions"
        case hidden
        case id
        case interestTags = "interest_tags"
        case isRead = "is_read"
        case isSeen = "is_seen"
        case isWatched = "is_watched"
        case latestReactions = "latest_reactions"
        case location
        case mentionedUsers = "mentioned_users"
        case metrics
        case moderation
        case moderationAction = "moderation_action"
        case notificationContext = "notification_context"
        case ownBookmarks = "own_bookmarks"
        case ownReactions = "own_reactions"
        case parent
        case poll
        case popularity
        case preview
        case reactionCount = "reaction_count"
        case reactionGroups = "reaction_groups"
        case restrictReplies = "restrict_replies"
        case score
        case scoreVars = "score_vars"
        case searchData = "search_data"
        case selectorSource = "selector_source"
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
            lhs.currentFeed == rhs.currentFeed &&
            lhs.custom == rhs.custom &&
            lhs.deletedAt == rhs.deletedAt &&
            lhs.editedAt == rhs.editedAt &&
            lhs.expiresAt == rhs.expiresAt &&
            lhs.feeds == rhs.feeds &&
            lhs.filterTags == rhs.filterTags &&
            lhs.friendReactionCount == rhs.friendReactionCount &&
            lhs.friendReactions == rhs.friendReactions &&
            lhs.hidden == rhs.hidden &&
            lhs.id == rhs.id &&
            lhs.interestTags == rhs.interestTags &&
            lhs.isRead == rhs.isRead &&
            lhs.isSeen == rhs.isSeen &&
            lhs.isWatched == rhs.isWatched &&
            lhs.latestReactions == rhs.latestReactions &&
            lhs.location == rhs.location &&
            lhs.mentionedUsers == rhs.mentionedUsers &&
            lhs.metrics == rhs.metrics &&
            lhs.moderation == rhs.moderation &&
            lhs.moderationAction == rhs.moderationAction &&
            lhs.notificationContext == rhs.notificationContext &&
            lhs.ownBookmarks == rhs.ownBookmarks &&
            lhs.ownReactions == rhs.ownReactions &&
            lhs.parent == rhs.parent &&
            lhs.poll == rhs.poll &&
            lhs.popularity == rhs.popularity &&
            lhs.preview == rhs.preview &&
            lhs.reactionCount == rhs.reactionCount &&
            lhs.reactionGroups == rhs.reactionGroups &&
            lhs.restrictReplies == rhs.restrictReplies &&
            lhs.score == rhs.score &&
            lhs.scoreVars == rhs.scoreVars &&
            lhs.searchData == rhs.searchData &&
            lhs.selectorSource == rhs.selectorSource &&
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
        hasher.combine(currentFeed)
        hasher.combine(custom)
        hasher.combine(deletedAt)
        hasher.combine(editedAt)
        hasher.combine(expiresAt)
        hasher.combine(feeds)
        hasher.combine(filterTags)
        hasher.combine(friendReactionCount)
        hasher.combine(friendReactions)
        hasher.combine(hidden)
        hasher.combine(id)
        hasher.combine(interestTags)
        hasher.combine(isRead)
        hasher.combine(isSeen)
        hasher.combine(isWatched)
        hasher.combine(latestReactions)
        hasher.combine(location)
        hasher.combine(mentionedUsers)
        hasher.combine(metrics)
        hasher.combine(moderation)
        hasher.combine(moderationAction)
        hasher.combine(notificationContext)
        hasher.combine(ownBookmarks)
        hasher.combine(ownReactions)
        hasher.combine(parent)
        hasher.combine(poll)
        hasher.combine(popularity)
        hasher.combine(preview)
        hasher.combine(reactionCount)
        hasher.combine(reactionGroups)
        hasher.combine(restrictReplies)
        hasher.combine(score)
        hasher.combine(scoreVars)
        hasher.combine(searchData)
        hasher.combine(selectorSource)
        hasher.combine(shareCount)
        hasher.combine(text)
        hasher.combine(type)
        hasher.combine(updatedAt)
        hasher.combine(user)
        hasher.combine(visibility)
        hasher.combine(visibilityTag)
    }
}
