//
//  Reaction.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 23/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

// MARK: - Reaction

/// A reaction for a message.
public struct Reaction: Codable, Equatable {
    /// A list of reactions in emoji.
    public static let emoji = ["👍", "❤️", "😂", "😲", "😔", "😠"]
    /// A list of reation types.
    public static let emojiTypes = ["like", "love", "haha", "wow", "sad", "angry"]
    
    private enum CodingKeys: String, CodingKey {
        case type
        case user
        case messageId = "message_id"
        case created = "created_at"
    }
    
    /// A reaction type.
    public let type: String
    /// A user of the reaction.
    public let user: User?
    /// A created date.
    public let created: Date
    /// A message id.
    public let messageId: String
    
    /// Check if the reaction if by the current user.
    public var isOwn: Bool {
        return user?.isCurrent ?? false
    }
}

// MARK - Reaction Counts

/// A reaction counts.
public struct ReactionCounts: Decodable {
    /// Reaction counts by reaction types.
    public private(set) var counts: [String: Int]
    /// A joined reaction types and counts.
    public private(set) var string: String
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        counts = try container.decode([String: Int].self)
        string = ""
        string = joinToString()
    }
    
    /// Init a reaction counts with 1 for a given reaction type.
    init(reactionType: String) {
        counts = [reactionType: 1]
        
        if let index = Reaction.emojiTypes.firstIndex(of: reactionType) {
            string = "\(Reaction.emoji[index])1"
        } else {
            string = ""
        }
    }
    
    private func joinToString() -> String {
        let count = counts.values.reduce(0, { $0 + $1 })
        let countKeys = counts.keys
        var emoji = ""
        
        guard !counts.isEmpty else {
            return ""
        }
        
        Reaction.emojiTypes.enumerated().forEach { index, key in
            if countKeys.contains(key) {
                emoji += Reaction.emoji[index]
            }
        }
        
        return emoji.appending(count.shortString())
    }
    
    mutating func update(type: String, increment: Int) {
        let count = increment + (counts[type] ?? 0)
        
        if count <= 0 {
            counts.removeValue(forKey: type)
        } else {
            counts[type] = count
        }
        
        string = joinToString()
    }
}
