//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

/// A message type, e.g. regular, ephemeral, reply.
public enum MessageType: String, Codable {
    /// A message type.
    case regular, ephemeral, error, reply, system, deleted
}

struct MessagePayload<ExtraData: ExtraDataTypes>: Decodable {
    private enum CodingKeys: String, CodingKey {
        case id
        case type
        case user
        case created = "created_at"
        case updated = "updated_at"
        case deleted = "deleted_at"
        case text
        case command
        case args
//        case attachments
        case parentId = "parent_id"
        case showReplyInChannel = "show_in_channel"
        case mentionedUsers = "mentioned_users"
        case replyCount = "reply_count"
//        case latestReactions = "latest_reactions"
//        case ownReactions = "own_reactions"
        case reactionScores = "reaction_scores"
        case isSilent = "silent"
//        case i18n
    }
    
    /// A message id.
    public var id: String
    /// A message type (see `MessageType`).
    public var type: MessageType
    /// A user (see `User`).
    public var user: UserPayload<ExtraData.User>
    /// A created date.
    public var created: Date
    /// A updated date.
    public var updated: Date
    /// A deleted date.
    public var deleted: Date?
    /// A text.
    public var text: String
    /// A used command name.
    public var command: String?
    /// A used command args.
    public var args: String?
    /// Attachments (see `Attachment`).
//    public var attachments: [Attachment]
    /// A parent message id.
    public var parentId: String?
    /// Check if this reply message needs to show in the channel.
    public var showReplyInChannel: Bool
    /// Mentioned users (see `User`).
    public internal(set) var mentionedUsers: [UserPayload<ExtraData.User>]
    /// Reply count.
    public var replyCount: Int
    /// An extra data for the message.
    public var extraData: ExtraData.Message
    /// The latest reactions (see `Reaction`).
//    public private(set) var latestReactions: [Reaction]
    /// The current user own reactions (see `Reaction`).
//    public private(set) var ownReactions: [Reaction]
    /// A reactions count (see `ReactionCounts`).
    public private(set) var reactionScores: [String: Int]
    /// Flag for silent messages. Silent messages won't increase the unread count. See https://getstream.io/chat/docs/silent_messages/?language=swift
    public var isSilent: Bool
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        type = try container.decode(MessageType.self, forKey: .type)
        user = try container.decode(UserPayload<ExtraData.User>.self, forKey: .user)
        created = try container.decode(Date.self, forKey: .created)
        updated = try container.decode(Date.self, forKey: .updated)
        deleted = try container.decodeIfPresent(Date.self, forKey: .deleted)
        text = try container.decode(String.self, forKey: .text).trimmingCharacters(in: .whitespacesAndNewlines)
        isSilent = try container.decodeIfPresent(Bool.self, forKey: .isSilent) ?? false
        command = try container.decodeIfPresent(String.self, forKey: .command)
        args = try container.decodeIfPresent(String.self, forKey: .args)
//        attachments = try container.decode([Attachment].self, forKey: .attachments)
        parentId = try container.decodeIfPresent(String.self, forKey: .parentId)
        showReplyInChannel = try container.decodeIfPresent(Bool.self, forKey: .showReplyInChannel) ?? false
        mentionedUsers = try container.decode([UserPayload<ExtraData.User>].self, forKey: .mentionedUsers)
        replyCount = try container.decode(Int.self, forKey: .replyCount)
//        latestReactions = (try? container.decode([Reaction].self, forKey: .latestReactions)) ?? []
//        ownReactions = (try? container.decode([Reaction].self, forKey: .ownReactions)) ?? []
        reactionScores = try container.decodeIfPresent([String: Int].self, forKey: .reactionScores) ?? [:]
//        i18n = try container.decodeIfPresent(MessageTranslations.self, forKey: .i18n)
        extraData = try ExtraData.Message(from: decoder)
    }
    
    init(
        id: String,
        type: MessageType,
        user: UserPayload<ExtraData.User>,
        created: Date,
        updated: Date,
        deleted: Date? = nil,
        text: String,
        command: String? = nil,
        args: String? = nil,
        parentId: String? = nil,
        showReplyInChannel: Bool,
        mentionedUsers: [UserPayload<ExtraData.User>],
        replyCount: Int,
        extraData: ExtraData.Message,
        reactionScores: [String: Int],
        isSilent: Bool
    ) {
        self.id = id
        self.type = type
        self.user = user
        self.created = created
        self.updated = updated
        self.deleted = deleted
        self.text = text
        self.command = command
        self.args = args
        self.parentId = parentId
        self.showReplyInChannel = showReplyInChannel
        self.mentionedUsers = mentionedUsers
        self.replyCount = replyCount
        self.extraData = extraData
        self.reactionScores = reactionScores
        self.isSilent = isSilent
    }
}

/// A command in a message, e.g. /giphy.
public struct Command: Codable, Hashable {
    /// A command name.
    public let name: String
    /// A description.
    public let description: String
    public let set: String
    /// Args for the command.
    public let args: String
    
    public init(name: String = "", description: String = "", set: String = "", args: String = "") {
        self.name = name
        self.description = description
        self.set = set
        self.args = args
    }
}
