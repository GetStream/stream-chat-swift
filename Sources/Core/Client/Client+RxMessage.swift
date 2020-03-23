//
//  Client+RxMessage.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 06/02/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChatClient
import RxSwift

// MARK: Message Requests

public extension Reactive where Base == Client {
    
    /// Get a message by id.
    /// - Parameters:
    ///   - messageId: a message id.
    func message(withId messageId: String) -> Observable<MessageResponse> {
        connected(request({ [unowned base] completion in
            base.message(withId: messageId, completion)
        }))
    }
    
    /// Mark all messages as read.
    func markAllRead() -> Observable<EmptyData> {
        connected(request({ [unowned base] completion in
            base.markAllRead(completion)
        }))
    }
    
    /// Delete the message.
    /// - Parameters:
    ///   - message: a message for deleting.
    func delete(message: Message) -> Observable<MessageResponse> {
        connected(request({ [unowned base] completion in
            base.delete(message: message, completion)
        }))
    }
    
    /// Send a request for reply messages.
    /// - Parameters:
    ///   - message: a message.
    ///   - pagination: a pagination (see `Pagination`).
    func replies(for message: Message, pagination: Pagination) -> Observable<[Message]> {
        connected(request({ [unowned base] completion in
            base.replies(for: message, pagination: pagination, completion)
        }))
    }
    
    // MARK: - Reactions
    
    /// Add a reaction to the message.
    /// - Parameters:
    ///   - type: a reaction type, e.g. like.
    ///   - score: a score.
    ///   - extraData: an extra data for the reaction.
    ///   - message: a message.
    func addReaction(type: String,
                     score: Int = 1,
                     extraData: Codable? = nil,
                     to message: Message) -> Observable<MessageResponse> {
        connected(request({ [unowned base] completion in
            base.addReaction(type: type, score: score, extraData: extraData, to: message, completion)
        }))
    }
    
    /// Delete a reaction to the message.
    /// - Parameters:
    ///   - type: a reaction type, e.g. like.
    ///   - message: a message.
    func deleteReaction(type: String, from message: Message) -> Observable<MessageResponse> {
        connected(request({ [unowned base] completion in
            base.deleteReaction(type: type, from: message, completion)
        }))
    }
    
    // MARK: Flag Message
    
    /// Flag a message.
    /// - Parameters:
    ///   - message: a message.
    func flag(message: Message) -> Observable<FlagMessageResponse> {
        connected(request({ [unowned base] completion in
            base.flag(message: message, completion)
        }))
    }
    
    /// Unflag a message.
    /// - Parameters:
    ///   - message: a message.
    func unflag(message: Message) -> Observable<FlagMessageResponse> {
        connected(request({ [unowned base] completion in
            base.unflag(message: message, completion)
        }))
    }
}
