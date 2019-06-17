//
//  Message.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 02/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

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
        case extraData
    }
    
    let id: String
    public let type: MessageType
    public let user: User
    public let created: Date
    public let updated: Date
    public let deleted: Date?
    public let text: String
    public let command: String?
    public let args: String?
    public let attachments: [Attachment]
    public let parentId: String?
    public let showReplyInChannel: Bool?
    public let mentionedUsers: [User]
    public let replyCount: Int
    public let extraData: ExtraData?
    public private(set) var latestReactions: [Reaction]
    public private(set) var ownReactions: [Reaction]
    public private(set) var reactionCounts: ReactionCounts?
    
    public var isEphemeral: Bool {
        return type == .ephemeral
    }
    
    public var isDeleted: Bool {
        return deleted != nil
    }
    
    public var isOwn: Bool {
        return Client.shared.user == user
    }
    
    public var canEdit: Bool {
        return isOwn
    }
    
    public var canDelete: Bool {
        return isOwn
    }
    
    public var textOrArgs: String {
        let text = self.text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return checkIfTextAsAttachmentURL(text)
            ? ""
            : (text.isEmpty ? (args ?? "") : text).trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    init?(id: String = "",
          text: String,
          attachments: [Attachment] = [],
          extraData: ExtraData?,
          parentId: String?,
          showReplyInChannel: Bool) {
        guard let user = Client.shared.user else {
            return nil
        }
        
        self.id = id
        self.parentId = parentId
        self.showReplyInChannel = showReplyInChannel
        type = .regular
        self.user = user
        created = Date()
        updated = Date()
        deleted = nil
        self.text = text
        command = nil
        args = nil
        self.attachments = attachments
        mentionedUsers = []
        replyCount = 0
        latestReactions = []
        ownReactions = []
        reactionCounts = nil
        self.extraData = extraData
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
        reactionCounts = try container.decodeIfPresent(ReactionCounts.self, forKey: .reactionCounts)
        extraData = .decode(from: decoder, ExtraData.decodableTypes.first(where: { $0.isMessage }))
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

extension Message {
    
    public func hasOwnReaction(type: String) -> Bool {
        return !ownReactions.isEmpty && ownReactions.firstIndex(where: { $0.type == type }) != nil
    }
    
    mutating func addToOwnReactions(_ reaction: Reaction, reactions: [Reaction]) {
        var reactions = reactions
        
        if let index = reactions.firstIndex(where: { $0.type == reaction.type }) {
            reactions[index] = reaction
        } else {
            reactions.insert(reaction, at: 0)
        }
        
        ownReactions = reactions
    }

    mutating func deleteFromOwnReactions(_ reaction: Reaction, reactions: [Reaction]) {
        var reactions = reactions
        
        if let index = reactions.firstIndex(where: { $0.type == reaction.type }) {
            reactions.remove(at: index)
        }
        
        ownReactions = reactions
    }
}

// MARK: - Type

public enum MessageType: String, Codable {
    case regular, ephemeral, error, reply, system
}
