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
    /// Messages (see `Message`).
    public let messages: [Message]
    /// Message read states (see `MessageRead`)
    public let messageReads: [MessageRead]
    /// Unread message state by the current user.
    public private(set) var unreadMessageRead: MessageRead?
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let members = try container.decode([Member].self, forKey: .members)
        channel = try container.decode(Channel.self, forKey: .channel)
        channel.members = Set(members)
        messages = try container.decodeIfPresent([Message].self, forKey: .messages) ?? []
        messageReads = try container.decodeIfPresent([MessageRead].self, forKey: .messageReads) ?? []
        updateUnreadMessageRead()
    }
    
    /// Init a channel response.
    /// - Note: This constructor is using for creating a channel response from a local database.
    ///
    /// - Parameters:
    ///   - channel: a channel.
    ///   - members: members of the channel.
    ///   - messages: messages in the channel.
    public init(channel: Channel, messages: [Message] = [], messageReads: [MessageRead] = []) {
        self.channel = channel
        self.messages = messages
        self.messageReads = messageReads
        updateUnreadMessageRead()
    }
    
    private mutating func updateUnreadMessageRead() {
        if let lastMessage = messages.last,
            let messageRead = messageReads.first(where: { $0.user.isCurrent }),
            lastMessage.updated > messageRead.lastReadDate {
            unreadMessageRead = messageRead
        }
    }
}

extension ChannelResponse: Hashable {
    
    public static func == (lhs: ChannelResponse, rhs: ChannelResponse) -> Bool {
        return lhs.channel.cid == rhs.channel.cid
            && lhs.channel.members == rhs.channel.members
            && lhs.messages == rhs.messages
            && lhs.messageReads == rhs.messageReads
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(channel)
        hasher.combine(channel.members)
        hasher.combine(messages)
        hasher.combine(messageReads)
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
