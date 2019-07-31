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
}

// MARK: - Supporting structs

/// A messages response.
public struct MessagesResponse: Decodable {
    /// A list of messages.
    let messages: [Message]
}
