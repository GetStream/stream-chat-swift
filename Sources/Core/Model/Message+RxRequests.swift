//
//  Message+Requests.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 30/07/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import RxSwift

extension Message: ReactiveCompatible {}

public extension Reactive where Base == Message {
    
    // MARK: Requests
    
    /// Delete the message.
    ///
    /// - Returns: an observable message response.
    func delete() -> Observable<MessageResponse> {
        return Client.shared.rx.connectedRequest(endpoint: .deleteMessage(base))
    }
    
    /// Add a reaction to the message.
    ///
    /// - Parameter reactionType: a reaction type, e.g. like.
    /// - Returns: an observable message response.
    func addReaction(_ reactionType: ReactionType) -> Observable<MessageResponse> {
        return Client.shared.rx.connectedRequest(endpoint: .addReaction(reactionType, base))
    }
    
    /// Delete a reaction to the message.
    ///
    /// - Parameter reactionType: a reaction type, e.g. like.
    /// - Returns: an observable message response.
    func deleteReaction(_ reactionType: ReactionType) -> Observable<MessageResponse> {
        return Client.shared.rx.connectedRequest(endpoint: .deleteReaction(reactionType, base))
    }
    
    /// Send a request for reply messages.
    ///
    /// - Parameter pagination: a pagination (see `Pagination`).
    /// - Returns: an observable message response.
    func replies(pagination: Pagination) -> Observable<[Message]> {
        return Client.shared.rx.connectedRequest(endpoint: .replies(base, pagination))
            .map { (response: MessagesResponse) in response.messages }
            .do(onNext: { self.base.add(repliesToDatabase: $0) })
    }
    
    // MARK: Flag Message
    
    /// Flag a message.
    /// - Returns: an observable flag message response.
    func flag() -> Observable<FlagMessageResponse> {
        guard !base.user.isCurrent else {
            return .empty()
        }
        
        let messageId = base.id
        return Client.shared.rx.connectedRequest(flagUnflagMessage(endpoint: .flagMessage(base))
            .do(onNext: { _ in Message.flaggedIds.insert(messageId) }))
    }
    
    /// Unflag a message.
    /// - Returns: an observable flag message response.
    func unflag() -> Observable<FlagMessageResponse> {
        guard !base.user.isCurrent else {
            return .empty()
        }
        
        let messageId = base.id
        
        return Client.shared.rx.connectedRequest(flagUnflagMessage(endpoint: .unflagMessage(base))
            .do(onNext: { _ in
                if let index = Message.flaggedIds.firstIndex(where: { $0 == messageId }) {
                    Message.flaggedIds.remove(at: index)
                }
            }))
    }
    
    private func flagUnflagMessage(endpoint: Endpoint) -> Observable<FlagMessageResponse> {
        let alreadyFlagged = FlagMessageResponse(messageId: base.id, created: Date(), updated: Date())
        return Client.shared.rx.flagUnflag(endpoint: endpoint, alreadyFlagged: alreadyFlagged)
    }
}
