//
//  EventType.swift
//  StreamChatClient
//
//  Created by Alexey Bukhtin on 06/04/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

/// A web socket channel event type.
public enum ChannelEventType: String, EventType {
    /// When a user was banned (when subscribed to the user presence).
    case userBanned = "user.banned"
    /// When a user starts watching a channel (when watching the channel).
    case userStartWatching = "user.watching.start"
    /// When a user stops watching a channel (when watching the channel).
    case userStopWatching = "user.watching.stop"
    
    /// Sent when a user starts typing (when watching the channel).
    case typingStart = "typing.start"
    /// Sent when a user stops typing (when watching the channel).
    case typingStop = "typing.stop"
    
    /// When a channel was updated (when watching the channel).
    case channelUpdated = "channel.updated"
    /// When a channel was deleted (when watching the channel).
    case channelDeleted = "channel.deleted"
    /// When a channel was hidden (when watching the channel).
    case channelHidden = "channel.hidden"
    
    /// When a new message was added on a channel (when watching the channel).
    case messageNew = "message.new"
    /// When a message was updated (when watching the channel).
    case messageUpdated = "message.updated"
    /// When a message was deleted (when watching the channel).
    case messageDeleted = "message.deleted"
    /// When a channel was marked as read (when watching the channel).
    case messageRead = "message.read"
    /// ⚠️ When a message reaction was added or deleted (when watching the channel).
    //case messageReaction = "message.reaction"
    
    /// When a member was added to a channel (when watching the channel).
    case memberAdded = "member.added"
    /// When a member was updated (when watching the channel).
    case memberUpdated = "member.updated"
    /// When a member was removed from a channel (when watching the channel).
    case memberRemoved = "member.removed"
    
    /// When a message reaction was added.
    case reactionNew = "reaction.new"
    /// When a message reaction updated.
    case reactionUpdated = "reaction.updated"
    /// When a message reaction deleted.
    case reactionDeleted = "reaction.deleted"
}
