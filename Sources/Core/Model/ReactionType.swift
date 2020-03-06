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
    public var name: String {
        switch self {
        case .regular(let name, emoji: _),
             .cumulative(let name, maxCount: _, emoji: _):
            return name
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
    
    /// Create a reaction type based on string type value.
    /// - Parameter name: reaction type.
    public init?(named name: String) {
        for registeredType in Client.shared.reactionTypes {
            if case .regular(let regularName, emoji: _) = registeredType, regularName == name {
                self = registeredType
                return
            }
            
            if case .cumulative(let cumulativeName, maxCount: _, emoji: _) = registeredType, cumulativeName == name {
                self = registeredType
                return
            }
        }
        
        return nil
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let name = (try? container.decode(String.self)) ?? ""
        
        if let type = ReactionType(named: name) {
            self = type
        } else {
            throw ClientError.invalidReactionType(name)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(name)
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
