//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class FeedsV3CommentResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var attachments: [Attachment]?
    var confidenceScore: Float
    var controversyScore: Float?
    var createdAt: Date
    var custom: [String: RawJSON]?
    var deletedAt: Date?
    var downvoteCount: Int
    var editedAt: Date?
    var id: String
    var mentionedUsers: [UserResponse]
    var moderation: ModerationV2Response?
    var objectId: String
    var objectType: String
    var ownReactions: Array
    var parentId: String?
    var reactionCount: Int
    var replyCount: Int
    var score: Int
    var status: String
    var text: String?
    var updatedAt: Date
    var upvoteCount: Int
    var user: UserResponse

    init(attachments: [Attachment]? = nil, confidenceScore: Float, controversyScore: Float? = nil, createdAt: Date, custom: [String: RawJSON]? = nil, deletedAt: Date? = nil, downvoteCount: Int, editedAt: Date? = nil, id: String, mentionedUsers: [UserResponse], moderation: ModerationV2Response? = nil, objectId: String, objectType: String, ownReactions: Array, parentId: String? = nil, reactionCount: Int, replyCount: Int, score: Int, status: String, text: String? = nil, updatedAt: Date, upvoteCount: Int, user: UserResponse) {
        self.attachments = attachments
        self.confidenceScore = confidenceScore
        self.controversyScore = controversyScore
        self.createdAt = createdAt
        self.custom = custom
        self.deletedAt = deletedAt
        self.downvoteCount = downvoteCount
        self.editedAt = editedAt
        self.id = id
        self.mentionedUsers = mentionedUsers
        self.moderation = moderation
        self.objectId = objectId
        self.objectType = objectType
        self.ownReactions = ownReactions
        self.parentId = parentId
        self.reactionCount = reactionCount
        self.replyCount = replyCount
        self.score = score
        self.status = status
        self.text = text
        self.updatedAt = updatedAt
        self.upvoteCount = upvoteCount
        self.user = user
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case attachments
        case confidenceScore = "confidence_score"
        case controversyScore = "controversy_score"
        case createdAt = "created_at"
        case custom
        case deletedAt = "deleted_at"
        case downvoteCount = "downvote_count"
        case editedAt = "edited_at"
        case id
        case mentionedUsers = "mentioned_users"
        case moderation
        case objectId = "object_id"
        case objectType = "object_type"
        case ownReactions = "own_reactions"
        case parentId = "parent_id"
        case reactionCount = "reaction_count"
        case replyCount = "reply_count"
        case score
        case status
        case text
        case updatedAt = "updated_at"
        case upvoteCount = "upvote_count"
        case user
    }

    static func == (lhs: FeedsV3CommentResponse, rhs: FeedsV3CommentResponse) -> Bool {
        lhs.attachments == rhs.attachments &&
            lhs.confidenceScore == rhs.confidenceScore &&
            lhs.controversyScore == rhs.controversyScore &&
            lhs.createdAt == rhs.createdAt &&
            lhs.custom == rhs.custom &&
            lhs.deletedAt == rhs.deletedAt &&
            lhs.downvoteCount == rhs.downvoteCount &&
            lhs.editedAt == rhs.editedAt &&
            lhs.id == rhs.id &&
            lhs.mentionedUsers == rhs.mentionedUsers &&
            lhs.moderation == rhs.moderation &&
            lhs.objectId == rhs.objectId &&
            lhs.objectType == rhs.objectType &&
            lhs.ownReactions == rhs.ownReactions &&
            lhs.parentId == rhs.parentId &&
            lhs.reactionCount == rhs.reactionCount &&
            lhs.replyCount == rhs.replyCount &&
            lhs.score == rhs.score &&
            lhs.status == rhs.status &&
            lhs.text == rhs.text &&
            lhs.updatedAt == rhs.updatedAt &&
            lhs.upvoteCount == rhs.upvoteCount &&
            lhs.user == rhs.user
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(attachments)
        hasher.combine(confidenceScore)
        hasher.combine(controversyScore)
        hasher.combine(createdAt)
        hasher.combine(custom)
        hasher.combine(deletedAt)
        hasher.combine(downvoteCount)
        hasher.combine(editedAt)
        hasher.combine(id)
        hasher.combine(mentionedUsers)
        hasher.combine(moderation)
        hasher.combine(objectId)
        hasher.combine(objectType)
        hasher.combine(ownReactions)
        hasher.combine(parentId)
        hasher.combine(reactionCount)
        hasher.combine(replyCount)
        hasher.combine(score)
        hasher.combine(status)
        hasher.combine(text)
        hasher.combine(updatedAt)
        hasher.combine(upvoteCount)
        hasher.combine(user)
    }
}
