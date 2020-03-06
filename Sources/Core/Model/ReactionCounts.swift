//
//  ReactionCounts.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 04/03/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

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
            if let reactionType = ReactionType(named: key) {
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
    
    /// Init a reaction counts with dictionary counts.
    /// - Parameter counts: a rection counts by reaction types.
    public init(counts: [ReactionType: Int]) {
        self.counts = counts
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
        
        Client.shared.reactionTypes.forEach { type in
            if countKeys.contains(type) {
                emoji += type.emoji
            }
        }
        
        return emoji.appending(count.shortString())
    }
    
    mutating func update(type: ReactionType, increment: Int) {
        let count = increment + (counts[type] ?? 0)
        
        if count <= 0 { // swiftlint:disable:this empty_count
            counts.removeValue(forKey: type)
        } else {
            counts[type] = count
        }
        
        string = joinToString()
    }
}
