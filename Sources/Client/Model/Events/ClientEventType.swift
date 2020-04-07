//
//  EventType.swift
//  StreamChatClient
//
//  Created by Alexey Bukhtin on 06/04/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

/// A web socket client event type.
public enum ClientEventType: String, EventType {
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
}
