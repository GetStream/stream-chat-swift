//
//  Reaction.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 23/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

// MARK: - Reaction

public struct Reaction: Codable {
    static let emoji = ["👍", "❤️", "😂", "😲", "😔", "😠"]
    static let emojiKeys = ["like", "love", "haha", "wow", "sad", "angry"]
    
    private enum CodingKeys: String, CodingKey {
        case type
        case user
        case messageId = "message_id"
        case created = "created_at"
    }
    
    public let type: String
    public let user: User?
    public let created: Date
    public let messageId: String
    
    public var emoji: String {
        guard let index = Reaction.emojiKeys.firstIndex(of: type) else {
            return type
        }
        
        return Reaction.emoji[index]
    }
}

// MARK - Reaction Counts

public struct ReactionCounts: Decodable {
    let counts: [String: Int]
    let string: String
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        counts = try container.decode([String: Int].self)
        let count = counts.values.reduce(0, { $0 + $1 })
        let countKeys = counts.keys
        var emoji = ""
        
        guard !counts.isEmpty else {
            string = ""
            return
        }
        
        Reaction.emojiKeys.enumerated().forEach { index, key in
            if countKeys.contains(key) {
                emoji += Reaction.emoji[index]
            }
        }
        
        string = emoji.appending(String(count))
    }
}
