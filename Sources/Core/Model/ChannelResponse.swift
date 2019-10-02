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
        channel.members = Set(members)
        messages = try container.decode([Message].self, forKey: .messages)
        messageReads = try container.decodeIfPresent([MessageRead].self, forKey: .messageReads) ?? []
        
        if let lastMessage = messages.last,
            let messageRead = messageReads.first(where: { $0.user.isCurrent }),
            lastMessage.updated > messageRead.lastReadDate {
            unreadMessageRead = messageRead
        } else  {
            unreadMessageRead = nil
        }
    }
    
    /// Init a channel response.
    /// - Note: This constructor is using for creating a channel response from a local database.
    ///
    /// - Parameters:
    ///   - channel: a channel.
    ///   - members: members of the channel.
    ///   - messages: messages in the channel.
    public init(channel: Channel, members: [Member] = [], messages: [Message] = []) {
        self.channel = channel
        self.members = members
        self.messages = messages
        messageReads = []
        unreadMessageRead = nil
    }
}

/// A response for an updated channel.
public struct ChannelDeletedResponse: Decodable {
    /// A channel.
    public let channel: Channel
}

/// A response for an updated channel.
public struct ChannelUpdatedResponse: Decodable, Equatable {
    /// A channel.
    public let channel: Channel
    /// A user who updated a channel.
    public let user: User?
    /// An additional message of the update.
    public let message: Message?
    
    /// Returns true if
    public var inviteAnswer: InviteAnswer {
        if nil != channel.members.first(where: { $0.user == user && $0.inviteAccepted != nil }) {
            return .accepted
        }
        
        if nil != channel.members.first(where: { $0.user == user && $0.inviteRejected != nil }) {
            return .rejected
        }
        
        return .notFound
    }
}

/// An answer for an invite to join a channel.
///
/// - accepted: an invite accepted.
/// - rejected: an invite rejected.
public enum InviteAnswer: String {
    case notFound
    case accepted
    case rejected
}
