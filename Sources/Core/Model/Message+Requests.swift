//
//  Message+Requests.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 30/07/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import RxSwift

// MARK: Requests

public extension Message {
    
    internal static var flaggedIds = [String]()
    
    /// Delete the message.
    ///
    /// - Returns: an observable message response.
    func delete() -> Observable<MessageResponse> {
        return Client.shared.rx.connectedRequest(endpoint: .deleteMessage(self))
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
    }
    
    /// Send a request for reply messages.
    ///
    /// - Parameter pagination: a pagination (see `Pagination`).
    /// - Returns: an observable message response.
    func replies(pagination: Pagination) -> Observable<[Message]> {
        return Client.shared.rx.connectedRequest(endpoint: .replies(self, pagination))
            .map { (response: MessagesResponse) in response.messages }
            .do(onNext: { self.add(repliesToDatabase: $0) })
    }
    
    // MARK: Flag Message
    
    /// Checks if the message is flagged (locally).
    var isFlagged: Bool {
        return Message.flaggedIds.contains(id)
    }
    
    /// Flag a message.
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
    
    private func flagUnflagMessage(endpoint: Endpoint) -> Observable<FlagMessageResponse> {
        return Client.shared.flagUnflag(endpoint: endpoint,
                                        aleradyFlagged: FlagMessageResponse(messageId: id, created: Date(), updated: Date()))
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
