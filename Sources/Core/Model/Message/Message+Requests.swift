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
    func delete(_ completion: @escaping ClientCompletion<MessageResponse>) {
        return rx.delete().bindOnce(to: completion)
    }
    
    /// Add a reaction to the message.
    ///
    /// - Parameters:
    ///   - type: a reaction type.
    ///   - score: a reaction score, e.g. `.cumulative` it could be more then 1.
    ///   - extraData: a reaction extra data.
    func addReaction(type: ReactionType, score: Int = 1, extraData: Codable? = nil) -> Observable<MessageResponse> {
        let reaction = Reaction(type: type, score: score, messageId: id, extraData: extraData)
        return Client.shared.rx.connectedRequest(endpoint: .addReaction(reaction))
    }
    
    /// Delete a reaction to the message.
    ///
    /// - Parameter type: a reaction type, e.g. like.
    /// - Returns: an observable message response.
    func deleteReaction(type: ReactionType) -> Observable<MessageResponse> {
        return Client.shared.rx.connectedRequest(endpoint: .deleteReaction(type, self))
    /// - Parameter reactionType: a reaction type, e.g. like.
    /// - Returns: an observable message response.
    func addReaction(_ reactionType: ReactionType, _ completion: @escaping ClientCompletion<MessageResponse>) -> Subscription {
        return rx.addReaction(reactionType).bind(to: completion)
    }
    
    /// Send a request for reply messages.
    ///
    /// - Parameter pagination: a pagination (see `Pagination`).
    /// Delete a reaction to the message.
    /// - Parameter reactionType: a reaction type, e.g. like.
    /// - Returns: an observable message response.
    func replies(pagination: Pagination) -> Observable<[Message]> {
        return Client.shared.rx.connectedRequest(endpoint: .replies(self, pagination))
            .map { (response: MessagesResponse) in response.messages }
            .do(onNext: { self.add(repliesToDatabase: $0) })
    func deleteReaction(_ reactionType: ReactionType,
                        _ completion: @escaping ClientCompletion<MessageResponse>) {
        return rx.deleteReaction(reactionType).bindOnce(to: completion)
    }
    
    /// Send a request for reply messages.
    /// - Parameters:
    ///   - pagination: a pagination (see `Pagination`).
    ///   - completion: a completion block with `[Message]`.
    func replies(pagination: Pagination, _ completion: @escaping ClientCompletion<[Message]>) {
        return rx.replies(pagination: pagination).bindOnce(to: completion)
    }
    
    /// Flag a message.
    /// - Parameter completion: a completion block with `FlagMessageResponse`.
    func flag(_ completion: @escaping ClientCompletion<FlagMessageResponse>) {
        return rx.flag().bindOnce(to: completion)
    }
    
    /// Unflag a message.
    /// - Parameter completion: a completion block with `FlagMessageResponse`.
    func unflag(_ completion: @escaping ClientCompletion<FlagMessageResponse>) {
        return rx.unflag().bindOnce(to: completion)
    }
}

// MARK: - Supporting structs

/// A messages response.
public struct MessagesResponse: Decodable {
    /// A list of messages.
    let messages: [Message]
}

struct FlagResponse<T: Decodable>: Decodable {
    let flag: T
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

/// A flag message response.
public struct FlagUserResponse: Decodable {
    private enum CodingKeys: String, CodingKey {
        case user = "target_user"
        case created = "created_at"
        case updated = "updated_at"
    }
    
    /// A flagged user.
    public let user: User
    /// A created date.
    public let created: Date
    /// A updated date.
    public let updated: Date
}
