//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

/// Coding keys for message-related JSON payloads
enum MessagePayloadsCodingKeys: String, CodingKey {
    case id
    case type
    case user
    case createdAt = "created_at"
    case updatedAt = "updated_at"
    case deletedAt = "deleted_at"
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

/// An object describing the incoming message JSON payload.
struct MessagePayload<ExtraData: ExtraDataTypes>: Decodable {
    let id: String
    let type: MessageType
    let user: UserPayload<ExtraData.User>
    let createdAt: Date
    let updatedAt: Date
    let deletedAt: Date?
    let text: String
    let command: String?
    let args: String?
    let parentId: String?
    let showReplyInChannel: Bool
    let mentionedUsers: [UserPayload<ExtraData.User>]
    let replyCount: Int
    let extraData: ExtraData.Message
    
    // TODO: Reactions
    // TODO: Attachments
    // TODO: Translations
    
    let latestReactions: [ReactionPayload] = []
    let ownReactions: [ReactionPayload] = []
    let reactionScores: [String: Int]
    let isSilent: Bool
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: MessagePayloadsCodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        type = try container.decode(MessageType.self, forKey: .type)
        user = try container.decode(UserPayload<ExtraData.User>.self, forKey: .user)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        deletedAt = try container.decodeIfPresent(Date.self, forKey: .deletedAt)
        text = try container.decode(String.self, forKey: .text).trimmingCharacters(in: .whitespacesAndNewlines)
        isSilent = try container.decodeIfPresent(Bool.self, forKey: .isSilent) ?? false
        command = try container.decodeIfPresent(String.self, forKey: .command)
        args = try container.decodeIfPresent(String.self, forKey: .args)
        parentId = try container.decodeIfPresent(String.self, forKey: .parentId)
        showReplyInChannel = try container.decodeIfPresent(Bool.self, forKey: .showReplyInChannel) ?? false
        mentionedUsers = try container.decode([UserPayload<ExtraData.User>].self, forKey: .mentionedUsers)
        replyCount = try container.decode(Int.self, forKey: .replyCount)
        
        reactionScores = try container.decodeIfPresent([String: Int].self, forKey: .reactionScores) ?? [:]
        extraData = try ExtraData.Message(from: decoder)
    }
    
    init(
        id: String,
        type: MessageType,
        user: UserPayload<ExtraData.User>,
        createdAt: Date,
        updatedAt: Date,
        deletedAt: Date? = nil,
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
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
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

/// An object describing the outgoing message JSON payload.
struct MessageRequestBody<ExtraData: ExtraDataTypes>: Encodable {
    let id: String
    let user: UserRequestBody<ExtraData.User>
    let text: String
    let command: String?
    let args: String?
    let parentId: String?
    let showReplyInChannel: Bool
    let extraData: ExtraData.Message
    
    init(
        id: String,
        user: UserRequestBody<ExtraData.User>,
        text: String,
        command: String? = nil,
        args: String? = nil,
        parentId: String? = nil,
        showReplyInChannel: Bool = false,
        extraData: ExtraData.Message
    ) {
        self.id = id
        self.user = user
        self.text = text
        self.command = command
        self.args = args
        self.parentId = parentId
        self.showReplyInChannel = showReplyInChannel
        self.extraData = extraData
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: MessagePayloadsCodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(text, forKey: .text)
        try container.encodeIfPresent(command, forKey: .command)
        try container.encodeIfPresent(args, forKey: .args)
        try container.encodeIfPresent(parentId, forKey: .parentId)
        try container.encodeIfPresent(showReplyInChannel, forKey: .showReplyInChannel)
        
        try extraData.encode(to: encoder)
    }
}

// TODO: Command???

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
