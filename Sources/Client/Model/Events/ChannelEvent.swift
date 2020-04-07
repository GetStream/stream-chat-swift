//
//  Event.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 01/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

/// A web socket event.
public enum ChannelEvent: Event {
    private enum CodingKeys: String, CodingKey {
        case type
        case cid
        case user
        case member
        case channel
        case message
        case reaction
        case watcherCount = "watcher_count"
        case channelType = "channel_type"
        case channelId = "channel_id"
        case created = "created_at"
        case reason
        case expiration
    }
    
    /// A filter type for channel events.
    public typealias Filter = (ChannelEvent, Channel?) -> Bool
    
    /// When a user starts watching a channel (when watching the channel).
    case userStartWatching(User, _ watcherCount: Int, ChannelId, ChannelEventType)
    /// When a user stops watching a channel (when watching the channel).
    case userStopWatching(User, _ watcherCount: Int, ChannelId, ChannelEventType)
    /// When a user was banned (when subscribed to the user presence).
    case userBanned(reason: String?, expiration: Date?, created: Date, ChannelId, ChannelEventType)
    
    /// Sent when a user starts typing (when watching the channel).
    case typingStart(User, ChannelId, ChannelEventType)
    /// Sent when a user stops typing (when watching the channel).
    case typingStop(User, ChannelId, ChannelEventType)
    
    /// When a new message was added on a channel (when watching the channel).
    case messageNew(Message, _ watcherCount: Int, ChannelId, ChannelEventType)
    /// When a message was updated (when watching the channel).
    case messageUpdated(Message, ChannelId, ChannelEventType)
    /// When a message was deleted (when watching the channel).
    case messageDeleted(Message, User?, ChannelId, ChannelEventType)
    /// When a channel was marked as read (when watching the channel).
    case messageRead(MessageRead, ChannelId, ChannelEventType)
    
    /// When a message reaction was added.
    case reactionNew(Reaction, Message, User, ChannelId, ChannelEventType)
    /// When a message reaction updated.
    case reactionUpdated(Reaction, Message, User, ChannelId, ChannelEventType)
    /// When a message reaction deleted.
    case reactionDeleted(Reaction, Message, User, ChannelId, ChannelEventType)
    
    /// When a member was added to a channel (when watching the channel).
    case memberAdded(Member, ChannelId, ChannelEventType)
    /// When a member was updated (when watching the channel).
    case memberUpdated(Member, ChannelId, ChannelEventType)
    /// When a member was removed from a channel (when watching the channel).
    case memberRemoved(User, ChannelId, ChannelEventType)
    
    /// When a channel was updated (when watching the channel).
    case channelUpdated(ChannelUpdatedResponse, ChannelId, ChannelEventType)
    /// When a channel was deleted (when watching the channel).
    case channelDeleted(Channel, ChannelEventType)
    /// When a channel was hidden (when watching the channel).
    case channelHidden(HiddenChannelResponse, ChannelId, ChannelEventType)
    
    /// An event type.
    public var type: ChannelEventType {
        switch self {
        case .channelUpdated(_, _, let type),
             .channelDeleted(_, let type),
             .channelHidden(_, _, let type),
             
             .messageRead(_, _, let type),
             .messageNew(_, _, _, let type),
             .messageDeleted(_, _, _, let type),
             .messageUpdated(_, _, let type),
             
             .userStartWatching(_, _, _, let type),
             .userStopWatching(_, _, _, let type),
             .userBanned(_, _, _, _, let type),
             
             .memberAdded(_, _, let type),
             .memberUpdated(_, _, let type),
             .memberRemoved(_, _, let type),
             
             .reactionNew(_, _, _, _, let type),
             .reactionUpdated(_, _, _, _, let type),
             .reactionDeleted(_, _, _, _, let type),
             
             .typingStart(_, _, let type),
             .typingStop(_, _, let type):
            return type
        }
    }
    
    /// A cid from the event.
    public var cid: ChannelId {
        switch self {
        case .channelUpdated(_, let cid, _),
             .channelHidden(_, let cid, _),
             
             .messageRead(_, let cid, _),
             .messageNew(_, _, let cid, _),
             .messageDeleted(_, _, let cid, _),
             .messageUpdated(_, let cid, _),
             
             .userStartWatching(_, _, let cid, _),
             .userStopWatching(_, _, let cid, _),
             .userBanned(_, _, _, let cid, _),
             
             .memberAdded(_, let cid, _),
             .memberUpdated(_, let cid, _),
             .memberRemoved(_, let cid, _),
             
             .reactionNew(_, _, _, let cid, _),
             .reactionUpdated(_, _, _, let cid, _),
             .reactionDeleted(_, _, _, let cid, _),
             
             .typingStart(_, let cid, _),
             .typingStop(_, let cid, _):
            return cid
        case .channelDeleted(let channel, _):
            return channel.cid
        }
    }
    
    /// A user from the event.
    public var user: User? {
        switch self {
        case .userStartWatching(let user, _, _, _),
             .userStopWatching(let user, _, _, _),
             .memberRemoved(let user, _, _),
             .reactionNew(_, _, let user, _, _),
             .reactionUpdated(_, _, let user, _, _),
             .reactionDeleted(_, _, let user, _, _),
             .typingStart(let user, _, _),
             .typingStop(let user, _, _):
            return user
        case .memberAdded(let member, _, _),
             .memberUpdated(let member, _, _):
            return member.user
        case .messageNew(let message, _, _, _):
            return message.user
        default:
            return nil
        }
    }
    
    // MARK: Decoder
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ChannelEventType.self, forKey: .type)
        
        func user() throws -> User {
            try container.decode(User.self, forKey: .user)
        }
        
        func cid() throws -> ChannelId {
            try container.decode(ChannelId.self, forKey: .cid)
        }
        
        func member() throws -> Member {
            try container.decode(Member.self, forKey: .member)
        }
        
        func message() throws -> Message {
            try container.decode(Message.self, forKey: .message)
        }
        
        func reaction() throws -> Reaction {
            try container.decode(Reaction.self, forKey: .reaction)
        }
        
        switch type {
        // Channel
        case .channelUpdated:
            self = try .channelUpdated(ChannelUpdatedResponse(from: decoder), cid(), type)
        case .channelDeleted:
            let channel = try container.decode(Channel.self, forKey: .channel)
            self = .channelDeleted(channel, type)
        case .channelHidden:
            let hiddenChannelResponse = try HiddenChannelResponse(from: decoder)
            self = try .channelHidden(hiddenChannelResponse, cid(), type)
            
        // Message
        case .messageNew:
            let watcherCount = try container.decodeIfPresent(Int.self, forKey: .watcherCount) ?? 0
            self = try .messageNew(message(), watcherCount, cid(), type)
        case .messageRead:
            let messageRead = try MessageRead(user: user(), lastReadDate: try container.decode(Date.self, forKey: .created))
            self = try .messageRead(messageRead, cid(), type)
        case .messageDeleted:
            let user = try container.decodeIfPresent(User.self, forKey: .user)
            self = try .messageDeleted(message(), user, cid(), type)
        case .messageUpdated:
            self = try .messageUpdated(message(), cid(), type)
            
        // User
        case .userStartWatching:
            let watcherCount = try container.decode(Int.self, forKey: .watcherCount)
            self = try .userStartWatching(user(), watcherCount, cid(), type)
        case .userStopWatching:
            let watcherCount = try container.decode(Int.self, forKey: .watcherCount)
            self = try .userStopWatching(user(), watcherCount, cid(), type)
        case .userBanned:
            var decodedCid: ChannelId? = try? container.decodeIfPresent(ChannelId.self, forKey: .cid)
            
            if let channelType = try container.decodeIfPresent(ChannelType.self, forKey: .channelType),
                let id = try container.decodeIfPresent(String.self, forKey: .channelId) {
                decodedCid = ChannelId(type: channelType, id: id)
            }
            
            guard let cid = decodedCid else {
                throw EventTypeError.cidNotFound
            }
            
            let reason = try container.decodeIfPresent(String.self, forKey: .reason)
            let expiration = try container.decodeIfPresent(Date.self, forKey: .expiration)
            let created = try container.decode(Date.self, forKey: .created)
            self = .userBanned(reason: reason, expiration: expiration, created: created, cid, type)
            
        // Member
        case .memberAdded:
            self = try .memberUpdated(member(), cid(), type)
        case .memberUpdated:
            self = try .memberUpdated(member(), cid(), type)
        case .memberRemoved:
            self = try .memberRemoved(user(), cid(), type)
            
        // Typing
        case .typingStart:
            self = try .typingStart(user(), cid(), type)
        case .typingStop:
            self = try .typingStop(user(), cid(), type)
            
        // Reaction
        case .reactionNew:
            self = try .reactionNew(reaction(), message(), user(), cid(), type)
        case .reactionUpdated:
            self = try .reactionUpdated(reaction(), message(), user(), cid(), type)
        case .reactionDeleted:
            self = try .reactionDeleted(reaction(), message(), user(), cid(), type)
        }
    }
}

// MARK: - Equatable

extension ChannelEvent: Equatable {
    public static func == (lhs: ChannelEvent, rhs: ChannelEvent) -> Bool {
        switch (lhs, rhs) {
        case (let .channelUpdated(response1, cid1, _), let .channelUpdated(response2, cid2, _)):
            return response1 == response2 && cid1 == cid2
        case (.channelDeleted(let channel1, _), .channelDeleted(let channel2, _)):
            return channel1 == channel2
        case (let .channelHidden(hiddenChannelResponse1, cid1, _), let .channelHidden(hiddenChannelResponse2, cid2, _)):
            return hiddenChannelResponse1 == hiddenChannelResponse2 && cid1 == cid2
        case (let .messageRead(messageRead1, cid1, _), let .messageRead(messageRead2, cid2, _)):
            return messageRead1 == messageRead2 && cid1 == cid2
        case (let .messageNew(message1, watcherCount1, cid1, _), let .messageNew(message2, watcherCount2, cid2, _)):
            return message1 == message2 && watcherCount1 == watcherCount2 && cid1 == cid2
        case (let .messageDeleted(message1, user1, cid1, _), let .messageDeleted(message2, user2, cid2, _)):
            return message1 == message2 && user1 == user2 && cid1 == cid2
        case (let .messageUpdated(message1, cid1, _), let .messageUpdated(message2, cid2, _)):
            return message1 == message2 && cid1 == cid2
        case (let .userStartWatching(user1, watcherCount1, cid1, _), let .userStartWatching(user2, watcherCount2, cid2, _)):
            return user1 == user2 && watcherCount1 == watcherCount2 && cid1 == cid2
        case (let .userStopWatching(user1, watcherCount1, cid1, _), let .userStopWatching(user2, watcherCount2, cid2, _)):
            return user1 == user2 && watcherCount1 == watcherCount2 && cid1 == cid2
        case (let .userBanned(reason1, expiration1, created1, cid1, _), let .userBanned(reason2, expiration2, created2, cid2, _)):
            return reason1 == reason2 && expiration1 == expiration2 && created1 == created2 && cid1 == cid2
        case (let .memberAdded(member1, cid1, _), let .memberAdded(member2, cid2, _)):
            return member1 == member2 && cid1 == cid2
        case (let .memberUpdated(member1, cid1, _), let .memberUpdated(member2, cid2, _)):
            return member1 == member2 && cid1 == cid2
        case (let .memberRemoved(user1, cid1, _), let .memberRemoved(user2, cid2, _)):
            return user1 == user2 && cid1 == cid2
        case (let .reactionNew(reaction1, message1, user1, cid1, _), let .reactionNew(reaction2, message2, user2, cid2, _)):
            return reaction1 == reaction2 && message1 == message2 && user1 == user2 && cid1 == cid2
        case (let .reactionUpdated(reaction1, message1, user1, cid1, _), let .reactionUpdated(reaction2, message2, user2, cid2, _)):
            return reaction1 == reaction2 && message1 == message2 && user1 == user2 && cid1 == cid2
        case (let .reactionDeleted(reaction1, message1, user1, cid1, _), let .reactionDeleted(reaction2, message2, user2, cid2, _)):
            return reaction1 == reaction2 && message1 == message2 && user1 == user2 && cid1 == cid2
        case (let .typingStart(user1, cid1, _), let .typingStart(user2, cid2, _)):
            return user1 == user2 && cid1 == cid2
        case (let .typingStop(user1, cid1, _), let .typingStop(user2, cid2, _)):
            return user1 == user2 && cid1 == cid2
        default:
            return false
        }
    }
}
