//
//  Client+Message.swift
//  StreamChatClient
//
//  Created by Alexey Bukhtin on 04/02/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

// MARK: Message Requests

public extension Client {
    
    /// Get a message by id.
    /// - Parameters:
    ///   - messageId: a message id.
    ///   - completion: a completion block with `MessageResponse`.
    @discardableResult
    func message(withId messageId: String, _ completion: @escaping Client.Completion<MessageResponse>) -> Cancellable {
        request(endpoint: .message(messageId), completion)
    }
    
    /// Mark all messages as read.
    /// - Parameter completion: an empty completion block.
    @discardableResult
    func markAllRead(_ completion: @escaping Client.Completion<EmptyData> = { _ in }) -> Cancellable {
        request(endpoint: .markAllRead, completion)
    }
    
    /// Delete the message.
    /// - Parameters:
    ///   - message: a message for deleting.
    ///   - completion: a completion block with `MessageResponse`.
    @discardableResult
    func delete(message: Message, _ completion: @escaping Client.Completion<MessageResponse>) -> Cancellable {
        request(endpoint: .deleteMessage(message), completion)
    }
    
    /// Send a request for reply messages.
    /// - Parameters:
    ///   - message: a message.
    ///   - pagination: a pagination (see `Pagination`).
    ///   - completion: a completion block with `[Message]`.
    @discardableResult
    func replies(for message: Message,
                 pagination: Pagination,
                 _ completion: @escaping Client.Completion<[Message]>) -> Cancellable {
        request(endpoint: .replies(message, pagination)) { (result: Result<MessagesResponse, ClientError>) in
            completion(result.map(to: \.messages))
        }
    }
    
    // MARK: - Reactions
    
    /// Add a reaction to the message.
    /// - Parameters:
    ///   - type: a reaction type, e.g. like.
    ///   - score: a score.
    ///   - extraData: an extra data for the reaction.
    ///   - message: a message.
    ///   - completion: a completion block with `MessageResponse`.
    @discardableResult
    func addReaction(type: String,
                     score: Int = 1,
                     extraData: Codable? = nil,
                     to message: Message,
                     _ completion: @escaping Client.Completion<MessageResponse>) -> Cancellable {
        let reaction = Reaction(type: type, score: score, messageId: message.id, extraData: extraData)
        return request(endpoint: .addReaction(reaction), completion)
    }
    
    /// Delete a reaction to the message.
    /// - Parameters:
    ///   - type: a reaction type, e.g. like.
    ///   - message: a message.
    ///   - completion: a completion block with `MessageResponse`.
    @discardableResult
    func deleteReaction(type: String,
                        from message: Message,
                        _ completion: @escaping Client.Completion<MessageResponse>) -> Cancellable {
        request(endpoint: .deleteReaction(type, message), completion)
    }
    
    // MARK: Flag Message
    
    /// Flag a message.
    /// - Parameters:
    ///   - message: a message.
    ///   - completion: a completion block with `FlagMessageResponse`.
    @discardableResult
    func flag(message: Message, _ completion: @escaping Client.Completion<FlagMessageResponse>) -> Cancellable {
        if message.id.isEmpty {
            completion(.failure(.emptyMessageId))
            return Subscription.empty
        }
        
        if message.user.isCurrent {
            completion(.success(.init(messageId: message.id, created: Date(), updated: Date())))
            return Subscription.empty
        }
        
        let completion = doAfter(completion) { _ in
            Message.flaggedIds.insert(message.id)
        }
        
        return toggleFlagMessage(message, endpoint: .flagMessage(message), completion)
    }
    
    /// Unflag a message.
    /// - Parameters:
    ///   - message: a message.
    ///   - completion: a completion block with `FlagMessageResponse`.
    @discardableResult
    func unflag(message: Message, _ completion: @escaping Client.Completion<FlagMessageResponse>) -> Cancellable {
        if message.id.isEmpty {
            completion(.failure(.emptyMessageId))
            return Subscription.empty
        }
        
        if message.user.isCurrent {
            completion(.success(.init(messageId: message.id, created: Date(), updated: Date())))
            return Subscription.empty
        }
        
        let completion = doAfter(completion) { _ in
            Message.flaggedIds.remove(message.id)
        }
        
        return toggleFlagMessage(message, endpoint: .unflagMessage(message), completion)
    }
    
    private func toggleFlagMessage(_ message: Message,
                                   endpoint: Endpoint,
                                   _ completion: @escaping Client.Completion<FlagMessageResponse>) -> Cancellable {
        request(endpoint: endpoint) { (result: Result<FlagResponse<FlagMessageResponse>, ClientError>) in
            let result = result.catchError { error in
                if case .responseError(let clientResponseError) = error,
                    clientResponseError.message.contains("flag already exists") {
                    let flagMessageResponse = FlagMessageResponse(messageId: message.id, created: Date(), updated: Date())
                    return .success(FlagResponse(flag: flagMessageResponse))
                }
                
                return .failure(error)
            }
            
            completion(result.map(to: \.flag))
        }
    }
}
