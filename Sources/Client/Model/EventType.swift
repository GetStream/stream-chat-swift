//
//  EventType.swift
//  StreamChatClient
//
//  Created by Alexey Bukhtin on 08/04/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

/// A web socket event type.
public enum EventType: String, Codable, CaseIterable {
    
    /// When the state of the connection changed.
    case connectionChanged = "connection.changed"
    /// Every 30 second to confirm that the client connection is still active.
    case healthCheck = "health.check"
    /// A pong event.
    case pong
    
    /// When a user presence changed, e.g. online, offline, away (when subscribed to the user presence).
    case userPresenceChanged = "user.presence.changed"
    /// When a user was updated (when subscribed to the user presence).
    case userUpdated = "user.updated"
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
//    case messageReaction = "message.reaction"
    
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
    
    /// When a message was added to a channel (when clients that are not currently watching the channel).
    case notificationMessageNew = "notification.message_new"
    /// When the total count of unread messages (across all channels the user is a member) changes
    /// (when clients from the user affected by the change).
    case notificationMarkRead = "notification.mark_read"
    /// When the user mutes someone.
    case notificationMutesUpdated = "notification.mutes_updated"
    
    /// When the user accepts an invite (when the user invited).
    case notificationAddedToChannel = "notification.added_to_channel"
    /// When a user was removed from a channel (when the user invited).
    case notificationRemovedFromChannel = "notification.removed_from_channel"
    
    /// When the user was invited to join a channel (when the user invited).
    case notificationInvited = "notification.invited"
    /// When the user accepts an invite (when the user invited).
    case notificationInviteAccepted = "notification.invite_accepted"
    /// When the user reject an invite (when the user invited).
    case notificationInviteRejected = "notification.invite_rejected"
    
    /// Checks if the type is a channel event type.
    public var isChannelEventType: Bool {
        EventType.channelEventTypes.contains(self)
    }
    
    /// All channel event types.
    public static var channelEventTypes: Set<EventType> {
        [.userBanned,
         .userStartWatching,
         .userStopWatching,
         .typingStart,
         .typingStop,
         .channelUpdated,
         .channelDeleted,
         .channelHidden,
         .messageNew,
         .messageUpdated,
         .messageDeleted,
         .messageRead,
         .memberAdded,
         .memberUpdated,
         .memberRemoved,
         .reactionNew,
         .reactionUpdated,
         .reactionDeleted]
    }
}
