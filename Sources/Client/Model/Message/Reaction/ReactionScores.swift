//
//  ReactionCounts.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 04/03/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

/// A reaction counts.
public struct ReactionScores: Decodable {
    /// Reaction counts by reaction types.
    public private(set) var scores: [ReactionType: Int]
    
    /// A joined reaction types and counts.
    public private(set) var string: String
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        string = ""
        let rawCounts = try container.decode([String: Int].self)
        var scores = [ReactionType: Int]()
        
        rawCounts.forEach { key, count in
            if let reactionType = ReactionType(named: key) {
                scores[reactionType] = count
            }
        }
        
        self.scores = scores
        string = joinToString()
    }
    
    /// Init a reaction counts with 1 for a given reaction type.
    init(reactionType: ReactionType) {
        scores = [reactionType: 1]
        string = ""
        string = joinToString()
    }
    
    /// Init a reaction counts with dictionary counts.
    /// - Parameter scores: a rection sccores by reaction types.
    public init(scores: [ReactionType: Int]) {
        self.scores = scores
        string = ""
        string = joinToString()
    }
    
    private func joinToString() -> String {
        guard !scores.isEmpty else {
            return ""
        }
        
        let score = scores.values.reduce(0, { $0 + $1 })
        let scoreKeys = scores.keys
        var emoji = ""
        
        Client.shared.reactionTypes.forEach { type in
            if scoreKeys.contains(type) {
                emoji += type.emoji
            }
        }
        
        return emoji.appending(score.shortString())
    }
    
    mutating func update(type: ReactionType, increment: Int) {
        let count = increment + (scores[type] ?? 0)
        
        if count <= 0 { // swiftlint:disable:this empty_count
            scores.removeValue(forKey: type)
        } else {
            scores[type] = count
        }
        
        string = joinToString()
    }
}
