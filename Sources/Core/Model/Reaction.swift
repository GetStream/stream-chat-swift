//
//  Reaction.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 23/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

// MARK: - Reaction

/// A reaction type.
public enum ReactionType: String, Codable, Hashable, CaseIterable {
    /// A like reaction 👍.
    case like
    /// A love reaction ❤️.
    case love
    /// A haha reaction 😂.
    case haha
    /// A wow reaction 😲.
    case wow
    /// A sad reaction 😔.
    case sad
    /// A angry reaction 😠.
    case angry
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let value = try? container.decode(String.self),
            let type = ReactionType(rawValue: value) {
            self = type
        } else {
            self = .like
        }
    }
    
    /// An reaction type as emoji.
    public var emoji: String {
        switch self {
        case .like: return "👍"
        case .love: return "❤️"
        case .haha: return "😂"
        case .wow: return "😲"
        case .sad: return "😔"
        case .angry: return "😠"
        }
    }
    
    /// A list of reactions as emoji's.
    public static var emojies: [String] {
        return ReactionType.allCases.map { $0.emoji }
    }
}

/// A reaction for a message.
public struct Reaction: Codable, Equatable {
    
    private enum CodingKeys: String, CodingKey {
        case type
        case user
        case messageId = "message_id"
        case created = "created_at"
    }
    
    /// A reaction type.
    public let type: ReactionType
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
    public private(set) var counts: [ReactionType: Int]
    
    /// A joined reaction types and counts.
    public private(set) var string: String
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        string = ""
        let rawCounts = try container.decode([String: Int].self)
        var counts = [ReactionType: Int]()
        
        rawCounts.forEach { key, count in
            if let reactionType = ReactionType(rawValue: key) {
                counts[reactionType] = count
            }
        }
        
        self.counts = counts
        string = joinToString()
    }
    
    /// Init a reaction counts with 1 for a given reaction type.
    init(reactionType: ReactionType) {
        counts = [reactionType: 1]
        string = ""
        string = joinToString()
    }
    
    private func joinToString() -> String {
        guard !counts.isEmpty else {
            return ""
        }
        
        let count = counts.values.reduce(0, { $0 + $1 })
        let countKeys = counts.keys
        var emoji = ""
        
        ReactionType.allCases.forEach { type in
            if countKeys.contains(type) {
                emoji += type.emoji
            }
        }
        
        return emoji.appending(count.shortString())
    }
    
    mutating func update(type: ReactionType, increment: Int) {
        let count = increment + (counts[type] ?? 0)
        
        if count <= 0 {
            counts.removeValue(forKey: type)
        } else {
            counts[type] = count
        }
        
        string = joinToString()
    }
}
