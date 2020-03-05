//
//  ReactionType.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 04/03/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

/// A reaction type.
public enum ReactionType: Codable {
    
    /// A list of default reactions.
    public static let defaultTypes: [ReactionType] = [.regular("like", emoji: "👍"),
                                                      .regular("love", emoji: "❤️"),
                                                      .regular("haha", emoji: "😂"),
                                                      .regular("wow", emoji: "😲"),
                                                      .regular("sad", emoji: "😔"),
                                                      .regular("angry", emoji: "😠")]
    
    case regular(String, emoji: String)
    case cumulative(String, maxCount: Int, emoji: String)
    
    /// An reaction type as emoji.
    public var value: String {
        switch self {
        case .regular(let type, emoji: _),
             .cumulative(let type, maxCount: _, emoji: _):
            return type
        }
    }
    
    /// An reaction type as emoji.
    public var emoji: String {
        switch self {
        case .regular(_, emoji: let emoji),
             .cumulative(_, maxCount: _, emoji: let emoji):
            return emoji
        }
    }
    
    /// Checks if the reaction type is regular.
    public var isRegular: Bool {
        if case .regular = self {
            return true
        }
        
        return false
    }
    
    /// Checks if the reaction type is regular.
    public var maxCount: Int {
        if case .cumulative(_, maxCount: let count, emoji: _) = self {
            return max(1, count)
        }
        
        return 1
    }
    
    /// A list of reactions as emoji's.
    public static var emojies: [String] { Client.shared.reactionTypes.map { $0.emoji } }
    
    init?(_ type: String) {
        for registeredType in Client.shared.reactionTypes {
            if case .regular(let regularType, emoji: _) = registeredType, regularType == type {
                self = registeredType
                return
            }
            
            if case .cumulative(let cumulativeType, maxCount: _, emoji: _) = registeredType, cumulativeType == type {
                self = registeredType
                return
            }
        }
        
        return nil
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let type = (try? container.decode(String.self)) ?? ""
        
        if let type = ReactionType(type) {
            self = type
        } else {
            throw ClientError.invalidReactionType(type)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

// MARK: - Hashable

extension ReactionType: Hashable {
    
    public static func == (lhs: ReactionType, rhs: ReactionType) -> Bool {
        switch (lhs, rhs) {
        case (let .regular(type1, emoji1), let .regular(type2, emoji2)):
            return type1 == type2 && emoji1 == emoji2
        case (let .cumulative(type1, maxCount1, emoji1), let .cumulative(type2, maxCount2, emoji2)):
            return type1 == type2 && maxCount1 == maxCount2 && emoji1 == emoji2
        default:
            return false
        }
    }
    
    public func hash(into hasher: inout Hasher) {
        switch self {
        case let .regular(type, emoji: emoji):
            hasher.combine(type)
            hasher.combine(emoji)
        case let .cumulative(type, maxCount: maxCount, emoji: emoji):
            hasher.combine(type)
            hasher.combine(maxCount)
            hasher.combine(emoji)
        }
    }
}
