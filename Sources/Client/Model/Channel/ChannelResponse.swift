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
    public private(set) var channel: Channel
    /// Messages (see `Message`).
    public let messages: [Message]
    /// Message read states (see `MessageRead`)
    public let messageReads: [MessageRead]
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let members = try container.decode([Member].self, forKey: .members)
        channel = try container.decode(Channel.self, forKey: .channel)
        channel.members = Set(members)
        messages = try container.decodeIfPresent([Message].self, forKey: .messages) ?? []
        messageReads = try container.decodeIfPresent([MessageRead].self, forKey: .messageReads) ?? []
        updateUnreadMessageRead()
        calculateChannelUnreadCount()
        Client.shared.channels.append(WeakRef(channel))
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
            channel.unreadMessageRead = messageRead
        }
    }
    
    func calculateChannelUnreadCount() {
        channel.unreadCountAtomic.set(0)
        channel.mentionedUnreadCountAtomic.set(0)
        
        if messages.isEmpty {
            return
        }
        
        var count = 0
        var mentionedCount = 0
        let currentUser = Client.shared.user
        
        if let unreadMessageRead = channel.unreadMessageRead {
            for message in messages.reversed() {
                if message.created > unreadMessageRead.lastReadDate {
                    count += 1
                    
                    if message.user != currentUser, message.mentionedUsers.contains(currentUser) {
                        mentionedCount += 1
                    }
                } else {
                    break
                }
            }
        } else {
            count = messages.count
            mentionedCount = messages.filter({ $0.user != currentUser && $0.mentionedUsers.contains(currentUser) }).count
        }
        
        channel.unreadCountAtomic.set(count)
        channel.mentionedUnreadCountAtomic.set(mentionedCount)
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
