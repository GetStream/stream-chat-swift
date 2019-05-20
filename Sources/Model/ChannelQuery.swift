//
//  Query.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 02/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

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
    
    public let channel: Channel
    public let members: [Member]
    public let messages: [Message]
    public let messageReads: [MessageRead]
    public let lastMessageRead: MessageRead?
    public let isUnread: Bool
    public let state: Bool = true
    public let watch: Bool = true
    public let pagination: Pagination
    
    public init(channel: Channel, members: [Member], pagination: Pagination) {
        self.channel = channel
        self.members = members
        self.pagination = pagination
        messages = []
        messageReads = []
        lastMessageRead = nil
        isUnread = false
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        channel = try container.decode(Channel.self, forKey: .channel)
        members = try container.decode([Member].self, forKey: .members)
        messages = try container.decode([Message].self, forKey: .messages)
        messageReads = try container.decode([MessageRead].self, forKey: .messageReads)
        pagination = .none
        
        if let user = Client.shared.user {
            lastMessageRead = messageReads.first { $0.user == user }
        } else {
            lastMessageRead = nil
        }
        
        if let lastMessage = messages.last, let lastMessageRead = lastMessageRead {
            isUnread = lastMessage.updated > lastMessageRead.lastReadDate
        } else  {
            isUnread = false
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(state, forKey: .state)
        try container.encode(watch, forKey: .watch)
        channel.userIds = members.map { $0.user.id }
        try container.encode(channel, forKey: .data)
        channel.userIds = []
        try container.encode(pagination, forKey: .messages)
    }
}
