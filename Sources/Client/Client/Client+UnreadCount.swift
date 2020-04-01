//
//  Client+UnreadCount.swift
//  StreamChatClient
//
//  Created by Alexey Bukhtin on 29/01/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

// `The current user Unread Count`
//
// To get global user unread count:
//   1. Get the latest values from me on connect.
//   2. Listing notifications for new values:
//     - messageNew and notificationMessageNew
//     - notificationMarkRead
//     - notificationAddedToChannel
//     - notificationMarkAllRead: 0 values
//
// `A channel Unread Count`
//
// The channel should be watched.
//   1. Make a query with watch for messages and read state.
//     - calculate the current values
//   2. +1 for messageNew event
//   3. set to 0 for notificationMarkRead or notificationMarkAllRead

// MARK: User Unread Count

extension Client {
    func updateUserUnreadCount(event: Event) {
        var updatedUnreadCount = UnreadCount.noUnread
        
        switch event {
        case .notificationMarkAllRead:
            break
        case .notificationAddedToChannel(_, let unreadCount, _),
             .notificationMarkRead(_, _, let unreadCount, _),
             .notificationMessageNew(_, _, let unreadCount, _, _):
            updatedUnreadCount = unreadCount
        case .messageNew(let message, _, let cid, _) where message.parentId == nil:
            updatedUnreadCount = unreadCount
            updatedUnreadCount.messages += 1
            
            // Checks if the number of channels should be increased.
            if let cid = cid, channelsAtomic[cid]?.first(where: { $0.value?.isUnread ?? false }) == nil {
                updatedUnreadCount.channels += 1
            }
        default:
            return
        }
        
        unreadCountAtomic.set(updatedUnreadCount)
    }
}

// MARK: Channel Unread Count

extension Client {
    func updateChannelsUnreadCount(event: Event) {
        if case .notificationMarkAllRead(let messageRead, _) = event {
            channelsAtomic.get(default: [:]).forEach {
                $0.value.forEach {
                    if let channel = $0.value {
                        channel.resetUnreadCount(messageRead: messageRead)
                    }
                }
            }
            
            return
        }
        
        if case .notificationMessageNew(let message, let channel, _, _, _) = event {
            if let channels = channelsAtomic[channel.cid] {
                channels.forEach {
                    if let watchingChannel = $0.value, watchingChannel.cid == channel.cid {
                        watchingChannel.updateUnreadCount(newMessage: message)
                    }
                }
            }
            
            return
        }
        
        if let eventChannelId = event.cid, let channels = channelsAtomic[eventChannelId] {
            channels.forEach {
                if let channel = $0.value {
                    channel.updateWatcherCount(event: event)
                    
                    if channel.readEventsEnabled {
                        channel.updateUnreadCount(event: event)
                    }
                }
            }
        }
    }
}
