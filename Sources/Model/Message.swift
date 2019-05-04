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
    public let attachments: [Attachment]
    public let mentionedUsers: [User]
    public let replyCount: Int
    public let latestReactions: [Reaction]
    public let ownReactions: [Reaction]
    public let reactionCounts: ReactionCounts?
    
    public var isDeleted: Bool {
        return deleted != nil
    }
//
//    public var reactionsString: String? {
//        guard let reactionCounts = reactionCounts else {
//            return nil
//        }
//
//        return
//    }
    
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

public enum MessageType: String, Codable {
    case regular, ephemeral, error, reply, system
}
