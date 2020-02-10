//
//  Message+Requests.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 30/07/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChatClient
import RxSwift

// MARK: Message Requests

extension Message: ReactiveCompatible {}

public extension Reactive where Base == Message {
    
    /// Delete the message.
    func delete() -> Observable<MessageResponse> {
        Client.shared.rx.delete(message: base)
    }
    
    /// Send a request for reply messages.
    /// - Parameter pagination: a pagination (see `Pagination`).
    func replies(pagination: Pagination) -> Observable<[Message]> {
        Client.shared.rx.replies(for: base, pagination: pagination)
    }
    
    // MARK: - Reactions
    
    /// Add a reaction to the message.
    /// - Parameter reactionType: a reaction type, e.g. like.
    func addReaction(reactionType: ReactionType) -> Observable<MessageResponse> {
        Client.shared.rx.addReaction(to: base, reactionType: reactionType)
    }
    
    /// Delete a reaction to the message.
    /// - Parameter reactionType: a reaction type, e.g. like.
    func deleteReaction(reactionType: ReactionType) -> Observable<MessageResponse> {
        Client.shared.rx.deleteReaction(from: base, reactionType: reactionType)
    }
    
    // MARK: Flag Message
    
    /// Flag a message.
    func flag() -> Observable<FlagMessageResponse> {
        Client.shared.rx.flag(message: base)
    }
    
    /// Unflag a message.
    func unflag() -> Observable<FlagMessageResponse> {
        Client.shared.rx.unflag(message: base)
    }
}
