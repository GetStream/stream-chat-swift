//
//  ChannelResponse.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 01/08/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

/// A channel response.
public struct ChannelResponse: Decodable {
    private enum CodingKeys: String, CodingKey {
        case channel
        case members
        case messages
        case messageReads = "read"
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
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        channel = try container.decode(Channel.self, forKey: .channel)
        members = try container.decode([Member].self, forKey: .members)
        messages = try container.decode([Message].self, forKey: .messages)
        messageReads = try container.decodeIfPresent([MessageRead].self, forKey: .messageReads) ?? []
        
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
}
