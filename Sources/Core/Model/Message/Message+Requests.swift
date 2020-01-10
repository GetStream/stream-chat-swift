//
//  Message+Requests.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 10/01/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

public extension Message {
    
    /// Delete the message.
    /// - Returns: an observable message response.
    func delete(_ completion: @escaping ClientCompletion<MessageResponse>) -> Subscription {
        return rx.delete().bind(to: completion)
    }
    
    /// Add a reaction to the message.
    /// - Parameter reactionType: a reaction type, e.g. like.
    /// - Returns: an observable message response.
    func addReaction(_ reactionType: ReactionType, _ completion: @escaping ClientCompletion<MessageResponse>) -> Subscription {
        return rx.addReaction(reactionType).bind(to: completion)
    }
    
    /// Delete a reaction to the message.
    /// - Parameter reactionType: a reaction type, e.g. like.
    /// - Returns: an observable message response.
    func deleteReaction(_ reactionType: ReactionType,
                        _ completion: @escaping ClientCompletion<MessageResponse>) -> Subscription {
        return rx.deleteReaction(reactionType).bind(to: completion)
    }
    
    /// Send a request for reply messages.
    /// - Parameter pagination: a pagination (see `Pagination`).
    /// - Returns: an observable message response.
    func replies(pagination: Pagination, _ completion: @escaping ClientCompletion<[Message]>) -> Subscription {
        return rx.replies(pagination: pagination).bind(to: completion)
    }
    
    /// Flag a message.
    /// - Returns: an observable flag message response.
    func flag(_ completion: @escaping ClientCompletion<FlagMessageResponse>) -> Subscription {
        return rx.flag().bind(to: completion)
    }
    
    /// Unflag a message.
    /// - Returns: an observable flag message response.
    func unflag(_ completion: @escaping ClientCompletion<FlagMessageResponse>) -> Subscription {
        return rx.unflag().bind(to: completion)
    }
}

// MARK: - Supporting structs

/// A messages response.
public struct MessagesResponse: Decodable {
    /// A list of messages.
    let messages: [Message]
}

struct FlagResponse<T: Decodable>: Decodable {
    let flag: T
}

/// A flag message response.
public struct FlagMessageResponse: Decodable {
    private enum CodingKeys: String, CodingKey {
        case messageId = "target_message_id"
        case created = "created_at"
        case updated = "updated_at"
    }
    
    /// A flagged message id.
    public let messageId: String
    /// A created date.
    public let created: Date
    /// A updated date.
    public let updated: Date
}

/// A flag message response.
public struct FlagUserResponse: Decodable {
    private enum CodingKeys: String, CodingKey {
        case user = "target_user"
        case created = "created_at"
        case updated = "updated_at"
    }
    
    /// A flagged user.
    public let user: User
    /// A created date.
    public let created: Date
    /// A updated date.
    public let updated: Date
}
