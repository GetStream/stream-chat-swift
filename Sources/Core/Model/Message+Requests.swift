//
//  Message+Requests.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 30/07/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import RxSwift

// MARK: - Requests

public extension Message {
    
    private static var flaggedIds = [String]()
    
    /// Delete the message.
    ///
    /// - Returns: an observable message response.
    func delete() -> Observable<MessageResponse> {
        return Client.shared.rx.connectedRequest(endpoint: .deleteMessage(self))
    }
    
    /// Add a reaction to the message.
    ///
    /// - Parameter reactionType: a reaction type, e.g. like.
    /// - Returns: an observable message response.
    func addReaction(_ reactionType: ReactionType) -> Observable<MessageResponse> {
        return Client.shared.rx.connectedRequest(endpoint: .addReaction(reactionType, self))
    }
    
    /// Delete a reaction to the message.
    ///
    /// - Parameter reactionType: a reaction type, e.g. like.
    /// - Returns: an observable message response.
    func deleteReaction(_ reactionType: ReactionType) -> Observable<MessageResponse> {
        return Client.shared.rx.connectedRequest(endpoint: .deleteReaction(reactionType, self))
    }
    
    /// Send a request for reply messages.
    ///
    /// - Parameter pagination: a pagination (see `Pagination`).
    /// - Returns: an observable message response.
    func replies(pagination: Pagination) -> Observable<[Message]> {
        return Client.shared.rx.connectedRequest(endpoint: .replies(self, pagination))
            .map { (response: MessagesResponse) -> [Message] in response.messages }
            .do(onNext: { Client.shared.database?.add(replies: $0, for: self) })
    }
    
    /// Fetch a reply messages from a database.
    ///
    /// - Parameter pagination: a pagination (see `Pagination`).
    /// - Returns: an observable message response.
    func fetchReplies(pagination: Pagination) -> Observable<[Message]> {
        return Client.shared.database?.replies(for: self, pagination: pagination) ?? .empty()
    }
    
    /// Flag a message.
    ///
    /// - Returns: an observable flag message response.
    func flag() -> Observable<FlagMessageResponse> {
        guard !user.isCurrent else {
            return .empty()
        }
        
        let messageId = id
        return Client.shared.connectedRequest(flagUnflagMessage(endpoint: .flagMessage(self))
            .do(onNext: { _ in Message.flaggedIds.append(messageId) }))
    }
    
    /// Unflag a message.
    ///
    /// - Returns: an observable flag message response.
    func unflag() -> Observable<FlagMessageResponse> {
        guard !user.isCurrent else {
            return .empty()
        }
        
        let messageId = id
        
        return Client.shared.connectedRequest(flagUnflagMessage(endpoint: .unflagMessage(self))
            .do(onNext: { _ in
                if let index = Message.flaggedIds.firstIndex(where: { $0 == messageId }) {
                    Message.flaggedIds.remove(at: index)
                }
            }))
    }
    
    /// Checks if the message is flagged (locally).
    var isFlagged: Bool {
        return Message.flaggedIds.contains(id)
    }
    
    private func flagUnflagMessage(endpoint: Endpoint) -> Observable<FlagMessageResponse> {
        let request: Observable<FlagResponse> = Client.shared.rx.request(endpoint: endpoint)
        return request.map { $0.flag }
            .catchError { error -> Observable<FlagMessageResponse> in
                if let clientError = error as? ClientError,
                    case .responseError(let clientResponseError) = clientError,
                    clientResponseError.message.contains("flag already exists") {
                    return .just(FlagMessageResponse(messageId: self.id, created: Date(), updated: Date()))
                }
                
                return .error(error)
        }
    }
}

// MARK: - Supporting structs

/// A messages response.
public struct MessagesResponse: Decodable {
    /// A list of messages.
    let messages: [Message]
}

struct FlagResponse: Decodable {
    let flag: FlagMessageResponse
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
