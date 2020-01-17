//
//  Channel+Database.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 17/09/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import RxSwift

// MARK: - Database

public extension Channel {
    
    /// Fetch channel messages for a local database.
    /// - Parameter pagination: a pagination perameters.
    /// - Returns: a channel response (see `ChannelResponse`).
    func fetch(pagination: Pagination = .none) -> Observable<ChannelResponse> {
        guard let database = Client.shared.database else {
            return .empty()
        }
        
        database.logger?.log("🆔 \(cid) ⬅️ Fetch messages: \(pagination)")
        return database.channel(channelType: type, channelId: id, pagination: pagination)
    }
    
    func addOrUpdateInDatabase() {
        guard let database = Client.shared.database else {
            return
        }
        
        database.logger?.log("➡️ Add or update a channel 🆔 \(cid)")
        database.addOrUpdate(channel: self)
    }
    
    /// Add messages to a database.
    /// - Parameter messages: messages
    func add(messagesToDatabase messages: [Message]) {
        guard let database = Client.shared.database, !messages.isEmpty else {
            return
        }
        
        database.logger?.log("🆔 \(cid) ➡️ Added messages: \(messages.count)")
        database.add(messages: messages, to: self)
    }
}

// MARK: - Database Members

public extension Channel {
    
    func set(membersToDatabase members: Set<Member>) {
        guard let database = Client.shared.database, !members.isEmpty else {
            return
        }
        
        logDatabaseMembers(message: "Set members", members: members)
        database.add(members: members, for: self)
    }
    
    func add(membersToDatabase: Set<Member>) {
        guard let database = Client.shared.database, !members.isEmpty else {
            return
        }
        
        logDatabaseMembers(message: "Add members", members: members)
        database.add(members: members, for: self)
    }
    
    func remove(membersFromDatabase members: Set<Member>) {
        guard let database = Client.shared.database, !members.isEmpty else {
            return
        }
        
        logDatabaseMembers(message: "Remove members", members: members)
        database.remove(members: members, from: self)
    }
    
    func update(membersInDatabase: Set<Member>) {
        guard let database = Client.shared.database, !members.isEmpty else {
            return
        }
        
        logDatabaseMembers(message: "Update members", members: members)
        database.update(members: members, from: self)
    }
    
    private func logDatabaseMembers(message: String, members: Set<Member>) {
        if let logger = Client.shared.database?.logger {
            logger.log("🆔 \(cid) ➡️ \(message) \(members.map({ $0.user.id }).joined(separator: ", "))")
        }
    }
}
