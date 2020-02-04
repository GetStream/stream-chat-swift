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
    @discardableResult
    func delete(_ completion: @escaping Client.Completion<MessageResponse>) -> URLSessionTask {
        Client.shared.delete(message: self, completion)
    }
    
    /// Send a request for reply messages.
    /// - Parameters:
    ///   - pagination: a pagination (see `Pagination`).
    ///   - completion: a completion block with `[Message]`.
    @discardableResult
    func replies(pagination: Pagination, _ completion: @escaping Client.Completion<[Message]>) -> URLSessionTask {
        Client.shared.replies(for: self, pagination: pagination, completion)
    }
    
    // MARK: - Reactions
    
    /// Add a reaction to the message.
    /// - Parameters:
    ///   - reactionType: a reaction type, e.g. like.
    ///   - completion: a completion block with `MessageResponse`.
    @discardableResult
    func addReaction(_ reactionType: ReactionType, _ completion: @escaping Client.Completion<MessageResponse>) -> URLSessionTask {
        Client.shared.addReaction(to: self, reactionType: reactionType, completion)
    }
    
    /// Delete a reaction to the message.
    /// - Parameters:
    ///   - reactionType: a reaction type, e.g. like.
    ///   - completion: a completion block with `MessageResponse`.
    @discardableResult
    func deleteReaction(_ reactionType: ReactionType,
                        _ completion: @escaping Client.Completion<MessageResponse>) -> URLSessionTask {
        Client.shared.deleteReaction(from: self, reactionType: reactionType, completion)
    }
    
    // MARK: Flag Message
    
    /// Flag a message.
    /// - Parameter completion: a completion block with `FlagMessageResponse`.
    @discardableResult
    func flag(_ completion: @escaping Client.Completion<FlagMessageResponse>) -> URLSessionTask {
        Client.shared.flag(message: self, completion)
    }
    
    /// Unflag a message.
    /// - Parameter completion: a completion block with `FlagMessageResponse`.
    @discardableResult
    func unflag(_ completion: @escaping Client.Completion<FlagMessageResponse>) -> URLSessionTask {
        Client.shared.unflag(message: self, completion)
    }
}
