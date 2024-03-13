//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct MessageResponse: Codable, Hashable {
    public var cid: String
    public var createdAt: Date
    public var deletedReplyCount: Int
    public var html: String
    public var id: String
    public var pinned: Bool
    public var replyCount: Int
    public var shadowed: Bool
    public var silent: Bool
    public var text: String
    public var type: String
    public var updatedAt: Date
    public var attachments: [Attachment?]
    public var latestReactions: [Reaction?]
    public var mentionedUsers: [UserResponse]
    public var ownReactions: [Reaction?]
    public var custom: [String: RawJSON]?
    public var reactionCounts: [String: Int]
    public var reactionScores: [String: Int]
    public var user: UserResponse
    public var command: String? = nil
    public var deletedAt: Date? = nil
    public var mml: String? = nil
    public var parentId: String? = nil
    public var pinExpires: Date? = nil
    public var pinnedAt: Date? = nil
    public var quotedMessageId: String? = nil
    public var showInChannel: Bool? = nil
    public var threadParticipants: [UserResponse]? = nil
    public var i18n: [String: String]? = nil
    public var imageLabels: [String: [String]]? = nil
    public var pinnedBy: UserResponse? = nil
    public var quotedMessage: Message? = nil

    public init(cid: String, createdAt: Date, deletedReplyCount: Int, html: String, id: String, pinned: Bool, replyCount: Int, shadowed: Bool, silent: Bool, text: String, type: String, updatedAt: Date, attachments: [Attachment?], latestReactions: [Reaction?], mentionedUsers: [UserResponse], ownReactions: [Reaction?], custom: [String: RawJSON], reactionCounts: [String: Int], reactionScores: [String: Int], user: UserResponse, command: String? = nil, deletedAt: Date? = nil, mml: String? = nil, parentId: String? = nil, pinExpires: Date? = nil, pinnedAt: Date? = nil, quotedMessageId: String? = nil, showInChannel: Bool? = nil, threadParticipants: [UserResponse]? = nil, i18n: [String: String]? = nil, imageLabels: [String: [String]]? = nil, pinnedBy: UserResponse? = nil, quotedMessage: Message? = nil) {
        self.cid = cid
        self.createdAt = createdAt
        self.deletedReplyCount = deletedReplyCount
        self.html = html
        self.id = id
        self.pinned = pinned
        self.replyCount = replyCount
        self.shadowed = shadowed
        self.silent = silent
        self.text = text
        self.type = type
        self.updatedAt = updatedAt
        self.attachments = attachments
        self.latestReactions = latestReactions
        self.mentionedUsers = mentionedUsers
        self.ownReactions = ownReactions
        self.custom = custom
        self.reactionCounts = reactionCounts
        self.reactionScores = reactionScores
        self.user = user
        self.command = command
        self.deletedAt = deletedAt
        self.mml = mml
        self.parentId = parentId
        self.pinExpires = pinExpires
        self.pinnedAt = pinnedAt
        self.quotedMessageId = quotedMessageId
        self.showInChannel = showInChannel
        self.threadParticipants = threadParticipants
        self.i18n = i18n
        self.imageLabels = imageLabels
        self.pinnedBy = pinnedBy
        self.quotedMessage = quotedMessage
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case cid
        case createdAt = "created_at"
        case deletedReplyCount = "deleted_reply_count"
        case html
        case id
        case pinned
        case replyCount = "reply_count"
        case shadowed
        case silent
        case text
        case type
        case updatedAt = "updated_at"
        case attachments
        case latestReactions = "latest_reactions"
        case mentionedUsers = "mentioned_users"
        case ownReactions = "own_reactions"
        case custom
        case reactionCounts = "reaction_counts"
        case reactionScores = "reaction_scores"
        case user
        case command
        case deletedAt = "deleted_at"
        case mml
        case parentId = "parent_id"
        case pinExpires = "pin_expires"
        case pinnedAt = "pinned_at"
        case quotedMessageId = "quoted_message_id"
        case showInChannel = "show_in_channel"
        case threadParticipants = "thread_participants"
        case i18n
        case imageLabels = "image_labels"
        case pinnedBy = "pinned_by"
        case quotedMessage = "quoted_message"
    }
}
