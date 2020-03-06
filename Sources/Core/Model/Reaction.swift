//
//  Reaction.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 23/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

/// A reaction for a message.
public struct Reaction: Codable, Equatable {
    private enum CodingKeys: String, CodingKey {
        case type
        case score
        case user
        case messageId = "message_id"
        case created = "created_at"
    }
    
    /// A reaction type.
    public let type: ReactionType
    /// A score.
    public let score: Int
    /// A message id.
    public let messageId: String
    /// A user of the reaction.
    public let user: User?
    /// A created date.
    public let created: Date
    
    /// Check if the reaction if by the current user.
    public var isOwn: Bool {
        return user?.isCurrent ?? false
    }
    
    /// Init a reaction.
    /// - Parameters:
    ///   - type: a reaction type.
    ///   - messageId: a message id.
    ///   - user: a user owner of the reaction.
    ///   - created: a created date.
    public init(type: ReactionType, score: Int = 1, messageId: String, user: User? = .current, created: Date = Date()) {
        self.type = type
        self.score = score
        self.messageId = messageId
        self.user = user
        self.created = created
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(score, forKey: .score)
    }
}
