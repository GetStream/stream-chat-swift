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
    func message(with messageId: String) -> Observable<MessageResponse> {
        connected(request({ [unowned base] completion in
            base.message(with: messageId, completion)
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
    ///   - message: a message.
    ///   - reactionType: a reaction type, e.g. like.
    func addReaction(to message: Message, reactionType: ReactionType) -> Observable<MessageResponse> {
        connected(request({ [unowned base] completion in
            base.addReaction(to: message, reactionType: reactionType, completion)
        }))
    }
    
    /// Delete a reaction to the message.
    /// - Parameters:
    ///   - message: a message.
    ///   - reactionType: a reaction type, e.g. like.
    func deleteReaction(from message: Message, reactionType: ReactionType) -> Observable<MessageResponse> {
        connected(request({ [unowned base] completion in
            base.deleteReaction(from: message, reactionType: reactionType, completion)
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
