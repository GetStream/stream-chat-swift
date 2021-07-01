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
        case channel
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
        case reactionScores = "reaction_scores"
        case isSilent = "silent"
        case i18n
    }
    
    /// A custom extra data type for messages.
    /// - Note: Use this variable to setup your own extra data type for decoding messages custom fields from JSON data.
    public static var extraDataType: Codable.Type?
    
    static var flaggedIds = Set<String>()
    
    /// A message id.
    public var id: String
    /// A message type (see `MessageType`).
    public var type: MessageType
    /// A user (see `User`).
    public var user: User
    /// A channel (see `Channel`).
    public var channel: Channel?
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
    public var attachments: [Attachment]
    /// A parent message id.
    public var parentId: String?
    /// Check if this reply message needs to show in the channel.
    public var showReplyInChannel: Bool
    /// Mentioned users (see `User`).
    public internal(set) var mentionedUsers: [User]
    /// Reply count.
    public var replyCount: Int
    /// An extra data for the message.
    public var extraData: Codable?
    /// The latest reactions (see `Reaction`).
    public private(set) var latestReactions: [Reaction]
    /// The current user own reactions (see `Reaction`).
    public private(set) var ownReactions: [Reaction]
    /// A reactions count (see `ReactionCounts`).
    public private(set) var reactionScores: [String: Int]
    /// Flag for silent messages. Silent messages won't increase the unread count. See https://getstream.io/chat/docs/silent_messages/?language=swift
    public var isSilent: Bool
    /// Internationalization and localization for the message. Only available for messages returned via `message.translate()`
    public var i18n: MessageTranslations?
    
    /// Check if the message is ephemeral, e.g. Giphy preview.
    public var isEphemeral: Bool { type == .ephemeral }
    /// Check if the message was deleted.
    public var isDeleted: Bool { type == .deleted || deleted != nil }
    /// Check if the message is own message of the current user.
    public var isOwn: Bool { user.isCurrent }
    /// Check if the message is a reply.
    public var isReply: Bool { parentId != nil }
    /// Check if the message could be edited.
    public var canEdit: Bool { isOwn && (!text.isBlank || !attachments.isEmpty) }
    /// Check if the message could be deleted.
    public var canDelete: Bool { isOwn }
    /// Check if the message has reactions.
    public var hasReactions: Bool { !reactionScores.isEmpty }
    /// Checks if the message is flagged (locally).
    public var isFlagged: Bool { Message.flaggedIds.contains(id) }
    
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
    public var isBan: Bool { id.isEmpty && type == .error && text == "You are not allowed to post messages on this channel" }
    /// Checks if the message is empty.
    public var isEmpty: Bool { text.isBlank && attachments.isEmpty && command.isBlank && extraData == nil }
    
    /// Init a message.
    ///
    /// - Parameters:
    ///   - id: Message id, leave it blank if it's a new message since server generates it
    ///   - type: Message type. See `MessageType`
    ///   - parentId: Parent message id if this message is a reply
    ///   - created: Message created date
    ///   - updated: Message updated date
    ///   - deleted: Message deleted date
    ///   - text: Message body
    ///   - isSilent: Flag for indicating if this message is silent (does not increase unread count)
    ///   - user: Owner of the message. Keep in mind that clients can only send messages as logged in user (User.current)
    ///   - command: Command associated with message
    ///   - args: Arguments in message
    ///   - attachments: Attachments for this message
    ///   - mentionedUsers: Mentioned users in this message
    ///   - extraData: ExtraData for this message
    ///   - latestReactions: Reactions to this message
    ///   - ownReactions: Current user's reactions to this message
    ///   - reactionScores: Scores of reactions to this message
    ///   - replyCount: Reply count
    ///   - showReplyInChannel: Flag for showing this reply message also in channel.
    public init(id: String = "",
                type: MessageType = .regular,
                parentId: String? = nil,
                created: Date = .init(),
                updated: Date = .init(),
                deleted: Date? = nil,
                text: String,
                silent: Bool = false,
                user: User = User.current,
                channel: Channel? = nil,
                command: String? = nil,
                args: String? = nil,
                attachments: [Attachment] = [],
                mentionedUsers: [User] = [],
                extraData: Codable? = nil,
                latestReactions: [Reaction] = [],
                ownReactions: [Reaction] = [],
                reactionScores: [String: Int] = [:],
                replyCount: Int = 0,
                showReplyInChannel: Bool = false) {
        self.id = id
        self.type = type
        self.parentId = parentId
        self.created = created
        self.updated = updated
        self.deleted = deleted
        self.text = text
        self.isSilent = silent
        self.user = user
        self.channel = channel
        self.command = command
        self.args = args
        self.attachments = attachments
        self.mentionedUsers = mentionedUsers
        self.extraData = extraData
        self.latestReactions = latestReactions
        self.ownReactions = ownReactions
        self.reactionScores = reactionScores
        self.replyCount = replyCount
        self.showReplyInChannel = showReplyInChannel
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(text, forKey: .text)
        try container.encode(isSilent, forKey: .isSilent)
        extraData?.encodeSafely(to: encoder, logMessage: "📦 when encoding a message extra data")
        
        if !attachments.isEmpty {
            try container.encode(attachments, forKey: .attachments)
        }
        
        if isReply {
            try container.encode(parentId, forKey: .parentId)
            try container.encode(showReplyInChannel, forKey: .showReplyInChannel)
        }
        
        if !mentionedUsers.isEmpty {
            try container.encode(mentionedUsers.map({ $0.id }), forKey: .mentionedUsers)
        }
        
        if !id.isEmpty {
            try container.encode(id, forKey: .id)
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        type = try container.decode(MessageType.self, forKey: .type)
        user = try container.decode(User.self, forKey: .user)
        channel = try container.decodeIfPresent(Channel.self, forKey: .channel)
        created = try container.decode(Date.self, forKey: .created)
        updated = try container.decode(Date.self, forKey: .updated)
        deleted = try container.decodeIfPresent(Date.self, forKey: .deleted)
        text = try container.decode(String.self, forKey: .text).trimmingCharacters(in: .whitespacesAndNewlines)
        isSilent = try container.decodeIfPresent(Bool.self, forKey: .isSilent) ?? false
        command = try container.decodeIfPresent(String.self, forKey: .command)
        args = try container.decodeIfPresent(String.self, forKey: .args)
        attachments = try container.decode([Attachment].self, forKey: .attachments)
        parentId = try container.decodeIfPresent(String.self, forKey: .parentId)
        showReplyInChannel = try container.decodeIfPresent(Bool.self, forKey: .showReplyInChannel) ?? false
        mentionedUsers = try container.decode([User].self, forKey: .mentionedUsers)
        replyCount = try container.decode(Int.self, forKey: .replyCount)
        latestReactions = (try? container.decode([Reaction].self, forKey: .latestReactions)) ?? []
        ownReactions = (try? container.decode([Reaction].self, forKey: .ownReactions)) ?? []
        reactionScores = try container.decodeIfPresent([String: Int].self, forKey: .reactionScores) ?? [:]
        i18n = try container.decodeIfPresent(MessageTranslations.self, forKey: .i18n)
        extraData = try? Self.extraDataType?.init(from: decoder) // swiftlint:disable:this explicit_init
    }
    
    private func checkIfTextAsAttachmentURL(_ text: String) -> Bool {
        let text = text.lowercased()
        return !text.isEmpty && text.hasPrefix("http") && !text.contains(" ") && attachments.count == 1
    }
}

extension Message: Equatable {
    public static func == (lhs: Message, rhs: Message) -> Bool {
        lhs.id == rhs.id
            && lhs.type == rhs.type
            && lhs.parentId == rhs.parentId
            && lhs.user == rhs.user
            && lhs.text == rhs.text
            && lhs.command == rhs.command
            && lhs.attachments == rhs.attachments
            && lhs.showReplyInChannel == rhs.showReplyInChannel
            && lhs.created == rhs.created
            && lhs.updated == rhs.updated
            && lhs.deleted == rhs.deleted
    }
}

// MARK: - Reactions

public extension Message {
    
    /// Check if the message has a reaction with the given type from the current user.
    /// - Parameter type: a reaction type.
    /// - Returns: true if the message has a reaction type.
    func hasOwnReaction(type: String) -> Bool {
        !ownReactions.isEmpty && ownReactions.firstIndex(where: { $0.type == type }) != nil
    }
    
    /// Add a given reaction to the current user own reactions.
    /// - Parameters:
    ///   - reaction: a reaction for adding.
    ///   - reactions: the current list of user own reactions.
    mutating func addOrUpdate(reaction: Reaction, toOwnReactions reactions: [Reaction]) {
        var reactions = reactions
        
        if let index = reactions.firstIndex(where: { $0.type == reaction.type }) {
            reactions[index] = reaction
        } else {
            reactions.insert(reaction, at: 0)
        }
        
        ownReactions = reactions
    }
    
    /// Delete a given reaction from the current user own reaction.
    /// - Parameters:
    ///   - reaction: a reaction for deleting.
    ///   - reactions: the current list of user own reactions.
    mutating func delete(reaction: Reaction, fromOwnReactions reactions: [Reaction]) {
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

// MARK: - Supporting Structs

/// A messages response.
public struct MessagesResponse: Decodable {
    /// A list of messages.
    let messages: [Message]
}

struct FlagResponse<T: Decodable>: Decodable {
    let flag: T
}

/// A flag message response.
public struct FlagMessageResponse: Decodable {
    private enum CodingKeys: String, CodingKey {
        case messageId = "target_message_id"
        case created = "created_at"
        case updated = "updated_at"
    }
    
    /// A flagged message id.
    public let messageId: String
    /// A created date.
    public let created: Date
    /// A updated date.
    public let updated: Date
}

// MARK: - Hashable
extension Message: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
