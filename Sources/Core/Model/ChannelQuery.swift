//
//  Query.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 02/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

/// A channel query.
public struct ChannelQuery: Codable {
    private enum CodingKeys: String, CodingKey {
        case data
        case channel
        case members
        case messages
        case messageReads = "read"
        case state
        case watch
    }
    
    /// A channel.
    public let channel: Channel
    /// Members of the channel (see `Member`).
    public let members: [Member]
    /// Messages (see `Message`).
    public let messages: [Message]
    /// Message read states (see `MessageRead`)
    public let messageReads: [MessageRead]
    /// Unread message state by the current user.
    public let unreadMessageRead: MessageRead?
    let state: Bool = true
    let watch: Bool = true
    /// A pagination (see `Pagination`).
    public let pagination: Pagination
    
    /// Init a channel query.
    ///
    /// - Parameters:
    ///     - channel: a channel.
    ///     - memebers: members of the channel.
    ///     - pagination: a pagination (see `Pagination`).
    public init(channel: Channel, members: [Member], pagination: Pagination) {
        self.channel = channel
        self.members = members
        self.pagination = pagination
        messages = []
        messageReads = []
        unreadMessageRead = nil
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        channel = try container.decode(Channel.self, forKey: .channel)
        members = try container.decode([Member].self, forKey: .members)
        messages = try container.decode([Message].self, forKey: .messages)
        messageReads = try container.decodeIfPresent([MessageRead].self, forKey: .messageReads) ?? []
        pagination = .none
        
        if let user = Client.shared.user {
            if let lastMessage = messages.last,
                let messageRead = messageReads.first(where: { $0.user == user }),
                lastMessage.updated > messageRead.lastReadDate {
                unreadMessageRead = messageRead
            } else  {
                unreadMessageRead = nil
            }
        } else {
            unreadMessageRead = nil
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(state, forKey: .state)
        try container.encode(watch, forKey: .watch)
        channel.memberIds = members.map { $0.user.id }
        try container.encode(channel, forKey: .data)
        channel.memberIds = []
        try container.encode(pagination, forKey: .messages)
    }
}
