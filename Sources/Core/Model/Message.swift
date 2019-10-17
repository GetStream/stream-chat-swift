//
//  Message.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 02/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

/// A message.
public struct Message: Codable {
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
        case attachments
        case parentId = "parent_id"
        case showReplyInChannel = "show_in_channel"
        case mentionedUsers = "mentioned_users"
        case replyCount = "reply_count"
        case latestReactions = "latest_reactions"
        case ownReactions = "own_reactions"
        case reactionCounts = "reaction_counts"
    }
    
    /// A message id.
    public let id: String
    /// A message type (see `MessageType`).
    public let type: MessageType
    /// A user (see `User`).
    public let user: User
    /// A created date.
    public let created: Date
    /// A updated date.
    public let updated: Date
    /// A deleted date.
    public let deleted: Date?
    /// A text.
    public let text: String
    /// A used command name.
    public let command: String?
    /// A used command args.
    public let args: String?
    /// Attachments (see `Attachment`).
    public let attachments: [Attachment]
    /// A parent message id.
    public let parentId: String?
    /// Check if this reply message needs to show in the channel.
    public let showReplyInChannel: Bool?
    /// Mentioned users (see `User`).
    public let mentionedUsers: [User]
    /// Reply count.
    public let replyCount: Int
    /// An extra data for the message.
    public let extraData: ExtraData?
    /// The latest reactions (see `Reaction`).
    public private(set) var latestReactions: [Reaction]
    /// The current user own reactions (see `Reaction`).
    public private(set) var ownReactions: [Reaction]
    /// A reactions count (see `ReactionCounts`).
    public private(set) var reactionCounts: ReactionCounts?
    
    /// Check if the message is ephemeral, e.g. Giphy preview.
    public var isEphemeral: Bool {
        return type == .ephemeral
    }
    
    /// Check if the message was deleted.
    public var isDeleted: Bool {
        return type == .deleted || deleted != nil
    }
    
    /// Check if the message is own message of the current user.
    public var isOwn: Bool {
        return user.isCurrent
    }
    
    /// Check if the message could be edited.
    public var canEdit: Bool {
        return isOwn && (!text.isBlank || !attachments.isEmpty)
    }
    
    /// Check if the message could be deleted.
    public var canDelete: Bool {
        return isOwn
    }
    
    /// Check if the message has reactions.
    public var hasReactions: Bool {
        return reactionCounts != nil && !(reactionCounts?.counts.isEmpty ?? true)
    }
    
    /// A combination of message text and command args.
    /// 1. if the text is not empty and it's not equal to the single attachment URL, then it will return empty string.
    /// 2. if the text is empty, then it will return commands args.
    public var textOrArgs: String {
        let text = self.text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return checkIfTextAsAttachmentURL(text)
            ? ""
            : (text.isEmpty ? (args ?? "") : text).trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Returns true if the message is type of error with a text for the banned user.
    public var isBan: Bool {
        return id.isEmpty && type == .error && text == "You are not allowed to post messages on this channel"
    }
    
    /// Init a message.
    ///
    /// - Parameters:
    ///   - id: a message id.
    ///   - text: a text.
    ///   - attachments: attachments (see `Attachment`).
    ///   - extraData: an extra data.
    ///   - parentId: a parent message id.
    ///   - mentionedUsers: a list of mentioned users.
    ///   - showReplyInChannel: a flag to show reply messages in a channel, not in a separate thread.
    public init(id: String = "",
                text: String,
                attachments: [Attachment] = [],
                extraData: Codable? = nil,
                parentId: String? = nil,
                mentionedUsers: [User] = [],
                showReplyInChannel: Bool = false) {
        self.id = id
        self.parentId = parentId
        self.showReplyInChannel = showReplyInChannel
        type = .regular
        user = .unknown
        created = .default
        updated = .default
        deleted = nil
        self.text = text
        command = nil
        args = nil
        self.attachments = attachments
        self.mentionedUsers = mentionedUsers
        replyCount = 0
        latestReactions = []
        ownReactions = []
        reactionCounts = nil
        
        if let extraData = extraData {
            self.extraData = ExtraData(extraData)
        } else {
            self.extraData = nil
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(text, forKey: .text)
        extraData?.encodeSafely(to: encoder)
        
        if !attachments.isEmpty {
            try container.encode(attachments, forKey: .attachments)
        }
        
        if parentId != nil {
            try container.encode(parentId, forKey: .parentId)
            try container.encode(showReplyInChannel, forKey: .showReplyInChannel)
        }
        
        if !mentionedUsers.isEmpty {
            try container.encode(mentionedUsers.map({ $0.id }), forKey: .mentionedUsers)
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        type = try container.decode(MessageType.self, forKey: .type)
        user = try container.decode(User.self, forKey: .user)
        created = try container.decode(Date.self, forKey: .created)
        updated = try container.decode(Date.self, forKey: .updated)
        deleted = try container.decodeIfPresent(Date.self, forKey: .deleted)
        text = try container.decode(String.self, forKey: .text)
        command = try container.decodeIfPresent(String.self, forKey: .command)
        args = try container.decodeIfPresent(String.self, forKey: .args)
        attachments = try container.decode([Attachment].self, forKey: .attachments)
        parentId = try container.decodeIfPresent(String.self, forKey: .parentId)
        showReplyInChannel = false
        mentionedUsers = try container.decode([User].self, forKey: .mentionedUsers)
        replyCount = try container.decode(Int.self, forKey: .replyCount)
        latestReactions = try container.decode([Reaction].self, forKey: .latestReactions)
        ownReactions = try container.decode([Reaction].self, forKey: .ownReactions)
        extraData = .decode(from: decoder, ExtraData.decodableTypes.first(where: { $0.isMessage }))
        
        if let reactionCounts = try container.decodeIfPresent(ReactionCounts.self, forKey: .reactionCounts),
            !reactionCounts.counts.isEmpty {
            self.reactionCounts = reactionCounts
        } else {
            reactionCounts = nil
        }
    }
    
    private func checkIfTextAsAttachmentURL(_ text: String) -> Bool {
        let text = text.lowercased()
        return !text.isEmpty && text.hasPrefix("http") && !text.contains(" ") && attachments.count == 1
    }
}

extension Message: Equatable {
    public static func == (lhs: Message, rhs: Message) -> Bool {
        return lhs.id == rhs.id
            && lhs.type == rhs.type
            && lhs.user == rhs.user
            && lhs.text == rhs.text
            && lhs.created == rhs.created
            && lhs.updated == rhs.updated
            && lhs.deleted == rhs.deleted
    }
}

// MARK: - Reactions

public extension Message {
    
    /// Check if the message has a reaction with the given type from the current user.
    ///
    /// - Parameter type: a reaction type.
    /// - Returns: true if the message has a reaction type.
    func hasOwnReaction(type: ReactionType) -> Bool {
        return !ownReactions.isEmpty && ownReactions.firstIndex(where: { $0.type == type }) != nil
    }
    
    /// Add a given reaction to the current user own reactions.
    ///
    /// - Parameters:
    ///   - reaction: a reaction for adding.
    ///   - reactions: the current list of user own reactions.
    mutating func addToOwnReactions(_ reaction: Reaction, reactions: [Reaction]) {
        var reactions = reactions
        
        if let index = reactions.firstIndex(where: { $0.type == reaction.type }) {
            reactions[index] = reaction
        } else {
            reactions.insert(reaction, at: 0)
        }
        
        ownReactions = reactions
    }
    
    /// Delete a given reaction from the current user own reaction.
    ///
    /// - Parameters:
    ///   - reaction: a reaction for deleting.
    ///   - reactions: the current list of user own reactions.
    mutating func deleteFromOwnReactions(_ reaction: Reaction, reactions: [Reaction]) {
        var reactions = reactions
        
        if let index = reactions.firstIndex(where: { $0.type == reaction.type }) {
            reactions.remove(at: index)
        }
        
        ownReactions = reactions
    }
}

// MARK: - Type

/// A message type, e.g. regular, ephemeral, reply.
public enum MessageType: String, Codable {
    /// A message type.
    case regular, ephemeral, error, reply, system, deleted
}
