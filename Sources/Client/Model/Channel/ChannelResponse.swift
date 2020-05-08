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
        case messages
        case messageReads = "read"
        case members
        case watchers
        case watcherCount = "watcher_count"
    }
    
    /// A channel.
    public private(set) var channel: Channel
    /// Messages (see `Message`).
    public let messages: [Message]
    /// Message read states (see `MessageRead`)
    public let messageReads: [MessageRead]
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        channel = try container.decode(Channel.self, forKey: .channel)
        messages = try container.decodeIfPresent([Message].self, forKey: .messages) ?? []
        messageReads = try container.decodeIfPresent([MessageRead].self, forKey: .messageReads) ?? []
        
        let members = try container.decodeIfPresent([Member].self, forKey: .members)
        
        if let members = members {
            channel.members = Set(members)
        }
        
        let watchers = try container.decodeIfPresent([User].self, forKey: .watchers)
        
        if let watchers = watchers {
            channel.watchers = Set(watchers)
        }
        
        if let watcherCount = try container.decodeIfPresent(Int.self, forKey: .watcherCount) {
            channel.watcherCountAtomic.set(watcherCount)
        }
        
        calculateChannelUnreadCount()
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
        channel.unreadMessageReadAtomic.set(userUnreadMessageRead())
    }
    
    private func userUnreadMessageRead() -> MessageRead? {
        messageReads.first(where: { $0.user.isCurrent })
    }
    
    private func calculateChannelUnreadCount() {
        if messages.isEmpty || !channel.members.contains(Member.current) {
            return
        }
        
        let unreadMessageRead = userUnreadMessageRead()
        channel.unreadMessageReadAtomic.set(unreadMessageRead)
        
        var unreadCount = ChannelUnreadCount.noUnread
        let currentUser = Client.shared.user
        
        if let unreadMessageRead = unreadMessageRead {
            // Backend sends message unread count, use it directly
            unreadCount.messages = unreadMessageRead.unreadMessagesCount
            
            if unreadMessageRead.unreadMessagesCount > 0 {
                // Calculate mentioned message unread count
                // This is approximate since it'll be limited for the messages we've fetched
                for message in messages.reversed() where !message.user.isCurrent {
                   if message.created > unreadMessageRead.lastReadDate {
                       if message.mentionedUsers.contains(currentUser) {
                           unreadCount.mentionedMessages += 1
                       }
                   } else {
                       break
                   }
                }
            }
        } else {
            unreadCount.messages = messages.count
            unreadCount.mentionedMessages = messages
                .filter({ $0.user != currentUser && $0.mentionedUsers.contains(currentUser) })
                .count
        }
        
        channel.unreadCountAtomic.set(unreadCount)
    }
}

extension ChannelResponse: Hashable {
    
    public static func == (lhs: ChannelResponse, rhs: ChannelResponse) -> Bool {
        lhs.channel.cid == rhs.channel.cid
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
