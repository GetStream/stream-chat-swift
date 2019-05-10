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
    static let emojiTypes = ["like", "love", "haha", "wow", "sad", "angry"]
    
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
    
    public var isOwn: Bool {
        if let user = user, let currentUser = Client.shared.user, user == currentUser {
            return true
        }
        
        return false
    }
}

// MARK - Reaction Counts

public struct ReactionCounts: Decodable {
    private(set) var counts: [String: Int]
    private(set) var string: String
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        counts = try container.decode([String: Int].self)
        string = ""
        string = joinToString()
    }
    
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
