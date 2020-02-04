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
    func message(with messageId: String, _ completion: @escaping Client.Completion<MessageResponse>) -> URLSessionTask {
        request(endpoint: .message(messageId), completion)
    }
    
    /// Mark all messages as read.
    /// - Parameter completion: an empty completion block.
    @discardableResult
    func markAllRead(_ completion: @escaping Client.Completion<EmptyData> = { _ in }) -> URLSessionTask {
        request(endpoint: .markAllRead, completion)
    }
    
    /// Delete the message.
    /// - Parameters:
    ///   - message: a message for deleting.
    ///   - completion: a completion block with `MessageResponse`.
    @discardableResult
    func delete(message: Message, _ completion: @escaping Client.Completion<MessageResponse>) -> URLSessionTask {
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
                 _ completion: @escaping Client.Completion<[Message]>) -> URLSessionTask {
        return request(endpoint: .replies(message, pagination)) { (result: Result<MessagesResponse, ClientError>) in
            completion(result.map(to: \.messages))
        }
    }
    
    // MARK: - Reactions
    
    /// Add a reaction to the message.
    /// - Parameters:
    ///   - message: a message.
    ///   - reactionType: a reaction type, e.g. like.
    ///   - completion: a completion block with `MessageResponse`.
    @discardableResult
    func addReaction(to message: Message,
                     reactionType: ReactionType,
                     _ completion: @escaping Client.Completion<MessageResponse>) -> URLSessionTask {
        request(endpoint: .addReaction(reactionType, message), completion)
    }
    
    /// Delete a reaction to the message.
    /// - Parameters:
    ///   - message: a message.
    ///   - reactionType: a reaction type, e.g. like.
    ///   - completion: a completion block with `MessageResponse`.
    @discardableResult
    func deleteReaction(from message: Message,
                        reactionType: ReactionType,
                        _ completion: @escaping Client.Completion<MessageResponse>) -> URLSessionTask {
        request(endpoint: .deleteReaction(reactionType, message), completion)
    }
    
    // MARK: Flag Message
    
    /// Flag a message.
    /// - Parameters:
    ///   - message: a message.
    ///   - completion: a completion block with `FlagMessageResponse`.
    @discardableResult
    func flag(message: Message, _ completion: @escaping Client.Completion<FlagMessageResponse>) -> URLSessionTask {
        if message.id.isEmpty {
            completion(.failure(.emptyMessageId))
            return .empty
        }
        
        if user.isCurrent {
            completion(.success(.init(messageId: message.id, created: Date(), updated: Date())))
            return .empty
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
    func unflag(message: Message, _ completion: @escaping Client.Completion<FlagMessageResponse>) -> URLSessionTask {
        if message.id.isEmpty {
            completion(.failure(.emptyMessageId))
            return .empty
        }
        
        if user.isCurrent {
            completion(.success(.init(messageId: message.id, created: Date(), updated: Date())))
            return .empty
        }
        
        let completion = doAfter(completion) { _ in
            if let index = Message.flaggedIds.firstIndex(where: { $0 == message.id }) {
                Message.flaggedIds.remove(at: index)
            }
        }
        
        return toggleFlagMessage(message, endpoint: .unflagMessage(message), completion)
    }
    
    private func toggleFlagMessage(_ message: Message,
                                    endpoint: Endpoint,
                                    _ completion: @escaping Client.Completion<FlagMessageResponse>) -> URLSessionTask {
        request(endpoint: endpoint) { (result: Result<FlagMessageResponse, ClientError>) in
            let result = result.catchError { error in
                if case .responseError(let clientResponseError) = error,
                    clientResponseError.message.contains("flag already exists") {
                    return .success(.init(messageId: message.id, created: Date(), updated: Date()))
                }
                
                return .failure(error)
            }
            
            completion(result)
        }
    }
}
