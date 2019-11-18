//
//  Message+Database.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 18/11/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import RxSwift

// MARK: Database

public extension Message {
    
    /// Fetch a reply messages from a database.
    ///
    /// - Parameter pagination: a pagination (see `Pagination`).
    /// - Returns: an observable message response.
    func fetchReplies(pagination: Pagination) -> Observable<[Message]> {
        guard let database = Client.shared.database else {
            return .empty()
        }
        
        database.logger?.log("🆔 \(id) \(textOrArgs.prefix(10))... ⬅️ Fetch replies with: \(pagination)")
        return database.replies(for: self, pagination: pagination)
    }
    
    /// Add reply messages to a message.
    /// - Parameter messages: message
    func add(repliesToDatabase replies: [Message]) {
        guard let database = Client.shared.database, !replies.isEmpty else {
            return
        }
        
        database.logger?.log("🆔 \(id) \(textOrArgs.prefix(10))... ➡️ Added replies: \(replies.count)")
        database.add(replies: replies, for: self)
    }
}
