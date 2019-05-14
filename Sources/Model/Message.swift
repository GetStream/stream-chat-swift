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
        case mentionedUsers = "mentioned_users"
        case replyCount = "reply_count"
        case latestReactions = "latest_reactions"
        case ownReactions = "own_reactions"
        case reactionCounts = "reaction_counts"
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
    public let mentionedUsers: [User]
    public let replyCount: Int
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
    
    init?(text: String) {
        guard let user = Client.shared.user else {
            return nil
        }
        
        id = ""
        type = .regular
        self.user = user
        created = Date()
        updated = Date()
        deleted = nil
        self.text = text
        command = nil
        args = nil
        attachments = []
        mentionedUsers = []
        replyCount = 0
        latestReactions = []
        ownReactions = []
        reactionCounts = nil
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(text, forKey: .text)
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
    
    mutating func addToOwnReactions(_ reaction: Reaction) {
        if let index = latestReactions.firstIndex(where: { $0.type == reaction.type }) {
            latestReactions[index] = reaction
        } else {
            latestReactions.insert(reaction, at: 0)
        }
        
        if let index = ownReactions.firstIndex(where: { $0.type == reaction.type }) {
            ownReactions[index] = reaction
        } else {
            ownReactions.insert(reaction, at: 0)
        }
        
        if reactionCounts != nil {
            reactionCounts?.update(type: reaction.type, increment: 1)
        } else {
            reactionCounts = ReactionCounts(reactionType: reaction.type)
        }
    }

    mutating func deleteFromOwnReactions(_ reaction: Reaction) {
        if let index = latestReactions.firstIndex(where: { $0.type == reaction.type }) {
            latestReactions.remove(at: index)
        }
        
        if let index = ownReactions.firstIndex(where: { $0.type == reaction.type }) {
            ownReactions.remove(at: index)
        }
        
        reactionCounts?.update(type: reaction.type, increment: -1)
    }
}

public enum MessageType: String, Codable {
    case regular, ephemeral, error, reply, system
}
