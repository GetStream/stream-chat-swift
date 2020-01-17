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
    /// - Parameter completion: a completion block with `MessageResponse`.
    func delete(_ completion: @escaping Client.Completion<MessageResponse>) {
        return rx.delete().bindOnce(to: completion)
    }
    
    /// Add a reaction to the message.
    /// - Parameters:
    ///   - reactionType: a reaction type, e.g. like.
    ///   - completion: a completion block with `MessageResponse`.
    func addReaction(_ reactionType: ReactionType, _ completion: @escaping Client.Completion<MessageResponse>) {
        return rx.addReaction(reactionType).bindOnce(to: completion)
    }
    
    /// Delete a reaction to the message.
    /// - Parameters:
    ///   - reactionType: a reaction type, e.g. like.
    ///   - completion: a completion block with `MessageResponse`.
    func deleteReaction(_ reactionType: ReactionType,
                        _ completion: @escaping Client.Completion<MessageResponse>) {
        return rx.deleteReaction(reactionType).bindOnce(to: completion)
    }
    
    /// Send a request for reply messages.
    /// - Parameters:
    ///   - pagination: a pagination (see `Pagination`).
    ///   - completion: a completion block with `[Message]`.
    func replies(pagination: Pagination, _ completion: @escaping Client.Completion<[Message]>) {
        return rx.replies(pagination: pagination).bindOnce(to: completion)
    }
    
    /// Flag a message.
    /// - Parameter completion: a completion block with `FlagMessageResponse`.
    func flag(_ completion: @escaping Client.Completion<FlagMessageResponse>) {
        return rx.flag().bindOnce(to: completion)
    }
    
    /// Unflag a message.
    /// - Parameter completion: a completion block with `FlagMessageResponse`.
    func unflag(_ completion: @escaping Client.Completion<FlagMessageResponse>) {
        return rx.unflag().bindOnce(to: completion)
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
