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
    /// - Parameters:
    ///   - type: a reaction type, e.g. like.
    ///   - score: a score.
    ///   - extraData: an extra data for the reaction.
    func addReaction(type: String, score: Int = 1, extraData: Codable? = nil) -> Observable<MessageResponse> {
        Client.shared.rx.addReaction(type: type, score: score, extraData: extraData, to: base)
    }
    
    /// Delete a reaction to the message.
    /// - Parameter type: a reaction type, e.g. like.
    func deleteReaction(type: String) -> Observable<MessageResponse> {
        Client.shared.rx.deleteReaction(type: type, from: base)
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
