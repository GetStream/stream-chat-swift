//
//  Reaction.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 23/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

/// A reaction for a message.
public struct Reaction: Codable {
    private enum CodingKeys: String, CodingKey {
        case type
        case score
        case user
        case messageId = "message_id"
        case created = "created_at"
    }
    
    /// A custom extra data type for reactions.
    /// - Note: Use this variable to setup your own extra data type for decoding reactions custom fields from JSON data.
    public static var extraDataType: Codable.Type?
    
    /// A reaction type.
    public let type: String
    /// A score.
    public let score: Int
    /// A message id.
    public let messageId: String
    /// A user of the reaction.
    public let user: User?
    /// A created date.
    public let created: Date
    /// An extra data for the reaction.
    public let extraData: Codable?
    
    /// Check if the reaction is from the current user.
    public var isOwn: Bool { user?.isCurrent ?? false }
    
    /// Init a reaction.
    /// - Parameters:
    ///   - type: a reaction type.
    ///   - score: a reaction score, e.g. `.cumulative` it could be more then 1.
    ///   - messageId: a message id.
    ///   - extraData: an extra data.
    ///   - user: a user of the reaction.
    ///   - created: a created date.
    public init(type: String,
                score: Int = 1,
                messageId: String,
                extraData: Codable? = nil,
                user: User? = .current,
                created: Date = Date()) {
        self.type = type
        self.score = score
        self.messageId = messageId
        self.user = user
        self.created = created
        self.extraData = extraData
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)
        score = try container.decode(Int.self, forKey: .score)
        messageId = try container.decode(String.self, forKey: .messageId)
        user = try container.decodeIfPresent(User.self, forKey: .user)
        created = try container.decode(Date.self, forKey: .created)
        extraData = try? Self.extraDataType?.init(from: decoder) // swiftlint:disable:this explicit_init
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(score, forKey: .score)
        extraData?.encodeSafely(to: encoder, logMessage: "📦 when encoding a reaction extra data")
    }
}

extension Reaction: Equatable {
    public static func == (lhs: Reaction, rhs: Reaction) -> Bool {
        return lhs.type == rhs.type
            && lhs.score == rhs.score
            && lhs.messageId == rhs.messageId
            && lhs.user == rhs.user
            && lhs.created == rhs.created
    }
}
