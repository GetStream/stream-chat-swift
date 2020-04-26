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
    func delete(_ completion: @escaping Client.Completion<MessageResponse>) -> Cancellable {
        Client.shared.delete(message: self, completion)
    }
    
    /// Send a request for reply messages.
    /// - Parameters:
    ///   - pagination: a pagination (see `Pagination`).
    ///   - completion: a completion block with `[Message]`.
    @discardableResult
    func replies(pagination: Pagination, _ completion: @escaping Client.Completion<[Message]>) -> Cancellable {
        Client.shared.replies(for: self, pagination: pagination, completion)
    }
    
    // MARK: - Reactions
    
    /// Add a reaction to the message.
    /// - Parameters:
    ///   - type: a reaction type, e.g. like.
    ///   - completion: a completion block with `MessageResponse`.
    @discardableResult
    func addReaction(type: String,
                     score: Int,
                     extraData: Codable? = nil,
                     _ completion: @escaping Client.Completion<MessageResponse>) -> Cancellable {
        Client.shared.addReaction(type: type, score: score, extraData: extraData, to: self, completion)
    }
    
    /// Delete a reaction to the message.
    /// - Parameters:
    ///   - type: a reaction type, e.g. like.
    ///   - completion: a completion block with `MessageResponse`.
    @discardableResult
    func deleteReaction(type: String, _ completion: @escaping Client.Completion<MessageResponse>) -> Cancellable {
        Client.shared.deleteReaction(type: type, from: self, completion)
    }
    
    // MARK: Flag Message
    
    /// Flag a message.
    /// - Parameter completion: a completion block with `FlagMessageResponse`.
    @discardableResult
    func flag(_ completion: @escaping Client.Completion<FlagMessageResponse>) -> Cancellable {
        Client.shared.flag(message: self, completion)
    }
    
    /// Unflag a message.
    /// - Parameter completion: a completion block with `FlagMessageResponse`.
    @discardableResult
    func unflag(_ completion: @escaping Client.Completion<FlagMessageResponse>) -> Cancellable {
        Client.shared.unflag(message: self, completion)
    }
}
