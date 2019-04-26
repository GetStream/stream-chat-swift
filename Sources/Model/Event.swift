//
//  Event.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 01/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

public enum Event: String {
//    case userStatusChanged = "user.status.changed"
//    case userWatchingStart = "user.watching.start"
//    case userWatchingStop = "user.watching.stop"
//    case userUpdated = "user.updated"
    
//    case typingStart = "typing.start"
//    case typingStop = "typing.stop"
    
//    case messageNew = "message.new"
    case messageUpdated = "message.updated"
    case messageDeleted = "message.deleted"
//    case messageRead = "message.read"
    case messageReaction = "message.reaction"
    
    case memberAdded = "member.added"
    case memberUpdated = "member.updated"
    case memberRemoved = "member.removed"
    
    case channelUpdated = "channel.updated"
    
//    case healthCheck = "health.check"
    
    case notificationMessageNew = "notification.message_new"
    case notificationMarkRead = "notification.mark_read"
    case notificationInvited = "notification.invited"
    case notificationInviteAccepted = "notification.invite_accepted"
    case notificationAddedToChannel = "notification.added_to_channel"
    case notificationRemovedFromChannel = "notification.removed_from_channel"
    
    case connectionChanged = "connection.changed"
    case connectionRecovered = "connection.recovered"
}
