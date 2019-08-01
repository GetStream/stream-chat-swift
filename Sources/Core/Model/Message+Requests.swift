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
    
    /// Delete the message.
    ///
    /// - Returns: an observable message response.
    func delete() -> Observable<MessageResponse> {
        return Client.shared.rx.request(endpoint: .deleteMessage(self))
    }
    
    /// Add a reaction to the message.
    ///
    /// - Parameter reactionType: a reaction type.
    /// - Returns: an observable message response.
    func addReaction(_ reactionType: String) -> Observable<MessageResponse> {
        return Client.shared.rx.request(endpoint: .addReaction(reactionType, self))
    }
    
    /// Delete a reaction to the message.
    ///
    /// - Parameter reactionType: a reaction type.
    /// - Returns: an observable message response.
    func deleteReaction(_ reactionType: String) -> Observable<MessageResponse> {
        return Client.shared.rx.request(endpoint: .deleteReaction(reactionType, self))
    }
    
    /// Send a request for reply messages.
    ///
    /// - Parameter pagination: a pagination (see `Pagination`).
    /// - Returns: an observable message response.
    func replies(pagination: Pagination) -> Observable<MessagesResponse> {
        return Client.shared.rx.request(endpoint: .replies(self, pagination))
    }
    
    /// Flag a message.
    func flag() -> Observable<FlagMessageResponse> {
        return flagUnflagMessage(endpoint: .flagMessage(self))
    }
    
    /// Unflag a message.
    func unflag() -> Observable<FlagMessageResponse> {
        return flagUnflagMessage(endpoint: .unflagMessage(self))
    }
    
    private func flagUnflagMessage(endpoint: ChatEndpoint) -> Observable<FlagMessageResponse> {
        let request: Observable<[String: FlagMessageResponse]> = Client.shared.rx.request(endpoint: endpoint)
        return request.map { $0["flag"] }.unwrap()
    }
}

// MARK: - Supporting structs

/// A messages response.
public struct MessagesResponse: Decodable {
    /// A list of messages.
    let messages: [Message]
}

/// A flag response.
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
